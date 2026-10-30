// 라우터에서 throw new HttpError(404, "...") 하면 errorHandler 가 { message } 로 응답합니다.
export class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

export function errorHandler(error, _request, response, _next) {
  if (error instanceof HttpError) {
    return response.status(error.status).json({ message: error.message });
  }
  // express.json 이 요청 본문을 읽다가 낸 에러 (라우트에 도착하기 전)
  if (error?.type === "entity.parse.failed") {
    return response
      .status(400)
      .json({ message: "요청 형식이 올바르지 않습니다." });
  }
  if (error?.type === "entity.too.large") {
    return response.status(413).json({ message: "요청 내용이 너무 큽니다." });
  }

  console.error(error);
  return response
    .status(500)
    .json({ message: "요청 처리 중 오류가 발생했습니다." });
}
