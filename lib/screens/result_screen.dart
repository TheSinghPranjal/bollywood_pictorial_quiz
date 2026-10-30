import 'dart:math';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../data/question.dart';
import '../data/question_repository.dart';
import '../widgets/cinema.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.questions,
    required this.repository,
    required this.roundSize,
  });

  final int score;
  final int total;
  final List<Question> questions;
  final QuestionRepository repository;
  final int roundSize;

  String get _title {
    final ratio = score / total;
    if (ratio == 1) return 'Superstar!';
    if (ratio >= 0.7) return 'Blockbuster!';
    if (ratio >= 0.4) return 'Hit hai!';
    return 'Picture abhi baaki hai...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMaroon,
      body: CinemaBackground(
        image: 'assets/images/result_bg.png',
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                // The marquee sits in the sky and the buttons on the carpet,
                // leaving the cheering kid in the picture uncovered.
                child: Column(
                  children: [
                    _ScoreMarquee(title: _title, score: score, total: total),
                    const Spacer(),
                    _WideButton(
                      label: 'Play again',
                      icon: Icons.replay_rounded,
                      colors: const [Color(0xFFFFE680), Color(0xFFFFC21A)],
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              QuizScreen(questions: questions, repository: repository, roundSize: roundSize),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _WideButton(
                      label: 'Home',
                      icon: Icons.home_outlined,
                      colors: const [Color(0xFFFFFAEE), Color(0xFFF7E6C4)],
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cream sign framed by a red border of light bulbs, with stars on top.
class _ScoreMarquee extends StatelessWidget {
  const _ScoreMarquee({required this.title, required this.score, required this.total});

  final String title;
  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 34),
          child: CustomPaint(
            painter: _MarqueePainter(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(fit: BoxFit.scaleDown, child: GoldTitleText(title, fontSize: 52)),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kPlum),
                        children: [
                          const TextSpan(text: 'You scored '),
                          TextSpan(
                            text: '$score',
                            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFFB0102A)),
                          ),
                          TextSpan(text: ' out of $total'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [_Star(size: 20), _Star(size: 40), _Star(size: 62), _Star(size: 40), _Star(size: 20)],
        ),
      ],
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star_rounded,
      size: size,
      color: kGold,
      shadows: const [
        Shadow(color: Color(0xFFB86E00), offset: Offset(0, 2)),
        Shadow(color: Colors.black45, blurRadius: 8),
      ],
    );
  }
}

class _MarqueePainter extends CustomPainter {
  static const _frame = 16.0;
  static const _bulbGap = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(30));
    canvas.drawShadow(Path()..addRRect(outer), Colors.black, 10, false);
    canvas.drawRRect(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE5304A), Color(0xFF8E0C22)],
        ).createShader(Offset.zero & size),
    );
    final inner = outer.deflate(_frame);
    canvas.drawRRect(
      inner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFAEE), Color(0xFFF7E3BC)],
        ).createShader(inner.outerRect),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = kGold,
    );

    // Bulbs evenly spaced around the middle of the red frame.
    final track = Path()..addRRect(outer.deflate(_frame / 2));
    final glow = Paint()
      ..color = const Color(0x99FFD54F)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final bulb = Paint()..color = const Color(0xFFFFF3C4);
    for (final PathMetric metric in track.computeMetrics()) {
      final count = max(1, (metric.length / _bulbGap).round());
      for (var i = 0; i < count; i++) {
        final pos = metric.getTangentForOffset(metric.length * i / count)!.position;
        canvas.drawCircle(pos, 5, glow);
        canvas.drawCircle(pos, 3.2, bulb);
      }
    }
  }

  @override
  bool shouldRepaint(_MarqueePainter oldDelegate) => false;
}

/// Full-width rounded button: icon on the left, label centred, chevron right.
class _WideButton extends StatelessWidget {
  const _WideButton({required this.label, required this.icon, required this.colors, required this.onTap});

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(30);
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFE0A030), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Material(
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Icon(icon, size: 30, color: kPlum),
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: kPlum),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 30, color: kPlum),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
