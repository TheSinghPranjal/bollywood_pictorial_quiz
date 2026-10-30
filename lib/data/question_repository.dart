import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'question.dart';

/// Loads questions from the phone first (bundled JSON + anything downloaded
/// earlier), and can pull more from the internet in the background.
class QuestionRepository {
  QuestionRepository({http.Client? client}) : _client = client ?? http.Client();

  static const _assetPath = 'assets/data/questions.json';
  static const _downloadedKey = 'downloaded_questions_json';
  static const _bestScoreKey = 'best_score';

  final http.Client _client;

  Future<List<Question>> loadLocal() async {
    final bundled = QuestionBank.fromJson(
      jsonDecode(await rootBundle.loadString(_assetPath)) as Map<String, dynamic>,
    );
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_downloadedKey);
    if (saved == null) return bundled.questions;
    try {
      final downloaded = QuestionBank.fromJson(jsonDecode(saved) as Map<String, dynamic>);
      return _merge(bundled.questions, downloaded.questions);
    } catch (e) {
      debugPrint('Ignoring corrupt downloaded questions: $e');
      await prefs.remove(_downloadedKey);
      return bundled.questions;
    }
  }

  /// Downloads [AppConfig.remoteQuestionsUrl] and stores it locally.
  /// Returns the merged list, or null when nothing new was fetched.
  Future<List<Question>?> refreshFromInternet() async {
    const url = AppConfig.remoteQuestionsUrl;
    if (url.isEmpty) return null;
    try {
      final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = response.body;
      // Validate before saving so a bad file never replaces good data.
      QuestionBank.fromJson(jsonDecode(body) as Map<String, dynamic>);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_downloadedKey, body);
      return loadLocal();
    } catch (e) {
      debugPrint('Could not refresh questions: $e');
      return null;
    }
  }

  Future<int> bestScore() async =>
      (await SharedPreferences.getInstance()).getInt(_bestScoreKey) ?? 0;

  Future<void> saveScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    if (score > (prefs.getInt(_bestScoreKey) ?? 0)) {
      await prefs.setInt(_bestScoreKey, score);
    }
  }

  /// Downloaded questions replace bundled ones with the same id.
  static List<Question> _merge(List<Question> base, List<Question> extra) {
    final byId = {for (final q in base) q.id: q};
    for (final q in extra) {
      byId[q.id] = q;
    }
    return byId.values.toList();
  }
}
