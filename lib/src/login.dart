import 'package:flutter/material.dart';
import 'm_signup.dart' show PasswordField;
import 'auth.dart';
import 'registration_selection.dart';
import 'social_login_buttons.dart';
import 'theme.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  void _login() {
    if (_emailController.text.trim().isEmpty || _pwController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요')));
      return;
    }
    // TODO: 서버에 이메일/비밀번호 확인 요청 (지금은 테스트 계정만 로그인 가능)
    final user = findTestAccount(_emailController.text, _pwController.text);
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아이디 또는 비밀번호가 올바르지 않아요')));
      return;
    }
    loginAs(user);
  }

  // TODO: 테스트용 빠른 로그인 — 서버 로그인이 생기면 삭제
  Widget _buildTestAccounts() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧪 테스트 계정 (비밀번호 $testPassword)',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final user in testAccounts) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => loginAs(user),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: user.isLeader
                          ? AppColors.leaderDark
                          : AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(
                      '${user.isLeader ? '👑' : '🙋'} ${user.name}\n(${user.loginId})',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                if (user != testAccounts.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 22),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '카카오 계정이나 이메일로 로그인하세요',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 24),
                  SocialLoginButtons(
                    // 처음 온 소셜 사용자는 회원/회장 선택부터
                    onNeedsSignup: (social) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Registration(social: social),
                      ),
                    ),
                  ),

                  _label('아이디 (이메일 주소)'),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'leader 또는 member',
                      prefixIcon: const Icon(Icons.mail_outline_rounded),
                    ),
                  ),

                  _label('비밀번호'),
                  PasswordField(controller: _pwController, hint: '비밀번호를 입력하세요'),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('비밀번호를 잊으셨나요?'),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: _login,
                        child: const Text('로그인'),
                      ),
                    ),
                  ),
                  _buildTestAccounts(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '아직 계정이 없으신가요?',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const Registration(),
                            ),
                          );
                        },
                        child: const Text('회원가입'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상단 브랜드 영역: 그라데이션 배경 + 로고 + 소개 문구
  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 36,
        24,
        36,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 배경 장식 이모지
          const Positioned(
            right: -4,
            top: -12,
            child: Opacity(
              opacity: 0.9,
              child: Text('🏸', style: TextStyle(fontSize: 44)),
            ),
          ),
          const Positioned(
            right: 56,
            top: 44,
            child: Opacity(
              opacity: 0.85,
              child: Text('🎸', style: TextStyle(fontSize: 30)),
            ),
          ),
          const Positioned(
            right: 8,
            top: 88,
            child: Opacity(
              opacity: 0.85,
              child: Text('📚', style: TextStyle(fontSize: 32)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.diversity_3_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'HABL',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '취미가 같은 사람들과\n함께하는 즐거움',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
