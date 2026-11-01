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

Future<void> refreshUnreadNotificationsCount() async {
  final token = authToken;
  if (token == null) {
    unreadNotificationsCount.value = 0;
    return;
  }

  final response = await apiGet('/users/me/notifications', token: token);
  final rawNotifications = response['notifications'];
  if (rawNotifications is! List) {
    throw const FormatException('알림 목록 응답 형식이 올바르지 않습니다.');
  }

  var unreadCount = 0;
  for (final rawNotification in rawNotifications) {
    if (rawNotification is! Map<String, dynamic>) {
      throw const FormatException('알림 정보 응답 형식이 올바르지 않습니다.');
    }
    final isRead = rawNotification['is_read'];
    if (isRead == false || isRead == 0) {
      unreadCount++;
    } else if (isRead != true && isRead != 1) {
      throw const FormatException('알림 읽음 상태 응답 형식이 올바르지 않습니다.');
    }
  }
  unreadNotificationsCount.value = unreadCount;
}
