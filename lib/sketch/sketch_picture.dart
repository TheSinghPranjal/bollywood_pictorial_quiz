import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/image_cache.dart';
import '../data/question.dart';
import 'sketch_painter.dart';

/// The reference picture for a question.
///
/// If the question has an internet image (`img`), it is downloaded once and
/// kept on the phone, so it also shows offline afterwards. Otherwise the tiny
/// vector sketch from the JSON is drawn. A question with both falls back to
/// its sketch when the photo can't be loaded.
class SketchPicture extends StatelessWidget {
  const SketchPicture({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final vector = CustomPaint(
      painter: SketchPainter(question.sketch, seed: _stableHash(question.id)),
      child: const SizedBox.expand(),
    );
    if (question.imageUrl.isEmpty) return vector;
    return CachedNetworkImage(
      imageUrl: question.imageUrl,
      cacheManager: QuizImageCache.instance,
      httpHeaders: QuizImageCache.headers,
      fit: BoxFit.cover,
      // Portraits are taller than the picture frame; keep faces in view.
      alignment: const Alignment(0, -0.5),
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, _) => question.sketch.isEmpty
          ? const Center(child: CircularProgressIndicator(color: kInk))
          : vector,
      errorWidget: (_, _, _) => question.sketch.isEmpty ? const _Offline() : vector,
    );
  }

  /// String.hashCode may change between runs; this keeps each sketch's
  /// wobble the same every time the app opens.
  static int _stableHash(String s) =>
      s.codeUnits.fold(17, (h, c) => (h * 31 + c) & 0x7fffffff);
}

class _Offline extends StatelessWidget {
  const _Offline();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, color: kInk, size: 40),
            SizedBox(height: 8),
            Text(
              'Connect to the internet once to download this picture.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kInk),
            ),
          ],
        ),
      ),
    );
  }
}
