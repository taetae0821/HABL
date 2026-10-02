import 'package:flutter/material.dart';
import 'package:habl/src/club.dart';
import 'package:habl/src/find_club.dart';
import 'package:habl/src/theme.dart';

// 가입한 동호회의 모임 일정 알림 한 건
class MeetingAlarm {
  const MeetingAlarm({
    required this.club,
    required this.date,
    required this.time,
  });

  final ClubSummary club;
  final DateTime date; // 모임 날짜
  final String time; // 모임 시간 (예: 오후 2시)
}

class Alarm extends StatefulWidget {
  const Alarm({super.key});

  @override
  State<Alarm> createState() => _AlarmState();
}

class _AlarmState extends State<Alarm> {
  List<MeetingAlarm> _alarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // 오늘로부터 며칠 뒤인지 (오늘 = 0)
  static int _daysFromToday(DateTime date) =>
      _dateOnly(date).difference(_dateOnly(DateTime.now())).inDays;

  // TODO: DB 연결 후 GET /users/me/meetings 처럼 가입한 동호회의
  // 다가오는 모임 일정을 서버에서 받아오도록 교체 (날짜순 정렬)
  // (아래는 임시 샘플: 오늘 기준으로 날짜를 만들어 항상 '오늘' 알림이 보이게 함)
  Future<void> _loadAlarms() async {
    final today = _dateOnly(DateTime.now());

    setState(() {
      _alarms = [
        MeetingAlarm(
          date: today,
          time: '오후 2시',
          club: const ClubSummary(
            id: 1,
            name: '스매시 파크 성동',
            category: '운동',
            description: '초보부터 실력자까지 함께 즐기는 배드민턴 모임입니다.',
            locationName: '서울 성동구',
            regularMeetingInfo: '매주 토요일 오후 2시',
            imageUrl: 'assets/badminton_img.png',
          ),
        ),
        MeetingAlarm(
          date: today.add(const Duration(days: 2)),
          time: '오전 11시',
          club: const ClubSummary(
            id: 2,
            name: '주말 북클럽',
            category: '스터디',
            description: '한 달에 한 권, 같이 읽고 이야기 나눠요.',
            locationName: '서울 마포구',
            regularMeetingInfo: '격주 일요일 오전 11시',
            imageUrl: 'assets/sample/book_club.jpg',
          ),
        ),
      ];
      _isLoading = false;
    });
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

    final todayAlarms =
        _alarms.where((a) => _daysFromToday(a.date) == 0).toList();
    final upcomingAlarms =
        _alarms.where((a) => _daysFromToday(a.date) > 0).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadAlarms,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _buildGreeting(),
              const SizedBox(height: 20),
              if (todayAlarms.isEmpty)
                _buildNoMeetingToday()
              else
                for (final alarm in todayAlarms)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _TodayAlarmCard(
                      alarm: alarm,
                      onTap: () => _openClub(alarm.club),
                    ),
                  ),
              if (upcomingAlarms.isNotEmpty) ...[
                const SizedBox(height: 18),
                _buildSectionTitle('다가오는 모임', upcomingAlarms.length),
                const SizedBox(height: 12),
                for (final alarm in upcomingAlarms)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UpcomingAlarmTile(
                      alarm: alarm,
                      daysLeft: _daysFromToday(alarm.date),
                      onTap: () => _openClub(alarm.club),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 상단 오늘 날짜 + 제목
  Widget _buildGreeting() {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${now.month}월 ${now.day}일 ${weekdays[now.weekday - 1]}요일',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '모임 알림 🔔',
          style: TextStyle(
            fontSize: 24,
            height: 1.3,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, int count) {
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

  Widget _buildNoMeetingToday() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
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
            child: const Text('😴', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 14),
          const Text(
            '오늘은 예정된 모임이 없어요',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// 오늘 모임 알림: "오늘은 OO에서 OO 모임이 진행됩니다!"
class _TodayAlarmCard extends StatelessWidget {
  const _TodayAlarmCard({required this.alarm, required this.onTap});

  final MeetingAlarm alarm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final club = alarm.club;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow(AppColors.primary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '📣 오늘의 모임',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '오늘은 '),
                      TextSpan(
                        text: club.locationName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const TextSpan(text: '에서\n'),
                      TextSpan(
                        text: club.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const TextSpan(text: ' 모임이 진행됩니다!'),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      alarm.time,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '모임 보기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 다가오는 모임 알림 한 줄
class _UpcomingAlarmTile extends StatelessWidget {
  const _UpcomingAlarmTile({
    required this.alarm,
    required this.daysLeft,
    required this.onTap,
  });

  final MeetingAlarm alarm;
  final int daysLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final club = alarm.club;
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
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: category.light,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${alarm.date.month}월 ${alarm.date.day}일 ${alarm.time} · ${club.locationName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysLeft == 1 ? '내일' : 'D-$daysLeft',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
