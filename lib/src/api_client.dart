import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

Future<Map<String, dynamic>> apiGet(
  String path, {
  Map<String, String>? queryParameters,
  String? token,
}) {
  return _send(
    path,
    queryParameters: queryParameters,
    token: token,
    send: (uri, headers) => http.get(uri, headers: headers),
  );
}

Future<Map<String, dynamic>> apiPost(
  String path,
  Map<String, dynamic> body, {
  String? token,
}) {
  return _send(
    path,
    token: token,
    send: (uri, headers) =>
        http.post(uri, headers: headers, body: jsonEncode(body)),
  );
}

Future<Map<String, dynamic>> _send(
  String path, {
  Map<String, String>? queryParameters,
  String? token,
  required Future<http.Response> Function(Uri uri, Map<String, String> headers)
  send,
}) async {
  final baseUri = Uri.parse('$apiBaseUrl$path');
  final uri = queryParameters == null
      ? baseUri
      : baseUri.replace(queryParameters: queryParameters);
  final headers = <String, String>{'Content-Type': 'application/json'};
  if (token != null) headers['Authorization'] = 'Bearer $token';

  final http.Response response;
  try {
    response = await send(uri, headers).timeout(const Duration(seconds: 15));
  } on TimeoutException {
    throw const ApiException('서버 응답 시간이 초과되었습니다.');
  } on http.ClientException {
    throw const ApiException('서버에 연결할 수 없습니다.');
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(response.bodyBytes));
  } on FormatException {
    throw ApiException(
      response.statusCode >= 400
          ? '요청을 처리하지 못했습니다. (HTTP ${response.statusCode})'
          : '서버 응답을 해석할 수 없습니다.',
      statusCode: response.statusCode,
    );
  }

  if (decoded is! Map<String, dynamic>) {
    throw ApiException('서버 응답 형식이 올바르지 않습니다.', statusCode: response.statusCode);
  }
  if (response.statusCode >= 400) {
    final message = decoded['message'];
    throw ApiException(
      message is String ? message : '요청을 처리하지 못했습니다.',
      statusCode: response.statusCode,
    );
  }
  return decoded;
}
