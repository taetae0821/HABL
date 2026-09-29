import 'package:flutter/material.dart';
import 'package:habl/src/m_signup.dart';
import 'package:habl/src/b_signup.dart';
import 'package:habl/src/social_auth.dart';
import 'package:habl/src/social_login_buttons.dart';

// 회원 / 회장 가입 화면과 같은 색을 씁니다
const _memberColor = Color(0xFF6C5CE7);
const _leaderColor = Color(0xFFE0A100);

class Registration extends StatelessWidget {
  // 소셜 로그인으로 넘어온 경우 가입 화면까지 전달합니다
  final PendingSocialSignup? social;

  const Registration({super.key, this.social});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _memberColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('🎉', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(height: 20),
              const Text(
                '동호회 세상에\n오신 것을 환영해요',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '나에게 맞는 가입 유형을 골라주세요',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),

              if (social != null) ...[
                const SizedBox(height: 20),
                SocialSignupBanner(social: social!),
              ],

              const SizedBox(height: 28),
              _RoleCard(
                color: _memberColor,
                icon: Icons.person_rounded,
                title: '동호회 회원',
                description: '관심 있는 동호회를 찾아 가입하고\n함께 활동해요',
                tags: const ['모임 찾기', '가입 신청', '활동 알림'],
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => Signup(social: social)),
                ),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                color: _leaderColor,
                icon: Icons.workspace_premium_rounded,
                title: '동호회 회장',
                badge: '👑',
                description: '나만의 동호회를 만들고\n멤버들과 모임을 운영해요',
                tags: const ['동호회 개설', '멤버 관리', '가입 승인'],
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => BSignup(social: social)),
                ),
              ),

              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        size: 18, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '어느 쪽을 선택해도 모임 활동은 자유롭게 시작할 수 있으니 부담 없이 골라보세요!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 가입 유형 하나를 보여주는 카드
class _RoleCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String? badge;
  final String description;
  final List<String> tags;
  final VoidCallback onTap;

  const _RoleCard({
    required this.color,
    required this.icon,
    required this.title,
    this.badge,
    required this.description,
    required this.tags,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.08),
          highlightColor: color.withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            Text(badge!, style: const TextStyle(fontSize: 16)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in tags)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color.lerp(color, Colors.black, 0.25),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
