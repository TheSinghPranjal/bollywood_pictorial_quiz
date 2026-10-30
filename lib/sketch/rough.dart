import 'dart:math';
import 'dart:ui';

/// Hand-drawn style drawing helpers: every stroke is drawn twice with a
/// little wobble so it looks like pencil on paper.
class Rough {
  Rough(this.canvas, int seed) : _rnd = Random(seed);

  final Canvas canvas;
  final Random _rnd;

  double _j(double amount) => (_rnd.nextDouble() * 2 - 1) * amount;

  Paint stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Polyline through [pts], drawn in two wobbly passes.
  void polyline(List<Offset> pts, Color color, {double width = 2}) {
    if (pts.length < 2) return;
    for (var pass = 0; pass < 2; pass++) {
      final paint = stroke(color.withValues(alpha: pass == 0 ? 0.9 : 0.55), pass == 0 ? width : width * 0.7);
      final path = Path()..moveTo(pts.first.dx + _j(1), pts.first.dy + _j(1));
      for (var i = 1; i < pts.length; i++) {
        final a = pts[i - 1];
        final b = pts[i];
        final len = (b - a).distance;
        // A slightly bowed midpoint makes long straight lines feel hand-drawn.
        final mid = Offset.lerp(a, b, 0.5)! + Offset(_j(len * 0.02 + 0.6), _j(len * 0.02 + 0.6));
        path.quadraticBezierTo(mid.dx, mid.dy, b.dx + _j(1), b.dy + _j(1));
      }
      canvas.drawPath(path, paint);
    }
  }

  void circle(Offset c, double r, Color color, {double width = 2, Color? fill}) {
    if (fill != null) {
      hatch(Path()..addOval(Rect.fromCircle(center: c, radius: r)), fill);
    }
    for (var pass = 0; pass < 2; pass++) {
      final start = _rnd.nextDouble() * pi * 2;
      const steps = 28;
      final path = Path();
      for (var i = 0; i <= steps + 2; i++) {
        final t = start + i * (pi * 2 / steps);
        final rr = r + _j(r * 0.05 + 0.4);
        final p = c + Offset(cos(t) * rr, sin(t) * rr);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, stroke(color.withValues(alpha: pass == 0 ? 0.9 : 0.5), width));
    }
  }

  void dot(Offset c, double r, Color color) =>
      canvas.drawCircle(c, r, Paint()..color = color);

  /// Closed shape outlined by hand and filled with pencil hatching.
  void polygon(List<Offset> pts, Color color, {Color? fill, double width = 2}) {
    if (pts.length < 3) return;
    if (fill != null) hatch(Path()..addPolygon(pts, true), fill);
    polyline([...pts, pts.first], color, width: width);
  }

  /// Diagonal pencil hatching clipped to [area].
  void hatch(Path area, Color color, {double gap = 5}) {
    final bounds = area.getBounds();
    canvas.save();
    canvas.clipPath(area);
    canvas.drawRect(bounds, Paint()..color = color.withValues(alpha: 0.18));
    final paint = stroke(color.withValues(alpha: 0.75), 1.2);
    for (var x = bounds.left - bounds.height; x < bounds.right; x += gap) {
      canvas.drawLine(
        Offset(x + _j(1), bounds.bottom + _j(1)),
        Offset(x + bounds.height + _j(1), bounds.top + _j(1)),
        paint,
      );
    }
    canvas.restore();
  }

  /// Solid paper-coloured background so shapes can sit in front of others.
  void cover(Path area, Color paper) => canvas.drawPath(area, Paint()..color = paper);
}
