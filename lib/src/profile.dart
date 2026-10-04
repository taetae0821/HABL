import 'package:flutter/material.dart';
import 'package:habl/src/auth.dart';
import 'package:habl/src/club.dart';
import 'package:habl/src/club_manage.dart';
import 'package:habl/src/find_club.dart';
import 'package:habl/src/theme.dart';

// 내가 가입한 동호회 (목록 정보 + 내 역할)
class JoinedClub {
  const JoinedClub({required this.club, this.isLeader = false});

  final ClubSummary club;
  final bool isLeader; // true면 회장, false면 회원
}

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // DB에서 가져올 값들
  String _userName = ''; // 사용자 이름
  String _profileImageUrl = ''; // 사용자가 설정한 프로필 이미지 URL
  List<JoinedClub> _joinedClubs = []; // 가입한 동호회
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // TODO: DB 연결 후 로그인한 사용자(authToken)로 조회한 실제 데이터로 교체
  // (예: GET /users/me 응답의 이름·프로필 이미지, GET /users/me/clubs 응답)
  Future<void> _loadProfile() async {
    final user = currentUser.value;

    setState(() {
      _userName = user?.name ?? '';
      _profileImageUrl = user?.profileImageUrl ?? '';
      _joinedClubs = [
        for (final id in user?.joinedClubIds ?? const <int>[])
          if (sampleClubById(id) case final club?)
            JoinedClub(club: club, isLeader: id == user?.leadingClubId),
      ];
      _isLoading = false;
    });
  }

  void _openManage(ClubSummary club) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClubManage(club: club)),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃 할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (ok == true) logout();
  }

  void _openClub(ClubSummary club) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Club(
          clubName: club.name,
          clubId: club.id,
          imageUrl: club.imageUrl,
          location: club.locationName,
          meetingTime: club.regularMeetingInfo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadProfile,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                _buildHeader(),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 8,
                  child: IconButton(
                    tooltip: '로그아웃',
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
            Transform.translate(
              offset: const Offset(0, -24), // 헤더를 살짝 덮도록 위로 올림
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: _buildJoinedClubs(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상단: 프로필 이미지 + 사용자 이름
  Widget _buildHeader() {
    final leaderCount = _joinedClubs.where((c) => c.isLeader).length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 28,
        20,
        52,
      ),
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 14),
          Text(
            _userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeaderBadge(text: '🙌 동호회 ${_joinedClubs.length}곳 활동 중'),
              if (leaderCount > 0) ...[
                const SizedBox(width: 6),
                _HeaderBadge(text: '👑 회장 $leaderCount곳'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 프로필 이미지: URL이 없거나 불러오기 실패하면 이름 첫 글자 표시
  Widget _buildAvatar() {
    const double size = 104;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: AppColors.primaryLight,
      child: Text(
        _userName.isEmpty ? '🙂' : _userName.characters.first,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );

    final Widget image;
    if (_profileImageUrl.isEmpty) {
      image = fallback;
    } else if (_profileImageUrl.startsWith('assets/')) {
      image = Image.asset(
        _profileImageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else {
      image = Image.network(
        _profileImageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: AppColors.softShadow(Colors.black),
      ),
      child: ClipOval(child: image),
    );
  }

  Widget _buildJoinedClubs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 회장이면 운영 중인 동호회의 부원 관리로 바로 이동
        for (final joined in _joinedClubs.where((c) => c.isLeader)) ...[
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () => _openManage(joined.club),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.leader,
              ),
              icon: const Icon(Icons.manage_accounts_rounded),
              label: Text('${joined.club.name} 부원 관리'),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Row(
          children: [
            const Text(
              '가입한 동호회',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${_joinedClubs.length}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_joinedClubs.isEmpty)
          _buildEmpty()
        else
          for (final joined in _joinedClubs)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _JoinedClubCard(
                joined: joined,
                onTap: () => _openClub(joined.club),
              ),
            ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow(),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Text('🏕️', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 14),
          const Text(
            '아직 가입한 동호회가 없어요',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '탐색 탭에서 마음에 드는 모임을 찾아보세요',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// 헤더 위 반투명 흰색 뱃지
class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _JoinedClubCard extends StatelessWidget {
  const _JoinedClubCard({required this.joined, required this.onTap});

  final JoinedClub joined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final club = joined.club;
    final category = categoryOf(club.category);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow(),
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildThumbnail(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Tag(
                            text: '${category.emoji} ${club.category}',
                            background: category.light,
                            foreground: category.dark,
                          ),
                          const SizedBox(width: 6),
                          joined.isLeader
                              ? _Tag(
                                  text: '👑 회장',
                                  background: AppColors.leader.withValues(
                                    alpha: 0.15,
                                  ),
                                  foreground: AppColors.leaderDark,
                                )
                              : const _Tag(
                                  text: '회원',
                                  background: AppColors.secondaryLight,
                                  foreground: AppColors.secondary,
                                ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        club.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _MetaText(
                        icon: Icons.place_rounded,
                        text: club.locationName,
                      ),
                      if (club.regularMeetingInfo != null) ...[
                        const SizedBox(height: 3),
                        _MetaText(
                          icon: Icons.schedule_rounded,
                          text: club.regularMeetingInfo!,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 동호회 대표 이미지 (없거나 실패하면 기본 이미지)
  Widget _buildThumbnail() {
    const double size = 84;
    final placeholder = Image.asset(
      'assets/badminton_img.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
    final url = joined.club.imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: (url == null || url.isEmpty)
          ? placeholder
          : url.startsWith('assets/')
          ? Image.asset(url, width: size, height: size, fit: BoxFit.cover)
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
