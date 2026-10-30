import 'package:flutter/material.dart';

import '../sketch/rough.dart';
import '../sketch/sketch_painter.dart';

/// A container with a wobbly, hand-drawn border and optional hatched fill.
class SketchBox extends StatelessWidget {
  const SketchBox({
    super.key,
    required this.child,
    this.fill,
    this.ink = kInk,
    this.padding = const EdgeInsets.all(12),
    this.seed = 1,
  });

  final Widget child;
  final Color? fill;
  final Color ink;
  final EdgeInsets padding;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BoxPainter(fill: fill, ink: ink, seed: seed),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _BoxPainter extends CustomPainter {
  _BoxPainter({required this.fill, required this.ink, required this.seed});

  final Color? fill;
  final Color ink;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rough(canvas, seed);
    final rect = (Offset.zero & size).deflate(2);
    if (fill != null) r.hatch(Path()..addRect(rect), fill!, gap: 7);
    r.polygon([rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft], ink, width: 2);
  }

  @override
  bool shouldRepaint(_BoxPainter old) => old.fill != fill || old.ink != ink || old.seed != seed;
}

/// Tappable sketch-style button.
class SketchButton extends StatelessWidget {
  const SketchButton({super.key, required this.label, required this.onTap, this.fill, this.seed = 1, this.trailing});

  final String label;
  final VoidCallback? onTap;
  final Color? fill;
  final int seed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SketchBox(
          fill: fill,
          seed: seed,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
