import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'question.dart';

/// Disk cache for question photos. Images are kept for a year so the quiz
/// works offline once they have been downloaded.
class QuizImageCache {
  static final instance = CacheManager(
    Config('quizImages', stalePeriod: const Duration(days: 365), maxNrOfCacheObjects: 300),
  );

  /// Wikimedia throttles requests without a descriptive User-Agent.
  static const headers = {
    'User-Agent': 'BollywoodPictorialQuiz/1.0 (com.the_lazy_bear_club.bollywood_pictorial_quiz; Flutter)',
  };

  /// Pause between background downloads so image hosts don't rate-limit us.
  static const _gap = Duration(milliseconds: 750);

  /// Downloads every question photo that isn't on the phone yet.
  ///
  /// Each URL is fetched once even if several questions share it. If the host
  /// answers 429 (Too Many Requests), the rest is left for the next launch;
  /// a photo that's still missing then loads when its question is shown.
  static Future<void> downloadAll(List<Question> questions) async {
    final urls = {
      for (final q in questions)
        if (q.imageUrl.isNotEmpty && !q.hasBundledImage) q.imageUrl,
    };
    for (final url in urls) {
      try {
        if (await instance.getFileFromCache(url) != null) continue;
        await instance.downloadFile(url, authHeaders: headers);
        await Future<void>.delayed(_gap);
      } on HttpExceptionWithStatus catch (e) {
        if (e.statusCode == 429) {
          debugPrint('Image host is rate-limiting; will finish caching next launch.');
          return;
        }
        debugPrint('Could not cache $url: $e');
      } catch (e) {
        // Offline or the image moved; it will be retried next launch.
        debugPrint('Could not cache $url: $e');
      }
    }
  }
}
