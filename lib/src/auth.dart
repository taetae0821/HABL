import 'package:flutter/foundation.dart';

// 앱 전체에서 공유하는 로그인 상태
// TODO: 앱을 껐다 켜도 유지되도록 authToken 을 안전한 저장소에 저장
final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

// 서버가 발급한 로그인 토큰 (API 요청 시 Authorization 헤더에 사용)
String? authToken;

// 내가 회장으로 운영 중인 동호회 id (회장이 아니면 null)
// 회장은 다른 동호회에 가입할 수 없으므로 가입 버튼에서 확인합니다
// TODO: 로그인 / 내 정보 조회 응답에서 값을 채우기
final ValueNotifier<int?> leadingClubId = ValueNotifier(null);

// 로그인한 사용자 정보
class AppUser {
  const AppUser({
    required this.loginId,
    required this.name,
    required this.role,
    this.profileImageUrl = '',
    this.leadingClubId,
    this.joinedClubIds = const [],
  });

  final String loginId;
  final String name;
  final String role; // 'LEADER' 또는 'MEMBER'
  final String profileImageUrl;
  final int? leadingClubId; // 회장이면 운영 중인 동호회 id
  final List<int> joinedClubIds; // 가입한 동호회 id (운영 중인 동호회 포함)

  bool get isLeader => role == 'LEADER';
}

final ValueNotifier<AppUser?> currentUser = ValueNotifier(null);

// TODO: 서버 연결 전 테스트용 계정 — 서버 로그인이 생기면 삭제
const String testPassword = '1234';
const List<AppUser> testAccounts = [
  AppUser(
    loginId: 'leader',
    name: '김회장',
    role: 'LEADER',
    leadingClubId: 1,
    joinedClubIds: [1],
  ),
  AppUser(
    loginId: 'member',
    name: '김회원',
    role: 'MEMBER',
    joinedClubIds: [1, 2],
  ),
];

// 아이디·비밀번호가 맞는 테스트 계정 (없으면 null)
AppUser? findTestAccount(String loginId, String password) {
  if (password != testPassword) return null;
  return testAccounts.where((u) => u.loginId == loginId.trim()).firstOrNull;
}

void loginAs(AppUser user) {
  currentUser.value = user;
  leadingClubId.value = user.leadingClubId;
  isLoggedIn.value = true;
}

// 동호회 탈퇴: 로그인한 사용자의 가입 목록에서 제거
// TODO: DB 연결 후 DELETE /clubs/:id/members/me 로 탈퇴 요청
void leaveClub(int clubId) {
  final user = currentUser.value;
  if (user == null) return;
  currentUser.value = AppUser(
    loginId: user.loginId,
    name: user.name,
    role: user.role,
    profileImageUrl: user.profileImageUrl,
    leadingClubId: user.leadingClubId,
    joinedClubIds: user.joinedClubIds.where((id) => id != clubId).toList(),
  );
}

void logout() {
  authToken = null;
  currentUser.value = null;
  leadingClubId.value = null;
  isLoggedIn.value = false;
}
