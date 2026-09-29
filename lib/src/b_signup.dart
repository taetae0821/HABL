import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import './m_signup.dart' show PasswordField;
import 'social_auth.dart';
import 'social_login_buttons.dart';

class BSignup extends StatefulWidget {
  final PendingSocialSignup? social;

  const BSignup({super.key, this.social});

  @override
  State<BSignup> createState() => _SignupState();
}

// 회장 가입 화면을 회원 가입과 구분하기 위한 금색 테마
const _leaderColor = Color(0xFFE0A100);

ThemeData _leaderTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _leaderColor,
      brightness: base.brightness,
    ),
  );
}

class _SignupState extends State<BSignup> {
  // 소셜 계정으로 가입 중이면 이메일/비밀번호 입력을 생략합니다
  PendingSocialSignup? _social;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.social != null) _applySocial(widget.social!);
  }

  void _applySocial(PendingSocialSignup social) {
    _social = social;
    if (_nameController.text.isEmpty) {
      _nameController.text = social.name ?? '';
    }
  }

  void _startSocialSignup(PendingSocialSignup social) =>
      setState(() => _applySocial(social));

  // TODO: 한 줄 소개·활동 지역·운영 경험은 저장할 DB 컬럼이 아직 없어 서버로 보내지 않음
  Future<void> _submitSocial() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('이름과 전화번호를 입력해주세요')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await completeSocialSignup(
        _social!,
        role: 'LEADER',
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      navigator.popUntil((route) => route.isFirst);
    } on SocialAuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  final _nameController = TextEditingController();
  final _birthController = TextEditingController();
  DateTime? _birthDate;
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();

  // 회장만 입력하는 정보
  final _introController = TextEditingController();
  final _regionController = TextEditingController();
  String? _experience;
  static const _experienceOptions = ['처음이에요', '1년 미만', '1~3년', '3년 이상'];

  @override
  void dispose() {
    _introController.dispose();
    _regionController.dispose();
    _nameController.dispose();
    _birthController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    super.dispose();
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 22),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
      );

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Theme(
        data: _leaderTheme(sheetContext),
        child: _BirthDateSheet(
          initial: _birthDate ?? DateTime(now.year - 25, 1, 1),
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _birthDate = picked;
      _birthController.text =
          '${picked.year}.${picked.month.toString().padLeft(2, '0')}.${picked.day.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _leaderTheme(context),
      child: Builder(builder: _buildPage),
    );
  }

  Widget _buildPage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmText = _pwConfirmController.text;
    final isMatch = confirmText == _pwController.text;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: _leaderColor,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _leaderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '👑 동호회 회장',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB07A00),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '회장으로 시작하기',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '멤버들이 믿고 함께할 수 있도록 회장님을 소개해 주세요',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 28),
              if (_social == null)
                SocialLoginButtons(onNeedsSignup: _startSocialSignup)
              else
                SocialSignupBanner(social: _social!),

              // 회장 전용 입력 영역
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.star_rounded, color: _leaderColor, size: 20),
                        SizedBox(width: 6),
                        Text(
                          '회장 정보',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '동호회 페이지에서 멤버들에게 보여지는 정보예요',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),

                    _label('한 줄 소개'),
                    TextField(
                      controller: _introController,
                      maxLength: 40,
                      decoration: InputDecoration(
                        hintText: '주말마다 함께 달릴 러닝 메이트를 찾아요!',
                        prefixIcon: Icon(Icons.chat_bubble_outline,
                            color: Colors.grey.shade500),
                      ),
                    ),

                    _label('주 동호회 활동 지역'),
                    TextField(
                      controller: _regionController,
                      decoration: InputDecoration(
                        hintText: '서울 마포구',
                        prefixIcon: Icon(Icons.place_outlined,
                            color: Colors.grey.shade500),
                      ),
                    ),

                    _label('모임 운영 경험'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in _experienceOptions)
                          ChoiceChip(
                            label: Text(option),
                            selected: _experience == option,
                            onSelected: (_) =>
                                setState(() => _experience = option),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              _label('기본 정보'),

              _label('이름'),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '홍길동',
                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade500),
                ),
              ),

              _label('생년월일'),
              TextField(
                controller: _birthController,
                readOnly: true,
                onTap: _pickBirthDate,
                decoration: InputDecoration(
                  hintText: '2000.01.01',
                  prefixIcon: Icon(Icons.cake_outlined, color: Colors.grey.shade500),
                  suffixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey.shade500),
                ),
              ),

              if (_social == null) ...[
                _label('이메일 주소'),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.mail_outline, color: Colors.grey.shade500),
                  ),
                ),
              ],
              _label('전화번호'),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '010-1234-1234',
                  prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey.shade500),
                ),
              ),

              if (_social == null) ...[
                _label('비밀번호'),
                PasswordField(
                  controller: _pwController,
                  hint: '8자 이상 입력하세요',
                  onChanged: (_) => setState(() {}),
                ),

                _label('비밀번호 확인'),
                PasswordField(
                  controller: _pwConfirmController,
                  hint: '비밀번호를 한 번 더 입력하세요',
                  onChanged: (_) => setState(() {}),
                  errorText: confirmText.isNotEmpty && !isMatch
                      ? '비밀번호가 일치하지 않습니다'
                      : null,
                ),
              ],

              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    // TODO: 이메일 가입도 서버(/auth/signup)에 연결
                    onPressed: _social == null
                        ? () {}
                        : (_submitting ? null : _submitSocial),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('회장으로 가입하기'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('이미 계정이 있으신가요?',
                      style: TextStyle(color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: () {
                      // 처음 화면(로그인)으로 돌아갑니다
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('로그인'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 년 / 월 / 일을 각각 휠로 고르는 생년월일 선택 시트
class _BirthDateSheet extends StatefulWidget {
  final DateTime initial;

  const _BirthDateSheet({required this.initial});

  @override
  State<_BirthDateSheet> createState() => _BirthDateSheetState();
}

class _BirthDateSheetState extends State<_BirthDateSheet> {
  static const _firstYear = 1900;
  final _today = DateTime.now();

  late int _year = widget.initial.year;
  late int _month = widget.initial.month;
  late int _day = widget.initial.day;

  late final _yearController =
      FixedExtentScrollController(initialItem: _year - _firstYear);
  late final _monthController =
      FixedExtentScrollController(initialItem: _month - 1);
  late final _dayController = FixedExtentScrollController(initialItem: _day - 1);

  // 오늘 이후 날짜는 고를 수 없게 제한합니다
  int get _maxMonth => _year == _today.year ? _today.month : 12;
  int get _maxDay {
    if (_year == _today.year && _month == _today.month) return _today.day;
    return DateTime(_year, _month + 1, 0).day; // 해당 월의 마지막 날
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  // 년/월이 바뀌어 선택된 월·일이 범위를 넘으면 마지막 값으로 맞춥니다
  void _clamp() {
    if (_month > _maxMonth) {
      _month = _maxMonth;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _monthController.jumpToItem(_month - 1));
    }
    if (_day > _maxDay) {
      _day = _maxDay;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _dayController.jumpToItem(_day - 1));
    }
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required int start,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) {
    return Expanded(
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 44,
        selectionOverlay: const SizedBox.shrink(),
        onSelectedItemChanged: onChanged,
        children: List.generate(
          count,
          (i) => Center(
            child: Text(
              '${start + i}$suffix',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '생년월일 선택',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 가운데 선택 영역 강조
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Row(
                    children: [
                      _wheel(
                        controller: _yearController,
                        count: _today.year - _firstYear + 1,
                        start: _firstYear,
                        suffix: '년',
                        onChanged: (i) => setState(() {
                          _year = _firstYear + i;
                          _clamp();
                        }),
                      ),
                      _wheel(
                        controller: _monthController,
                        count: _maxMonth,
                        start: 1,
                        suffix: '월',
                        onChanged: (i) => setState(() {
                          _month = i + 1;
                          _clamp();
                        }),
                      ),
                      _wheel(
                        controller: _dayController,
                        count: _maxDay,
                        start: 1,
                        suffix: '일',
                        onChanged: (i) => setState(() => _day = i + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () => Navigator.of(context)
                        .pop(DateTime(_year, _month, _day)),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
