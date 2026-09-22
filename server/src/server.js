import "dotenv/config";
import express from "express";
import cors from "cors";
import mysql from "mysql2";
import bcrypt from "bcryptjs";

const app = express();
const port = Number(process.env.PORT || 3000);
const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error("DATABASE_URL is required");
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

app.listen(port, () => {
  console.log(`HABL API listening on port ${port}`);
});
