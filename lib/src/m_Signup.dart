import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import './login.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _nameController = TextEditingController();
  final _birthController = TextEditingController();
  DateTime? _birthDate;
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();

  @override
  void dispose() {
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
      builder: (_) => _BirthDateSheet(
        initial: _birthDate ?? DateTime(now.year - 25, 1, 1),
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '계정 만들기',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '몇 가지 정보만 입력하면 시작할 수 있어요',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),

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

              _label('이메일 주소'),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'name@example.com',
                  prefixIcon: Icon(Icons.mail_outline, color: Colors.grey.shade500),
                ),
              ),
              _label('전화번호'),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '010-1234-1234',
                  prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey.shade500),
                ),
              ),

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
                    onPressed: () {},
                    child: const Text('가입하기'),
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
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const Login()),
                      );
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

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const PasswordField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.errorText,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        errorText: widget.errorText,
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade500),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey.shade500,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
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
