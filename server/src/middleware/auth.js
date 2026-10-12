import jwt from "jsonwebtoken";
import { pool } from "../db.js";
import { HttpError } from "../http_error.js";

// Authorization: Bearer <token> 을 확인하고 request.user = { id, name, role } 를 채웁니다.
// role 은 토큰이 아니라 DB 에서 매번 읽습니다 (토큰은 30일 유효라 그 사이 바뀔 수 있음).
async function loadUser(request) {
  const [scheme, token] = (request.headers.authorization ?? "").split(" ");
  if (scheme !== "Bearer" || !token) return null;

  let payload;
  try {
    payload = jwt.verify(token, process.env.JWT_SECRET);
  } catch (_error) {
    throw new HttpError(401, "로그인이 만료되었습니다. 다시 로그인해주세요.");
  }

  const [rows] = await pool.query(
    "SELECT id, name, role FROM users WHERE id = ?",
    [payload.sub],
  );
  if (rows.length === 0) {
    throw new HttpError(401, "존재하지 않는 계정입니다.");
  }
  return rows[0];
}

export async function requireAuth(request, _response, next) {
  const user = await loadUser(request);
  if (!user) throw new HttpError(401, "로그인이 필요합니다.");
  request.user = user;
  next();
}

// 로그인하지 않아도 되는 API 에서, 로그인했다면 request.user 를 채웁니다.
export async function optionalAuth(request, _response, next) {
  request.user = await loadUser(request);
  next();
}
