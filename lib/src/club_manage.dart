import 'package:flutter/material.dart';
import 'package:habl/src/auth.dart';
import 'package:habl/src/find_club.dart';
import 'package:habl/src/theme.dart';

// 회장이 올린 공지 한 건 (부원들에게 알람으로 전송)
class ClubNotice {
  ClubNotice({
    required this.clubId,
    required this.clubName,
    required this.authorLoginId,
    required this.authorName,
    required this.message,
    required this.createdAt,
  });

  final int clubId;
  final String clubName;
  final String authorLoginId;
  final String authorName;
  final String message;
  final DateTime createdAt;
  final Set<String> readBy = {}; // 알람을 확인한 사용자 loginId
}

// 앱 전체에서 공유하는 공지 목록 (최신순)
// TODO: DB 연결 후 POST /clubs/:id/notices 로 저장하고, 서버가 부원들에게 푸시 알림 전송
final ValueNotifier<List<ClubNotice>> clubNotices = ValueNotifier([]);

// 내가 받은 공지: 내가 가입한 동호회의 공지 중 내가 쓰지 않은 것
List<ClubNotice> noticesFor(AppUser? user) {
  if (user == null) return [];
  return clubNotices.value
      .where(
        (n) =>
            user.joinedClubIds.contains(n.clubId) &&
            n.authorLoginId != user.loginId,
      )
      .toList();
}

int unreadNoticeCount(AppUser? user) => noticesFor(
  user,
).where((n) => !n.readBy.contains(user!.loginId)).length;

void markNoticesRead(AppUser? user) {
  if (user == null || unreadNoticeCount(user) == 0) return;
  for (final notice in noticesFor(user)) {
    notice.readBy.add(user.loginId);
  }
  clubNotices.value = [...clubNotices.value]; // 알람 뱃지 갱신
}

// 동호회 부원 / 가입 신청자
class ClubMember {
  const ClubMember({
    required this.name,
    required this.joinedAt,
    this.isLeader = false,
    this.introduction,
  });

  final String name;
  final String joinedAt; // 가입일 또는 신청일
  final bool isLeader;
  final String? introduction; // 가입 신청 시 한마디
}

// 회장 전용 부원 관리 화면: 가입 신청 승인/거절, 부원 내보내기, 공지 올리기
class ClubManage extends StatefulWidget {
  const ClubManage({super.key, required this.club});

  final ClubSummary club;

  @override
  State<ClubManage> createState() => _ClubManageState();
}

class _ClubManageState extends State<ClubManage> {
  List<ClubMember> _members = [];
  List<ClubMember> _applicants = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  // TODO: DB 연결 후 GET /clubs/:id/members, GET /clubs/:id/applications 로 교체
  void _loadMembers() {
    final leaderName = currentUser.value?.name ?? '회장';
    _members = [
      ClubMember(name: leaderName, joinedAt: '2026.09.01', isLeader: true),
      const ClubMember(name: '김회원', joinedAt: '2026.09.05'),
      const ClubMember(name: '이배드', joinedAt: '2026.09.12'),
      const ClubMember(name: '박스매시', joinedAt: '2026.09.20'),
    ];
    _applicants = const [
      ClubMember(
        name: '최셔틀',
        joinedAt: '2026.10.02',
        introduction: '배드민턴 3년 쳤어요! 주말 모임 좋아요 🙌',
      ),
      ClubMember(
        name: '정라켓',
        joinedAt: '2026.10.03',
        introduction: '완전 초보지만 열심히 배우겠습니다',
      ),
    ];
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // TODO: POST /clubs/:id/applications/:applicantId/approve
  void _approve(ClubMember applicant) {
    setState(() {
      _applicants = [..._applicants]..remove(applicant);
      _members = [
        ..._members,
        ClubMember(name: applicant.name, joinedAt: _today()),
      ];
    });
    _showSnack('${applicant.name}님의 가입을 승인했어요');
  }

  // TODO: POST /clubs/:id/applications/:applicantId/reject
  void _reject(ClubMember applicant) {
    setState(() => _applicants = [..._applicants]..remove(applicant));
    _showSnack('${applicant.name}님의 가입 신청을 거절했어요');
  }

  // TODO: DELETE /clubs/:id/members/:memberId
  Future<void> _confirmKick(ClubMember member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${member.name}님을 내보낼까요?'),
        content: const Text('내보낸 부원은 다시 가입 신청을 해야 해요.'),
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
            child: const Text('내보내기'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _members = [..._members]..remove(member));
    _showSnack('${member.name}님을 내보냈어요');
  }

  static String _today() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}.${two(now.month)}.${two(now.day)}';
  }

  // 공지 작성 바텀시트
  Future<void> _openNoticeSheet() async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, // 키보드가 올라와도 입력칸이 가려지지 않게
      builder: (context) => const _NoticeSheet(),
    );
    if (message == null || message.trim().isEmpty) return;

    final user = currentUser.value;
    final notice = ClubNotice(
      clubId: widget.club.id,
      clubName: widget.club.name,
      authorLoginId: user?.loginId ?? '',
      authorName: user?.name ?? '회장',
      message: message.trim(),
      createdAt: DateTime.now(),
    );
    clubNotices.value = [notice, ...clubNotices.value];

    final receiverCount = _members.where((m) => !m.isLeader).length;
    _showSnack('📢 부원 $receiverCount명에게 공지 알람을 보냈어요');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('부원 관리')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _buildClubBanner(),
            const SizedBox(height: 28),
            _buildNoticeSection(),
            const SizedBox(height: 28),
            _SectionTitle(title: '가입 신청', count: _applicants.length),
            const SizedBox(height: 12),
            if (_applicants.isEmpty)
              const _EmptyBox(text: '새로운 가입 신청이 없어요')
            else
              for (final applicant in _applicants)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ApplicantCard(
                    applicant: applicant,
                    onApprove: () => _approve(applicant),
                    onReject: () => _reject(applicant),
                  ),
                ),
            const SizedBox(height: 16),
            _SectionTitle(title: '부원', count: _members.length),
            const SizedBox(height: 12),
            _buildMemberList(),
          ],
        ),
      ),
    );
  }

  // 상단 동호회 정보 배너
  Widget _buildClubBanner() {
    final category = categoryOf(widget.club.category);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow(AppColors.primary),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '👑 내가 운영하는 동호회',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.club.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '부원 ${_members.length}명 · 가입 신청 ${_applicants.length}건',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Text(category.emoji, style: const TextStyle(fontSize: 30)),
          ),
        ],
      ),
    );
  }

  // 공지 올리기 버튼 + 이 동호회에 올린 공지 목록
  Widget _buildNoticeSection() {
    return ValueListenableBuilder<List<ClubNotice>>(
      valueListenable: clubNotices,
      builder: (context, notices, _) {
        final myNotices =
            notices.where((n) => n.clubId == widget.club.id).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: '공지', count: myNotices.length),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _openNoticeSheet,
                icon: const Icon(Icons.campaign_rounded),
                label: const Text('공지 올리기'),
              ),
            ),
            for (final notice in myNotices) ...[
              const SizedBox(height: 12),
              _NoticeCard(notice: notice),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMemberList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow(),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _members.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 72),
            _MemberTile(
              member: _members[i],
              onKick: _members[i].isLeader
                  ? null
                  : () => _confirmKick(_members[i]),
            ),
          ],
        ],
      ),
    );
  }
}

// 공지 작성 바텀시트 (작성한 내용을 돌려줌)
class _NoticeSheet extends StatefulWidget {
  const _NoticeSheet();

  @override
  State<_NoticeSheet> createState() => _NoticeSheetState();
}

class _NoticeSheetState extends State<_NoticeSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📢 공지 올리기',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '올린 공지는 모든 부원에게 알람으로 전송돼요',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            maxLength: 200,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: '예) 이번 주 토요일은 체육관 공사로 오후 4시에 모여요!',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, _controller.text),
              child: const Text('부원들에게 보내기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});

  final ClubNotice notice;

  @override
  Widget build(BuildContext context) {
    final t = notice.createdAt;
    final time =
        '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notice.message,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$time · 읽은 부원 ${notice.readBy.length}명',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// 이름 첫 글자 동그라미
class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        shape: BoxShape.circle,
      ),
      child: Text(
        name.characters.first,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({
    required this.applicant,
    required this.onApprove,
    required this.onReject,
  });

  final ClubMember applicant;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InitialAvatar(
                name: applicant.name,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicant.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${applicant.joinedAt} 신청',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (applicant.introduction != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                applicant.introduction!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('거절'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onApprove,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('승인'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, this.onKick});

  final ClubMember member;
  final VoidCallback? onKick; // null이면 내보낼 수 없음 (회장)

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          _InitialAvatar(
            name: member.name,
            color: member.isLeader ? AppColors.leaderDark : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (member.isLeader) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.leader.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '👑 회장',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.leaderDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${member.joinedAt} 가입',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onKick != null)
            TextButton(
              onPressed: onKick,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('내보내기'),
            ),
        ],
      ),
    );
  }
}
