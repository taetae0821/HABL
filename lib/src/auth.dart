import 'package:flutter/foundation.dart';

// 앱 전체에서 공유하는 로그인 상태
// TODO: 서버 로그인 연결 시 실제 인증 결과로 바꾸고, 앱을 껐다 켜도 유지되도록 저장
final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);
