import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'question.dart';

/// Disk cache for question photos. Images are kept for a year so the quiz
/// works offline once they have been downloaded.
class QuizImageCache {
  static final instance = CacheManager(
    Config('quizImages', stalePeriod: const Duration(days: 365), maxNrOfCacheObjects: 300),
  );

  /// Wikimedia rejects requests without a descriptive User-Agent.
  static const headers = {'User-Agent': 'BollywoodPictorialQuiz/1.0 (Flutter app)'};

  /// Downloads every question photo that isn't on the phone yet.
  static Future<void> downloadAll(List<Question> questions) async {
    for (final q in questions) {
      if (q.imageUrl.isEmpty) continue;
      try {
        if (await instance.getFileFromCache(q.imageUrl) != null) continue;
        await instance.downloadFile(q.imageUrl, authHeaders: headers);
      } catch (e) {
        // Offline or the image moved; it will be retried next launch.
        debugPrint('Could not cache ${q.imageUrl}: $e');
      }
    }
  }
}
