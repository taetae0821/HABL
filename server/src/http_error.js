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

  console.error(error);
  return response
    .status(500)
    .json({ message: "요청 처리 중 오류가 발생했습니다." });
}
