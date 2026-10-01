import 'package:flutter/material.dart';
import 'auth.dart';
import 'theme.dart';

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

  @override
  void initState() {
    super.initState();
    _loadClubInfo();
  }

  // TODO: DB 연결 후 widget.clubId로 조회한 실제 데이터로 교체
  Future<void> _loadClubInfo() async {
    setState(() {
      _recruitCount = 10;
      _meetingTime = widget.meetingTime ?? '';
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

  Widget _buildJoinGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '가입 안내',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
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
              if (myClubId == null) return _buildApplyButton();
              return _buildBlockedButton(
                myClubId == widget.clubId
                    ? '👑 내가 운영 중인 동호회예요'
                    : '회장은 다른 동호회에 가입할 수 없어요',
              );
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
          onPressed: () {
            // TODO: 가입 신청 기능 (서버에서도 회장이면 가입을 거절해야 함)
          },
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
