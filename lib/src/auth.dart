import 'package:flutter/foundation.dart';

// 앱 전체에서 공유하는 로그인 상태
// TODO: 앱을 껐다 켜도 유지되도록 authToken 을 안전한 저장소에 저장
final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

// 서버가 발급한 로그인 토큰 (API 요청 시 Authorization 헤더에 사용)
String? authToken;

// 내가 회장으로 운영 중인 동호회 id (회장이 아니면 null)
// 회장은 다른 동호회에 가입할 수 없으므로 가입 버튼에서 확인합니다
// TODO: 로그인 / 내 정보 조회 응답에서 값을 채우고, 로그아웃 시 null 로 초기화
final ValueNotifier<int?> leadingClubId = ValueNotifier(null);
