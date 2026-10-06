import 'package:flutter/material.dart';
import 'auth.dart';
import 'theme.dart';

// 사용자별로 가입 신청한 동호회 id (화면을 다시 열어도 '신청 완료' 유지)
// TODO: DB 연결 후 서버의 가입 신청 목록으로 교체
final Map<String, Set<int>> _appliedClubIds = {};

class Club extends StatefulWidget {
  const Club({
    super.key,
    required this.clubName,
    this.clubId,
    this.imageUrl,
    this.location,
    this.meetingTime,
  });

  // 동호회 명 (나중에 바뀔 수 있음)
  final String clubName;

  // 목록에서 넘겨받는 값 (DB 조회 전 먼저 보여줄 값)
  final int? clubId;
  final String? imageUrl;
  final String? location;
  final String? meetingTime;

  @override
  State<Club> createState() => _ClubState();
}

class _ClubState extends State<Club> {
  // DB에서 가져올 값들
  int _recruitCount = 0; // 회원 모집 수
  String _meetingTime = ''; // 언제 모이는지
  String _location = ''; // 위치
  String _imageUrl = ''; // 대표 이미지 URL
  List<String> _joinGuide = []; // 가입 안내 (단계별)
  List<DateTime> _meetingDates = []; // 이번 달 실제 모임 날짜

  @override
  void initState() {
    super.initState();
    _loadClubInfo();
  }

  // 모임 시각만 (예: '매주 토요일 오후 2시' → '오후 2시')
  String get _meetingClock => _meetingTime.split('요일').last.trim();

  // TODO: DB 연결 후 GET /clubs/:id/meetings?month=YYYY-MM 으로 받은 실제 모임 날짜로 교체
  // (임시 샘플: 이번 달 모임 요일 중 첫째·셋째·다섯째 주만 모임)
  List<DateTime> _sampleMeetingDates(String info) {
    final index = _weekdayNames.indexWhere((name) => info.contains('$name요일'));
    if (index < 0) return [];

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final sameWeekdays = [
      for (var d = 1; d <= daysInMonth; d++)
        if (DateTime(now.year, now.month, d).weekday == index + 1)
          DateTime(now.year, now.month, d),
    ];
    return [
      for (var i = 0; i < sameWeekdays.length; i += 2) sameWeekdays[i],
    ];
  }

  // TODO: DB 연결 후 widget.clubId로 조회한 실제 데이터로 교체
  Future<void> _loadClubInfo() async {
    setState(() {
      _recruitCount = 10;
      _meetingTime = widget.meetingTime ?? '';
      _meetingDates = _sampleMeetingDates(_meetingTime);
      _location = widget.location ?? '';
      _imageUrl = widget.imageUrl ?? '';
      _joinGuide = [
        '아래 가입 신청 버튼을 눌러 신청서를 작성해 주세요.',
        '운영진이 확인 후 개별 연락을 드립니다.',
        '첫 모임에 참석하면 정식 회원으로 등록됩니다.',
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Transform.translate(
              offset: const Offset(0, -24), // 이미지를 살짝 덮도록 위로 올림
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecruitBadge(),
                    const SizedBox(height: 12),
                    Text(
                      widget.clubName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInfoCard(),
                    if (_meetingDates.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildSectionTitle('이번 달 모임 일정'),
                      const SizedBox(height: 16),
                      _MeetingCalendar(
                        meetingDates: _meetingDates,
                        time: _meetingClock,
                      ),
                    ],
                    const SizedBox(height: 32),
                    _buildJoinGuide(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildJoinButton(),
    );
  }

  // 상단 대표 이미지 + 뒤로가기 버튼
  Widget _buildHeader() {
    return Stack(
      children: [
        _buildImage(),
        // 상단 버튼이 잘 보이도록 살짝 어둡게
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.95),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ),
      ],
    );
  }

  // 대표 이미지: URL이 없거나 불러오기 실패하면 기본 이미지 표시
  Widget _buildImage() {
    const double height = 300;
    final placeholder = Image.asset(
      'assets/badminton_img.png',
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
    );

    if (_imageUrl.isEmpty) return placeholder;

    // 앱에 포함된 이미지 경로 (예: assets/sample/...)
    if (_imageUrl.startsWith('assets/')) {
      return Image.asset(
        _imageUrl,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      _imageUrl,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const SizedBox(
          height: height,
          child: Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }

  Widget _buildRecruitBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '🔥 회원 $_recruitCount명 모집 중',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow(),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.groups_rounded,
            color: AppColors.primary,
            label: '모집 인원',
            value: '$_recruitCount명',
          ),
          const SizedBox(height: 18),
          _InfoRow(
            icon: Icons.schedule_rounded,
            color: AppColors.secondary,
            label: '모임 시간',
            value: _meetingTime,
          ),
          const SizedBox(height: 18),
          _InfoRow(
            icon: Icons.place_rounded,
            color: AppColors.leader,
            label: '위치',
            value: _location,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildJoinGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('가입 안내'),
        const SizedBox(height: 16),
        for (var i = 0; i < _joinGuide.length; i++)
          _GuideStep(
            number: i + 1,
            text: _joinGuide[i],
            isLast: i == _joinGuide.length - 1,
          ),
      ],
    );
  }

  bool get _isJoined =>
      currentUser.value?.joinedClubIds.contains(widget.clubId) ?? false;

  bool get _isApplied =>
      _appliedClubIds[currentUser.value?.loginId]?.contains(widget.clubId) ??
      false;

  // TODO: DB 연결 후 POST /clubs/:id/applications 로 신청
  // (서버에서도 회장이거나 이미 가입한 사용자면 거절해야 함)
  void _apply() {
    final loginId = currentUser.value?.loginId;
    final clubId = widget.clubId;
    if (loginId == null || clubId == null) return;

    setState(() => _appliedClubIds.putIfAbsent(loginId, () => {}).add(clubId));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '🎉 ${widget.clubName}에 가입 신청했어요!\n회장이 승인하면 알려드릴게요.',
          ),
        ),
      );
  }

  Future<void> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.clubName}에서 탈퇴할까요?'),
        content: const Text('탈퇴하면 모임 알람과 공지를 더 이상 받을 수 없어요.\n다시 가입하려면 가입 신청을 해야 해요.'),
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
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );
    final clubId = widget.clubId;
    if (ok != true || clubId == null || !mounted) return;

    setState(() => leaveClub(clubId));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${widget.clubName}에서 탈퇴했어요')),
      );
  }

  // 가입한 동호회: 가입 상태 안내 + 탈퇴 버튼
  Widget _buildLeaveButton() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '🙌 가입한 동호회예요',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: _confirmLeave,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('탈퇴하기'),
          ),
        ),
      ],
    );
  }

  // 회장은 다른 동호회에 가입할 수 없으므로 가입 버튼 대신 안내를 보여줌
  Widget _buildJoinButton() {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: ValueListenableBuilder<int?>(
            valueListenable: leadingClubId,
            builder: (context, myClubId, _) {
              if (myClubId != null) {
                return _buildBlockedButton(
                  myClubId == widget.clubId
                      ? '👑 내가 운영 중인 동호회예요'
                      : '회장은 다른 동호회에 가입할 수 없어요',
                );
              }
              if (_isJoined) return _buildLeaveButton();
              if (_isApplied) return _buildBlockedButton('✅ 신청 완료 · 승인 대기 중');
              return _buildApplyButton();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedButton(String message) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
        ),
        onPressed: null,
        child: Text(
          message,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow(AppColors.primary),
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          onPressed: _apply,
          child: const Text(
            '가입 신청하기',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 가입 안내 한 단계: 번호 원 + 연결선 + 설명
class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.text,
    required this.isLast,
  });

  final int number;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.primaryLight),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 20),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// 이번 달 달력: 실제 모임 날짜만 강조하고, 지난 날은 회색으로 표시
class _MeetingCalendar extends StatelessWidget {
  const _MeetingCalendar({required this.meetingDates, required this.time});

  final List<DateTime> meetingDates;
  final String time; // 모임 시각 (예: 오후 2시)

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final month = DateTime(today.year, today.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = month.weekday % 7; // 일요일 시작 달력
    final meetings = {for (final d in meetingDates) _dateOnly(d)};
    final next = (meetings.where((d) => !d.isBefore(today)).toList()..sort())
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow(),
      ),
      child: Column(
        children: [
          Text(
            '${month.year}년 ${month.month}월',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '모임 ${meetings.length}회',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          // 요일 머리글 (일 ~ 토)
          Row(
            children: [
              for (final name in ['일', ..._weekdayNames.take(6)])
                Expanded(
                  child: Center(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: name == '일'
                            ? AppColors.primary
                            : name == '토'
                            ? const Color(0xFF4C7DF0)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
              for (var d = 1; d <= daysInMonth; d++)
                _DayCell(
                  day: d,
                  isMeeting: meetings.contains(
                    DateTime(month.year, month.month, d),
                  ),
                  isToday: d == today.day,
                  isPast: d < today.day,
                ),
            ],
          ),
          const SizedBox(height: 10),
          // 다음 모임 안내
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: next == null ? AppColors.background : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 20,
                  color: next == null ? AppColors.textHint : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    next == null
                        ? '이번 달 남은 모임이 없어요'
                        : '다음 모임  ${next.month}월 ${next.day}일 '
                              '(${_weekdayNames[next.weekday - 1]}) $time'
                              '${next == today ? ' · 오늘!' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: next == null
                          ? AppColors.textSecondary
                          : AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isMeeting,
    required this.isToday,
    required this.isPast,
  });

  final int day;
  final bool isMeeting;
  final bool isToday;
  final bool isPast; // 지난 날은 회색

  static const _pastFill = Color(0xFFEFECEF);
  static const _pastMeetingFill = Color(0xFFCFCAD1);

  @override
  Widget build(BuildContext context) {
    final Color? fill;
    final Color textColor;
    if (isPast) {
      fill = isMeeting ? _pastMeetingFill : _pastFill;
      textColor = isMeeting ? Colors.white : AppColors.textHint;
    } else {
      fill = null;
      textColor = isMeeting ? Colors.white : AppColors.textPrimary;
    }

    return Center(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          gradient: isMeeting && !isPast ? AppColors.heroGradient : null,
          border: isToday && !isMeeting
              ? Border.all(color: AppColors.primary, width: 1.6)
              : null,
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isMeeting || isToday ? FontWeight.w800 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

