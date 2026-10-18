import 'api_client.dart';
import 'auth.dart';

Future<void> loginWithEmail(String email, String password) async {
  final response = await apiPost('/auth/login', {
    'email': email.trim(),
    'password': password,
  });
  final token = response['token'];
  if (token is! String || token.isEmpty) {
    throw const ApiException('로그인 응답에 토큰이 없습니다.');
  }
  await completeLogin(token);
}

Future<void> completeLogin(String token) async {
  final response = await apiGet('/users/me', token: token);
  final rawUser = response['user'];
  if (rawUser is! Map<String, dynamic>) {
    throw const ApiException('사용자 정보 응답 형식이 올바르지 않습니다.');
  }
  authenticateUser(AppUser.fromJson(rawUser), token);
}
