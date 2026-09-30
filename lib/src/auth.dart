import 'package:flutter/foundation.dart';

// 앱 전체에서 공유하는 로그인 상태
// TODO: 앱을 껐다 켜도 유지되도록 authToken 을 안전한 저장소에 저장
final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

// 서버가 발급한 로그인 토큰 (API 요청 시 Authorization 헤더에 사용)
String? authToken;
