import "dotenv/config";
import express from "express";
import cors from "cors";
import mysql from "mysql2";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import {
  SOCIAL_PROVIDERS,
  isProviderConfigured,
  verifySocialToken,
} from "./social_auth.js";

const app = express();
const port = Number(process.env.PORT || 3000);
const databaseUrl = process.env.DATABASE_URL;
const jwtSecret = process.env.JWT_SECRET;

if (!databaseUrl) {
  throw new Error("DATABASE_URL is required");
}

if (!jwtSecret) {
  throw new Error("JWT_SECRET is required");
}

const pool = mysql.createPool(databaseUrl).promise();

const corsOrigin = process.env.CORS_ORIGIN;

if (!corsOrigin) {
  throw new Error("CORS_ORIGIN is required");
}

const allowedOrigins = corsOrigin
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: (requestOrigin, callback) => {
      if (!requestOrigin || allowedOrigins.includes(requestOrigin)) {
        return callback(null, true);
      }

      return callback(new Error("CORS origin is not allowed"));
    },
  }),
);
app.use(express.json({ limit: "10kb" }));

app.get("/health", async (_request, response) => {
  try {
    await pool.query("SELECT 1");
    response.json({ ok: true });
  } catch (_error) {
    response
      .status(503)
      .json({ ok: false, message: "Database is unavailable" });
  }
});

app.post("/auth/signup", async (request, response) => {
  const { name, email, phoneNumber, password } = request.body ?? {};
  const normalizedEmail =
    typeof email === "string" ? email.trim().toLowerCase() : "";
  const normalizedPhone =
    typeof phoneNumber === "string" ? phoneNumber.trim() : "";
  const isValidEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail);
  const isValidPhone = /^[0-9+()\-\s]{7,20}$/.test(normalizedPhone);

  if (
    typeof name !== "string" ||
    name.trim().length === 0 ||
    !isValidEmail ||
    !isValidPhone ||
    typeof password !== "string" ||
    password.length < 8
  ) {
    return response.status(400).json({
      message: "이름, 이메일, 전화번호, 8자 이상의 비밀번호를 입력해주세요.",
    });
  }

  try {
    const passwordHash = await bcrypt.hash(password, 12);
    const [result] = await pool.query(
      `INSERT INTO users (name, email, password_hash, phone_number)
        VALUES (?, ?, ?, ?)`,
      [name.trim(), normalizedEmail, passwordHash, normalizedPhone],
    );
    const [rows] = await pool.query(
      `SELECT id, name, email, created_at
       FROM users
       WHERE id = ?`,
      [result.insertId],
    );

    return response.status(201).json({ user: rows[0] });
  } catch (error) {
    if (error?.code === "ER_DUP_ENTRY") {
      return response
        .status(409)
        .json({ message: "이미 가입된 이메일입니다." });
    }

    console.error(error);
    return response
      .status(500)
      .json({ message: "회원가입 처리 중 오류가 발생했습니다." });
  }
});

function issueToken(user) {
  return jwt.sign({ sub: String(user.id), role: user.role }, jwtSecret, {
    expiresIn: "30d",
  });
}

async function findUserById(id) {
  const [rows] = await pool.query(
    `SELECT id, name, email, role, provider, created_at
     FROM users
     WHERE id = ?`,
    [id],
  );
  return rows[0];
}

// 소셜 요청의 공통 검사: 제공자 확인 → 토큰 검증 → 소셜 프로필 반환
async function verifySocialRequest(request, response) {
  const { provider, token } = request.body ?? {};

  if (!SOCIAL_PROVIDERS.includes(provider)) {
    response.status(400).json({ message: "지원하지 않는 로그인 방식입니다." });
    return null;
  }
  if (!isProviderConfigured(provider)) {
    response
      .status(503)
      .json({ message: "서버에 소셜 로그인 설정이 되어 있지 않습니다." });
    return null;
  }

  const profile = await verifySocialToken(provider, token);
  if (!profile) {
    response
      .status(401)
      .json({ message: "소셜 로그인 정보를 확인할 수 없습니다." });
    return null;
  }
  return { provider, profile };
}

// 이미 가입된 소셜 계정이면 로그인, 아니면 가입이 필요하다고 알려줍니다
app.post("/auth/social/login", async (request, response) => {
  try {
    const verified = await verifySocialRequest(request, response);
    if (!verified) return;
    const { provider, profile } = verified;

    const [rows] = await pool.query(
      `SELECT id FROM users WHERE provider = ? AND provider_id = ?`,
      [provider, profile.providerId],
    );

    if (rows.length === 0) {
      return response.json({
        needsSignup: true,
        profile: { name: profile.name, email: profile.email },
      });
    }

    const user = await findUserById(rows[0].id);
    return response.json({ token: issueToken(user), user });
  } catch (error) {
    console.error(error);
    return response
      .status(500)
      .json({ message: "로그인 처리 중 오류가 발생했습니다." });
  }
});

// 처음 온 소셜 사용자를 회원/회장으로 가입시킵니다
app.post("/auth/social/signup", async (request, response) => {
  const { role, name, phoneNumber } = request.body ?? {};
  const normalizedPhone =
    typeof phoneNumber === "string" ? phoneNumber.trim() : "";
  const isValidPhone = /^[0-9+()\-\s]{7,20}$/.test(normalizedPhone);

  if (
    !["MEMBER", "LEADER"].includes(role) ||
    typeof name !== "string" ||
    name.trim().length === 0 ||
    !isValidPhone
  ) {
    return response
      .status(400)
      .json({ message: "이름과 전화번호를 입력해주세요." });
  }

  try {
    const verified = await verifySocialRequest(request, response);
    if (!verified) return;
    const { provider, profile } = verified;

    const [result] = await pool.query(
      `INSERT INTO users (name, email, phone_number, role, provider, provider_id)
        VALUES (?, ?, ?, ?, ?, ?)`,
      [
        name.trim(),
        profile.email?.toLowerCase() ?? null,
        normalizedPhone,
        role,
        provider,
        profile.providerId,
      ],
    );

    const user = await findUserById(result.insertId);
    return response.status(201).json({ token: issueToken(user), user });
  } catch (error) {
    if (error?.code === "ER_DUP_ENTRY") {
      const message = error.message.includes("uq_users_email")
        ? "이미 다른 방법으로 가입된 이메일입니다."
        : "이미 가입된 계정입니다. 로그인해주세요.";
      return response.status(409).json({ message });
    }

    console.error(error);
    return response
      .status(500)
      .json({ message: "회원가입 처리 중 오류가 발생했습니다." });
  }
});

app.listen(port, () => {
  console.log(`HABL API listening on port ${port}`);
});
