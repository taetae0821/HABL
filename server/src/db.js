import "dotenv/config";
import mysql from "mysql2";

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is required");
}

// 날짜는 'YYYY-MM-DD HH:mm:ss' 문자열 그대로 주고받습니다 (시간대 변환 없이 DB 값 그대로)
// 위도·경도(DECIMAL)는 문자열이 아닌 숫자로 받습니다
export const pool = mysql
  .createPool({
    uri: process.env.DATABASE_URL,
    dateStrings: true,
    decimalNumbers: true,
  })
  .promise();

// fn 안의 쿼리를 하나의 트랜잭션으로 실행합니다. 에러가 나면 전부 되돌립니다.
export async function withTransaction(fn) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const result = await fn(connection);
    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}
