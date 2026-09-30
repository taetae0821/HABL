import 'package:flutter/material.dart';
import 'social_auth.dart';
import 'theme.dart';

// 카카오로 계속하기 버튼 (+ 이메일 구분선)
// 이미 가입된 계정이면 바로 로그인되고, 처음이면 onNeedsSignup 이 호출됩니다.
class SocialLoginButtons extends StatefulWidget {
  final ValueChanged<PendingSocialSignup> onNeedsSignup;

  const SocialLoginButtons({super.key, required this.onNeedsSignup});

  @override
  State<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

class _SocialLoginButtonsState extends State<SocialLoginButtons> {
  SocialProvider? _loading;

  Future<void> _signIn(SocialProvider provider) async {
    setState(() => _loading = provider);
    try {
      final pending = await signInWithSocial(provider);
      if (!mounted) return;
      if (pending == null) {
        // 로그인 완료 — 쌓여 있는 가입 화면을 닫고 메인으로
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        widget.onNeedsSignup(pending);
      }
    } on SocialLoginCanceled {
      // 사용자가 창을 닫은 경우는 조용히 넘어갑니다
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is SocialAuthException ? e.message : '로그인 중 오류가 발생했습니다.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = null);
    }
  }

  Widget _button({
    required SocialProvider provider,
    required Color background,
    required Color foreground,
    required Widget icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
        ),
        onPressed: _loading == null ? () => _signIn(provider) : null,
        child: _loading == provider
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: foreground,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text('${provider.label}로 계속하기'),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _button(
          provider: SocialProvider.kakao,
          background: const Color(0xFFFEE500),
          foreground: const Color(0xD9000000),
          icon: const Icon(Icons.chat_bubble, size: 20),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '또는 이메일로',
                style: const TextStyle(fontSize: 13, color: AppColors.textHint),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
      ],
    );
  }
}

// 소셜 계정으로 가입 중일 때 가입 화면 위쪽에 보여주는 안내
class SocialSignupBanner extends StatelessWidget {
  final PendingSocialSignup social;

  const SocialSignupBanner({super.key, required this.social});

  @override
  Widget build(BuildContext context) {
    final isKakao = social.provider == SocialProvider.kakao;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isKakao ? const Color(0x33FEE500) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isKakao ? const Color(0xFFFEE500) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              social.email == null
                  ? '${social.provider.label} 계정으로 가입 중이에요'
                  : '${social.provider.label} 계정(${social.email})으로 가입 중이에요',
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
