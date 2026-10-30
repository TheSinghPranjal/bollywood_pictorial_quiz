import 'dart:math';

import 'package:flutter/material.dart';

import 'rough.dart';

const kInk = Color(0xFF2B2B2B);
const kPaper = Color(0xFFFBF7EE);

/// Paints a question's vector sketch from its JSON elements.
///
/// Elements are drawn on a 320 x 220 board, scaled to fit. Supported types:
///  * `l`     polyline        p: [x1, y1, x2, y2, ...]   w: stroke width
///  * `pg`    filled shape    p: [x1, y1, ...]           f: fill colour
///  * `r`     rectangle       p: [x, y, w, h]
///  * `c`     circle          p: [x, y, r]
///  * `tx`    handwritten     p: [x, y, size]            s: text
///  * `b`     speech bubble   p: [x, y, w, h, tailX, tailY]  s: text
///  * `grass` field strokes   p: [x1, x2, groundY, height, gap]
///  * `fig`   stick figure    p: [neckX, neckY, scale]
///            a: 8 limb angles in degrees (0 = right, 90 = down):
///               [leftUpperArm, leftForearm, rightUpperArm, rightForearm,
///                leftThigh, leftShin, rightThigh, rightShin]
///            x: extras - mustache, shades, shades_back, cap, hair_long,
///               ponytail, dress, bandolier
/// `c` is the ink colour and `f` the hatching colour, both as #RRGGBB.
class SketchPainter extends CustomPainter {
  SketchPainter(this.elements, {required this.seed});

  static const boardSize = Size(320, 220);

  final List<Map<String, dynamic>> elements;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = min(size.width / boardSize.width, size.height / boardSize.height);
    canvas.save();
    canvas.translate(
      (size.width - boardSize.width * scale) / 2,
      (size.height - boardSize.height * scale) / 2,
    );
    canvas.scale(scale);
    canvas.clipRect(Offset.zero & boardSize);

    // Fresh generator on every paint keeps the wobble identical between frames.
    final rough = Rough(canvas, seed);
    for (final e in elements) {
      try {
        _draw(rough, e);
      } catch (err) {
        debugPrint('Skipping bad sketch element $e: $err');
      }
    }
    canvas.restore();
  }

  void _draw(Rough r, Map<String, dynamic> e) {
    final p = (e['p'] as List? ?? const []).map((v) => (v as num).toDouble()).toList();
    final ink = _color(e['c']) ?? kInk;
    final fill = _color(e['f']);
    final width = (e['w'] as num?)?.toDouble() ?? 2;

    switch (e['t']) {
      case 'l':
        r.polyline(_points(p), ink, width: width);
      case 'pg':
        r.polygon(_points(p), ink, fill: fill, width: width);
      case 'r':
        r.polygon([
          Offset(p[0], p[1]),
          Offset(p[0] + p[2], p[1]),
          Offset(p[0] + p[2], p[1] + p[3]),
          Offset(p[0], p[1] + p[3]),
        ], ink, fill: fill, width: width);
      case 'c':
        r.circle(Offset(p[0], p[1]), p[2], ink, fill: fill, width: width);
      case 'tx':
        _text(r.canvas, e['s'] as String? ?? '', Offset(p[0], p[1]), p.length > 2 ? p[2] : 13, ink);
      case 'b':
        _bubble(r, p, e['s'] as String? ?? '', ink);
      case 'grass':
        _grass(r, p, ink, fill);
      case 'fig':
        _figure(r, p, (e['a'] as List).map((v) => (v as num).toDouble()).toList(),
            List<String>.from(e['x'] as List? ?? const []), ink);
    }
  }

  static List<Offset> _points(List<double> p) =>
      [for (var i = 0; i + 1 < p.length; i += 2) Offset(p[i], p[i + 1])];

  static Color? _color(Object? hex) {
    if (hex is! String || !hex.startsWith('#') || hex.length != 7) return null;
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }

  static Offset _dir(double degrees, double length) {
    final rad = degrees * pi / 180;
    return Offset(cos(rad) * length, sin(rad) * length);
  }

  void _text(Canvas canvas, String text, Offset at, double size, Color color, {double? maxWidth}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      textAlign: maxWidth == null ? TextAlign.left : TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth ?? double.infinity);
    final offset = maxWidth == null ? at : at + Offset((maxWidth - tp.width) / 2, 0);
    tp.paint(canvas, offset);
  }

  void _bubble(Rough r, List<double> p, String text, Color ink) {
    final rect = Rect.fromLTWH(p[0], p[1], p[2], p[3]);
    final tail = Offset(p[4], p[5]);
    // Tail leaves the bubble's bottom edge at the point closest to the speaker.
    final baseX = tail.dx.clamp(rect.left + 14, rect.right - 14).toDouble();
    final tailPts = [Offset(baseX - 8, rect.bottom), tail, Offset(baseX + 8, rect.bottom)];

    r.cover(Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))), Colors.white);
    r.cover(Path()..addPolygon(tailPts, true), Colors.white);
    r.polyline([
      Offset(rect.left + 10, rect.top),
      Offset(rect.right - 10, rect.top),
      Offset(rect.right, rect.top + 10),
      Offset(rect.right, rect.bottom - 8),
      Offset(rect.right - 10, rect.bottom),
      tailPts[2],
      tail,
      tailPts[0],
      Offset(rect.left + 10, rect.bottom),
      Offset(rect.left, rect.bottom - 8),
      Offset(rect.left, rect.top + 10),
      Offset(rect.left + 10, rect.top),
    ], ink, width: 1.8);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    var size = 14.0;
    // Shrink long dialogues until they fit inside the bubble.
    while (size > 8) {
      tp
        ..text = TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w700))
        ..layout(maxWidth: rect.width - 12);
      if (tp.height <= rect.height - 6) break;
      size -= 1;
    }
    _text(r.canvas, text, Offset(rect.left + 6, rect.center.dy - tp.height / 2), size, ink,
        maxWidth: rect.width - 12);
  }

  void _grass(Rough r, List<double> p, Color ink, Color? flower) {
    final x1 = p[0], x2 = p[1], ground = p[2], height = p[3], gap = p[4];
    var i = 0;
    for (var x = x1; x <= x2; x += gap, i++) {
      final h = height * (0.6 + 0.4 * ((i * 37) % 10) / 10);
      final top = Offset(x + (i.isEven ? 3 : -3), ground - h);
      r.polyline([Offset(x, ground), top], ink, width: 1.4);
      if (flower != null) r.dot(top, 3, flower);
    }
  }

  void _figure(Rough r, List<double> p, List<double> a, List<String> extras, Color ink) {
    final s = p.length > 2 ? p[2] : 1.0;
    final neck = Offset(p[0], p[1]);
    final head = neck + Offset(0, -16 * s);
    final shoulder = neck + Offset(0, 6 * s);
    final hip = neck + Offset(0, 48 * s);
    final w = 2.4 * s;

    Offset limb(Offset from, double upper, double lower, double len1, double len2, List<Offset> out) {
      final joint = from + _dir(upper, len1 * s);
      final end = joint + _dir(lower, len2 * s);
      out.addAll([from, joint, end]);
      return end;
    }

    final has = extras.toSet();
    if (has.contains('hair_long')) {
      r.polygon([
        head + Offset(-12 * s, -9 * s),
        head + Offset(-5 * s, -15 * s),
        head + Offset(5 * s, -15 * s),
        head + Offset(12 * s, -9 * s),
        head + Offset(15 * s, 10 * s),
        head + Offset(17 * s, 26 * s),
        head + Offset(-17 * s, 26 * s),
        head + Offset(-15 * s, 10 * s),
      ], ink, fill: const Color(0xFF3E2723), width: 1.5);
    }
    if (has.contains('dress')) {
      r.polygon([
        neck + Offset(-7 * s, 16 * s),
        neck + Offset(7 * s, 16 * s),
        neck + Offset(24 * s, 70 * s),
        neck + Offset(-24 * s, 70 * s),
      ], ink, fill: const Color(0xFFD81B60), width: 1.6);
    }

    r.polyline([neck, hip], ink, width: w);
    for (final arm in [
      [a[0], a[1]],
      [a[2], a[3]],
    ]) {
      final pts = <Offset>[];
      limb(shoulder, arm[0], arm[1], 26, 24, pts);
      r.polyline(pts, ink, width: w);
    }
    for (final leg in [
      [a[4], a[5]],
      [a[6], a[7]],
    ]) {
      final pts = <Offset>[];
      final foot = limb(hip, leg[0], leg[1], 30, 30, pts);
      r.polyline(pts, ink, width: w);
      r.polyline([foot, foot + Offset(cos(leg[1] * pi / 180) >= 0 ? 6 * s : -6 * s, 0)], ink, width: w);
    }

    if (has.contains('bandolier')) {
      r.polyline([shoulder + Offset(-10 * s, 0), hip + Offset(8 * s, 0)], const Color(0xFF8D6E63), width: 4 * s);
      for (var t = 0.15; t < 0.9; t += 0.15) {
        r.dot(Offset.lerp(shoulder + Offset(-10 * s, 0), hip + Offset(8 * s, 0), t)!, 1.6 * s,
            const Color(0xFFFFC107));
      }
    }
    if (has.contains('shades_back')) {
      r.polygon([
        neck + Offset(-9 * s, 2 * s),
        neck + Offset(9 * s, 2 * s),
        neck + Offset(7 * s, 7 * s),
        neck + Offset(-7 * s, 7 * s),
      ], ink, fill: kInk, width: 1.2);
    }

    // Head on top of everything else on the body.
    r.cover(Path()..addOval(Rect.fromCircle(center: head, radius: 13 * s)), kPaper);
    r.circle(head, 13 * s, ink, width: w);
    if (has.contains('shades')) {
      r.polyline([head + Offset(-9 * s, -3 * s), head + Offset(9 * s, -3 * s)], ink, width: 1.5);
      r.dot(head + Offset(-4.5 * s, -1.5 * s), 3.2 * s, kInk);
      r.dot(head + Offset(4.5 * s, -1.5 * s), 3.2 * s, kInk);
    } else {
      r.dot(head + Offset(-4.5 * s, -2 * s), 1.6 * s, ink);
      r.dot(head + Offset(4.5 * s, -2 * s), 1.6 * s, ink);
    }
    if (has.contains('mustache')) {
      r.polyline([
        head + Offset(-7 * s, 6 * s),
        head + Offset(-2 * s, 3.5 * s),
        head + Offset(0, 4.5 * s),
        head + Offset(2 * s, 3.5 * s),
        head + Offset(7 * s, 6 * s),
      ], ink, width: 2.2 * s);
    } else {
      r.polyline([head + Offset(-4 * s, 5 * s), head + Offset(0, 7 * s), head + Offset(4 * s, 5 * s)], ink,
          width: 1.4 * s);
    }
    if (has.contains('cap')) {
      r.polygon([
        head + Offset(-13 * s, -8 * s),
        head + Offset(-10 * s, -18 * s),
        head + Offset(10 * s, -18 * s),
        head + Offset(13 * s, -8 * s),
      ], ink, fill: const Color(0xFF8D6E63), width: 1.6);
      r.polyline([head + Offset(-16 * s, -8 * s), head + Offset(16 * s, -8 * s)], ink, width: 2.4);
    }
    if (has.contains('ponytail')) {
      r.polyline([
        head + Offset(11 * s, -8 * s),
        head + Offset(20 * s, -4 * s),
        head + Offset(22 * s, 8 * s),
      ], const Color(0xFF3E2723), width: 4 * s);
    }
  }

  @override
  bool shouldRepaint(SketchPainter old) => old.elements != elements || old.seed != seed;
}
