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

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final email = json['email'];
    final name = json['name'];
    final role = json['role'];
    if (name is! String ||
        role is! String ||
        !const {'MEMBER', 'LEADER'}.contains(role)) {
      throw const FormatException('사용자 정보 응답에 필수 값이 없습니다.');
    }

    final rawJoinedClubIds = json['joined_club_ids'];
    if (rawJoinedClubIds is! List) {
      throw const FormatException('가입 동호회 목록 응답 형식이 올바르지 않습니다.');
    }
    final joinedClubIds = rawJoinedClubIds.map((id) {
      if (id is! num) {
        throw const FormatException('가입 동호회 ID 형식이 올바르지 않습니다.');
      }
      return id.toInt();
    }).toList();
    final rawLeadingClubId = json['leading_club_id'];
    if (rawLeadingClubId != null && rawLeadingClubId is! num) {
      throw const FormatException('운영 동호회 ID 형식이 올바르지 않습니다.');
    }

    return AppUser(
      loginId: email is String ? email : '',
      name: name,
      role: role,
      leadingClubId: rawLeadingClubId is num ? rawLeadingClubId.toInt() : null,
      joinedClubIds: joinedClubIds,
    );
  }
}

final ValueNotifier<AppUser?> currentUser = ValueNotifier(null);

void authenticateUser(AppUser user, String token) {
  authToken = token;
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
