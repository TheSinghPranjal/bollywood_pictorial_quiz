import 'dart:math';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// Shared colours and widgets for the cinema-styled screens.
const kGold = Color(0xFFFFC93C);
const kMaroon = Color(0xFF5A0E14);
const kCream = Color(0xFFFFF4DC);
const kPlum = Color(0xFF2A0F3D);

/// Big glowing yellow button, like the Play Quiz button.
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.height = 80,
    this.fontSize = 32,
    this.iconAfter = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final bool iconAfter;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    final iconWidget = Icon(icon, size: fontSize * 1.6, color: const Color(0xFFC4161C));
    final text = Text(
      label,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, color: kMaroon),
    );
    return Semantics(
      button: true,
      label: label,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: const Color(0xFFFFF1B8), width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0xAAFFB300), blurRadius: 24),
              BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 6)),
            ],
          ),
          child: Material(
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFE680), Color(0xFFFFC21A), Color(0xFFF29A00)],
                ),
              ),
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  // Shrinks the label on narrow buttons instead of overflowing.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: iconAfter
                          ? [text, const SizedBox(width: 6), iconWidget]
                          : [iconWidget, const SizedBox(width: 6), text],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dark pill with a gold star coin, e.g. "Best 7" or "Score 3".
class StarPill extends StatelessWidget {
  const StarPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
      decoration: BoxDecoration(
        color: const Color(0xCC3A0A10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kGold, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: kGold,
            child: Icon(Icons.star, size: 20, color: Color(0xFFB86E00)),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Full-screen background picture with [child] laid on top.
class CinemaBackground extends StatelessWidget {
  const CinemaBackground({super.key, required this.image, required this.child});

  final String image;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Image.asset(image, fit: BoxFit.cover)),
        child,
      ],
    );
  }
}

/// Big gold-gradient lettering with a dark red outline, like the logo.
class GoldTitleText extends StatelessWidget {
  const GoldTitleText(this.text, {super.key, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, height: 1, letterSpacing: -1);
    return Stack(
      children: [
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize / 7
              ..color = const Color(0xFF7A1A0A),
            shadows: const [Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))],
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3A0), kGold, Color(0xFFF08A00)],
          ).createShader(bounds),
          child: Text(text, style: style.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}

/// A row of five gold stars, biggest in the middle, to crown a sign.
class StarCrown extends StatelessWidget {
  const StarCrown({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [_Star(size: 20), _Star(size: 40), _Star(size: 62), _Star(size: 40), _Star(size: 20)],
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

/// Sign framed by a red border of glowing light bulbs, like a cinema marquee.
class MarqueePainter extends CustomPainter {
  const MarqueePainter({this.inner = const [Color(0xFFFFFAEE), Color(0xFFF7E3BC)], this.radius = 30, this.frame = 16});

  /// Top and bottom colours of the sign inside the bulb frame.
  final List<Color> inner;
  final double radius;
  final double frame;
  static const _bulbGap = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
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
    final sign = outer.deflate(frame);
    canvas.drawRRect(
      sign,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: inner,
        ).createShader(sign.outerRect),
    );
    canvas.drawRRect(
      sign,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = kGold,
    );

    // Bulbs evenly spaced around the middle of the red frame.
    final track = Path()..addRRect(outer.deflate(frame / 2));
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
  bool shouldRepaint(MarqueePainter oldDelegate) =>
      oldDelegate.inner != inner || oldDelegate.radius != radius || oldDelegate.frame != frame;
}
