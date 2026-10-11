import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'theme.dart';

// 앱 처음 실행 시 보여주는 로딩 화면
// 배드민턴 랠리 → 책장 넘기기 → 달리기 → 골인! 순서로 이어지고,
// 끝나면 onFinished 를 호출합니다
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // 전체 진행(0~1) 중 각 장면이 끝나는 지점
  static const double _badmintonEnd = 0.3;
  static const double _bookEnd = 0.58;
  // 달리기 장면 안에서 결승선에 닿는 지점
  static const double _goalAt = 0.62;

  static const double _stageWidth = 320;
  static const double _stageHeight = 220;

  late final AnimationController _story = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7000),
  );

  @override
  void initState() {
    super.initState();
    // TODO: 저장된 로그인 토큰 확인 등 실제 초기화 작업이 생기면 여기서 함께 기다리기
    _story.forward().whenComplete(() {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _story.dispose();
    super.dispose();
  }

  // start~end 구간을 0~1 로 바꾼 값
  double _local(double v, double start, double end) =>
      ((v - start) / (end - start)).clamp(0.0, 1.0);

  // 장면이 바뀔 때 앞뒤로 살짝 겹쳐 흐려지게
  double _sceneOpacity(double v, double start, double end) {
    const fade = 0.035;
    final fadeIn = start == 0 ? 1.0 : ((v - start + fade) / (fade * 2));
    final fadeOut = end == 1 ? 1.0 : ((end + fade - v) / (fade * 2));
    return math.min(fadeIn, fadeOut).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.primaryLight],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _story,
            builder: (context, _) {
              final v = _story.value;
              return Column(
                children: [
                  const Spacer(flex: 3),
                  _buildTitle(),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: _stageWidth,
                    height: _stageHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _scene(v, 0, _badmintonEnd, _buildBadminton),
                        _scene(v, _badmintonEnd, _bookEnd, _buildBook),
                        _scene(v, _bookEnd, 1, _buildRunning),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildProgress(v),
                  const Spacer(flex: 4),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _scene(
    double v,
    double start,
    double end,
    Widget Function(double p) builder,
  ) {
    final opacity = _sceneOpacity(v, start, end);
    if (opacity <= 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: 0.92 + 0.08 * opacity,
          child: builder(_local(v, start, end)),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'Habl',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: -1.5,
          ),
        ),
        SizedBox(height: 2),
        Text(
          '함께라서 더 즐거운 우리 동네 동호회',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // 1. 배드민턴: 셔틀콕이 네트를 넘나들며 랠리
  Widget _buildBadminton(double p) {
    return CustomPaint(painter: _BadmintonPainter(p));
  }

  // 2. 책: 책장이 한 장씩 넘어감
  Widget _buildBook(double p) {
    const pageW = 118.0;
    const pageH = 150.0;
    const flips = 3;

    final index = (p * flips).floor().clamp(0, flips - 1);
    final s = p * flips - index;
    final f = Curves.easeInOut.transform(((s - 0.15) / 0.75).clamp(0.0, 1.0));
    final turned = f > 0.5;

    return Center(
      child: SizedBox(
        width: pageW * 2 + 16,
        height: pageH + 16,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 표지
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4C7DF0),
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppColors.softShadow(const Color(0xFF4C7DF0)),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: _BookPage(
                width: pageW,
                height: pageH,
                seed: index * 2 + (turned ? 1 : 0),
                isLeft: true,
              ),
            ),
            Positioned(
              left: 8 + pageW,
              top: 8,
              child: _BookPage(
                width: pageW,
                height: pageH,
                seed: index * 2 + 2,
                isLeft: false,
              ),
            ),
            // 넘어가는 장
            if (f > 0 && f < 1)
              Positioned(
                left: 8 + pageW,
                top: 8,
                child: Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateY(-math.pi * f),
                  child: Transform(
                    // 뒷면이 보일 때 글자가 뒤집혀 보이지 않게
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(turned ? -1 : 1, 1, 1),
                    child: _BookPage(
                      width: pageW,
                      height: pageH,
                      seed: turned ? index * 2 + 1 : index * 2,
                      isLeft: turned,
                      shade: math.sin(math.pi * f) * 0.25,
                    ),
                  ),
                ),
              ),
            // 가운데 접히는 부분 그림자
            Positioned(
              left: 8 + pageW - 6,
              top: 8,
              child: Container(
                width: 12,
                height: pageH,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. 달리기: 결승선까지 달려가 골인!
  Widget _buildRunning(double p) {
    const finishX = 252.0;
    const groundY = 176.0;
    const runnerSize = 46.0;

    final run = Curves.easeInSine.transform((p / _goalAt).clamp(0.0, 1.0));
    final goal = _local(p, _goalAt, 1);
    final reached = p >= _goalAt;

    final startX = 0.0;
    final endX = finishX - runnerSize * 0.7;
    final runnerX = reached
        ? endX + Curves.easeOut.transform(goal) * 36
        : lerpDouble(startX, endX, run)!;

    // 달릴 땐 통통, 골인 후엔 만세 점프
    final cheering = reached && goal > 0.08;
    final bob = reached
        ? math.sin(math.min(goal * 2, 1) * math.pi * 2).abs() * 26
        : math.sin(p * math.pi * 16).abs() * 7;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _TrackPainter(
              finishX: finishX,
              groundY: groundY,
              goal: reached ? goal : 0,
            ),
          ),
        ),
        // 결승 깃발
        Positioned(
          left: finishX - 4,
          top: groundY - 118,
          child: Transform.rotate(
            angle: math.sin(p * math.pi * (reached ? 30 : 8)) * 0.15,
            alignment: Alignment.bottomLeft,
            child: const Text('🏁', style: TextStyle(fontSize: 30)),
          ),
        ),
        // 달려온 자리에 남는 먼지
        if (!reached)
          for (var i = 0; i < 3; i++)
            Builder(builder: (_) {
              final puff = (p * 10 + i / 3) % 1;
              return Positioned(
                left: runnerX - 10 - puff * 30,
                top: groundY - 22 - puff * 8,
                child: Opacity(
                  opacity: (1 - puff) * 0.7,
                  child: Transform.scale(
                    scale: 0.6 + puff * 0.6,
                    child: const Text('💨', style: TextStyle(fontSize: 16)),
                  ),
                ),
              );
            }),
        Positioned(
          left: runnerX,
          top: groundY - runnerSize - 6 - bob,
          child: Transform.rotate(
            angle: reached ? 0 : 0.08,
            child: Transform(
              // 🏃 이모지는 왼쪽을 보고 있어서 오른쪽으로 뒤집기
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(cheering ? 1 : -1, 1, 1),
              child: Text(
                cheering ? '🙌' : '🏃',
                style: const TextStyle(fontSize: runnerSize),
              ),
            ),
          ),
        ),
        if (reached)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BurstPainter(
                  origin: const Offset(finishX + 10, groundY - 80),
                  t: goal,
                ),
              ),
            ),
          ),
        if (reached)
          Align(
            alignment: const Alignment(0, -0.95),
            child: Transform.scale(
              scale: Curves.elasticOut.transform((goal / 0.45).clamp(0.0, 1.0)),
              child: Transform.rotate(
                angle: -0.08,
                child: const Text(
                  '골인!',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -1,
                    shadows: [
                      Shadow(
                        color: Colors.white,
                        blurRadius: 0,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgress(double v) {
    final String message;
    if (v < _badmintonEnd) {
      message = '랠리 주고받는 중 🏸';
    } else if (v < _bookEnd) {
      message = '책장 넘기는 중 📖';
    } else if (_local(v, _bookEnd, 1) < _goalAt) {
      message = '결승선까지 달리는 중 🏃';
    } else {
      message = '골인! 모임 준비 완료 🎉';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              message,
              key: ValueKey(message),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, color: AppColors.border),
                FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: AppColors.heroGradient,
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

// 책 한 쪽: 글줄을 회색 막대로 표현
class _BookPage extends StatelessWidget {
  const _BookPage({
    required this.width,
    required this.height,
    required this.seed,
    required this.isLeft,
    this.shade = 0,
  });

  final double width;
  final double height;
  final int seed;
  final bool isLeft;
  final double shade;

  @override
  Widget build(BuildContext context) {
    final random = math.Random(seed);
    final hasPicture = seed % 3 == 1;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white, const Color(0xFFD9D4CF), shade),
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(isLeft ? 6 : 0),
          right: Radius.circular(isLeft ? 0 : 6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPicture) ...[
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4C7DF0).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: const Text('📖', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 8),
          ],
          for (var i = 0; i < (hasPicture ? 5 : 9); i++)
            Container(
              margin: const EdgeInsets.only(bottom: 7),
              height: 4,
              width: (width - 28) * (0.55 + random.nextDouble() * 0.45),
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const Spacer(),
          Align(
            alignment: isLeft ? Alignment.bottomLeft : Alignment.bottomRight,
            child: Text(
              '${seed + 1}',
              style: const TextStyle(fontSize: 9, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}

// 네트 양쪽 라켓이 셔틀콕을 주고받는 장면
class _BadmintonPainter extends CustomPainter {
  _BadmintonPainter(this.p);

  final double p;

  static const int _hits = 4;
  static const double _restAngle = -math.pi / 3;
  static const double _reach = 62;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h * 0.9;

    // 바닥
    canvas.drawLine(
      Offset(8, groundY),
      Offset(w - 8, groundY),
      Paint()
        ..color = AppColors.border
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // 네트
    final netX = w / 2;
    final netTop = h * 0.45;
    canvas.drawLine(
      Offset(netX, groundY),
      Offset(netX, netTop - 4),
      Paint()
        ..color = AppColors.textSecondary
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final netRect = Rect.fromLTRB(netX - 6, netTop, netX + 6, netTop + 50);
    final meshPaint = Paint()
      ..color = AppColors.textHint
      ..strokeWidth = 1;
    for (var y = netRect.top; y <= netRect.bottom; y += 6) {
      canvas.drawLine(Offset(netRect.left, y), Offset(netRect.right, y), meshPaint);
    }
    canvas.drawRect(
      Rect.fromLTRB(netRect.left - 1, netTop - 3, netRect.right + 1, netTop + 2),
      Paint()..color = Colors.white,
    );

    // 랠리 진행
    final seg = (p * _hits).floor().clamp(0, _hits - 1);
    final s = p * _hits - seg;
    final fromLeft = seg.isEven;

    // 친 쪽은 휘두르고, 받을 쪽은 뒤로 젖혀 준비
    double hit(double s) => s < 0.22 ? math.sin(s / 0.22 * math.pi) : 0;
    double windup(double s) => s > 0.7 ? -(s - 0.7) / 0.3 * 0.7 : 0;
    final leftSwing = fromLeft ? hit(s) : windup(s);
    final rightSwing = fromLeft ? windup(s) : hit(s);

    final leftPivot = Offset(w * 0.08, h * 0.82);
    final rightPivot = Offset(w * 0.92, h * 0.82);
    final leftHit =
        leftPivot + Offset(math.cos(_restAngle), math.sin(_restAngle)) * _reach;
    final rightHit = Offset(w - leftHit.dx, leftHit.dy);

    _drawRacket(canvas, leftPivot, _restAngle + leftSwing * 0.7, AppColors.primary, false);
    _drawRacket(canvas, rightPivot, _restAngle + rightSwing * 0.7, AppColors.secondary, true);

    // 셔틀콕 궤적: 포물선
    final from = fromLeft ? leftHit : rightHit;
    final to = fromLeft ? rightHit : leftHit;
    final arc = h * 0.42;
    Offset at(double s) => Offset(
          lerpDouble(from.dx, to.dx, s)!,
          lerpDouble(from.dy, to.dy, s)! - math.sin(math.pi * s) * arc,
        );

    // 잔상
    for (var i = 1; i <= 4; i++) {
      final ts = s - i * 0.04;
      if (ts < 0) break;
      canvas.drawCircle(
        at(ts),
        3.5 - i * 0.5,
        Paint()..color = AppColors.primary.withValues(alpha: 0.18 - i * 0.03),
      );
    }

    final pos = at(s);
    final angle = math.atan2(
      -math.cos(math.pi * s) * math.pi * arc,
      to.dx - from.dx,
    );
    _drawShuttle(canvas, pos, angle);
  }

  void _drawRacket(Canvas canvas, Offset pivot, double angle, Color color, bool mirror) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    if (mirror) canvas.scale(-1, 1);
    canvas.rotate(angle);

    // 손잡이
    canvas.drawLine(
      Offset.zero,
      const Offset(16, 0),
      Paint()
        ..color = Color.lerp(color, Colors.black, 0.35)!
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(16, 0),
      const Offset(38, 0),
      Paint()
        ..color = AppColors.textSecondary
        ..strokeWidth = 2.5,
    );

    // 헤드 + 줄
    final head = Rect.fromCenter(center: const Offset(56, 0), width: 38, height: 30);
    canvas.drawOval(head, Paint()..color = Colors.white.withValues(alpha: 0.85));
    canvas.save();
    canvas.clipPath(Path()..addOval(head));
    final stringPaint = Paint()
      ..color = AppColors.textHint
      ..strokeWidth = 0.8;
    for (var x = head.left; x <= head.right; x += 5) {
      canvas.drawLine(Offset(x, head.top), Offset(x, head.bottom), stringPaint);
    }
    for (var y = head.top; y <= head.bottom; y += 5) {
      canvas.drawLine(Offset(head.left, y), Offset(head.right, y), stringPaint);
    }
    canvas.restore();
    canvas.drawOval(
      head,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    canvas.restore();
  }

  // 코르크(머리)가 날아가는 방향을 향하도록 그림
  void _drawShuttle(Canvas canvas, Offset pos, double angle) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final feathers = Path()
      ..moveTo(2, -4)
      ..lineTo(-14, -9)
      ..lineTo(-14, 9)
      ..lineTo(2, 4)
      ..close();
    canvas.drawPath(feathers, Paint()..color = Colors.white);
    canvas.drawPath(
      feathers,
      Paint()
        ..color = AppColors.textHint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawLine(
      const Offset(-6, -6.5),
      const Offset(-6, 6.5),
      Paint()
        ..color = AppColors.textHint
        ..strokeWidth = 1,
    );
    canvas.drawCircle(const Offset(5, 0), 5, Paint()..color = AppColors.primary);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BadmintonPainter oldDelegate) => oldDelegate.p != p;
}

// 달리기 트랙과 결승선
class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.finishX,
    required this.groundY,
    required this.goal,
  });

  final double finishX;
  final double groundY;
  final double goal;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // 트랙
    final track = RRect.fromRectAndRadius(
      Rect.fromLTRB(0, groundY - 4, w, groundY + 26),
      const Radius.circular(8),
    );
    canvas.drawRRect(track, Paint()..color = const Color(0xFFFF9A7A));
    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2;
    for (var x = 6.0; x < w; x += 22) {
      canvas.drawLine(Offset(x, groundY + 11), Offset(x + 11, groundY + 11), lanePaint);
    }

    // 바닥 체크무늬 결승선
    const cell = 5.0;
    for (var row = 0; row < 6; row++) {
      for (var col = 0; col < 2; col++) {
        canvas.drawRect(
          Rect.fromLTWH(finishX + col * cell, groundY - 4 + row * cell, cell, cell),
          Paint()..color = (row + col).isEven ? Colors.white : AppColors.textPrimary,
        );
      }
    }

    // 깃대
    canvas.drawLine(
      Offset(finishX, groundY),
      Offset(finishX, groundY - 92),
      Paint()
        ..color = AppColors.textSecondary
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // 결승 테이프: 골인 전엔 팽팽하게, 골인하면 끊어져 휘날림
    final tapePaint = Paint()
      ..color = AppColors.leader
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final tapeY = groundY - 38;
    if (goal == 0) {
      canvas.drawLine(Offset(finishX, tapeY), Offset(finishX - 14, tapeY + 2), tapePaint);
    } else {
      final drop = Curves.easeOut.transform(goal) * 26;
      final wave = math.sin(goal * math.pi * 10) * 5;
      canvas.drawPath(
        Path()
          ..moveTo(finishX, tapeY)
          ..quadraticBezierTo(finishX + 10, tapeY + drop / 2 + wave, finishX + 4, tapeY + drop),
        tapePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TrackPainter oldDelegate) =>
      oldDelegate.goal != goal || oldDelegate.finishX != finishX;
}

// 골인 순간 터지는 꽃가루
class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.origin, required this.t});

  final Offset origin;
  final double t;

  static final List<(double, double, Color, double)> _pieces = () {
    final random = math.Random(3);
    return List.generate(32, (_) {
      final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 1.4;
      final speed = 150 + random.nextDouble() * 170;
      final color = clubCategories[random.nextInt(clubCategories.length)].color;
      return (angle, speed, color, 4 + random.nextDouble() * 5);
    });
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final time = t * 2.2;
    const gravity = 420.0;
    final opacity = (1 - t).clamp(0.0, 1.0);
    final paint = Paint();

    for (final (angle, speed, color, pieceSize) in _pieces) {
      final pos = origin +
          Offset(
            math.cos(angle) * speed * time,
            math.sin(angle) * speed * time + 0.5 * gravity * time * time,
          );
      paint.color = color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(speed * time * 0.05);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: pieceSize, height: pieceSize * 0.55),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) => oldDelegate.t != t;
}
