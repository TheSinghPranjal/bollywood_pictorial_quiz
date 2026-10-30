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
  static const _roundSizeKey = 'round_size';
  static const _difficultiesKey = 'difficulties';
  static const _soundEffectsKey = 'sound_effects';
  static const _musicKey = 'background_music';

  /// Questions per round the player can pick in Settings.
  static const roundSizes = [10, 20, 30];
  static const defaultRoundSize = 10;

  final http.Client _client;

  Future<List<Question>> loadLocal() async {
    final bundled = QuestionBank.fromJson(jsonDecode(await rootBundle.loadString(_assetPath)) as Map<String, dynamic>);
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

  Future<int> bestScore() async => (await SharedPreferences.getInstance()).getInt(_bestScoreKey) ?? 0;

  Future<int> roundSize() async {
    final saved = (await SharedPreferences.getInstance()).getInt(_roundSizeKey);
    return roundSizes.contains(saved) ? saved! : defaultRoundSize;
  }

  Future<void> saveRoundSize(int size) async => (await SharedPreferences.getInstance()).setInt(_roundSizeKey, size);

  /// Difficulty levels to play; only easy until the player changes it.
  Future<Set<Difficulty>> difficulties() async {
    final saved = (await SharedPreferences.getInstance()).getStringList(_difficultiesKey) ?? const [];
    final levels = Difficulty.values.where((d) => saved.contains(d.name)).toSet();
    return levels.isEmpty ? {Difficulty.easy} : levels;
  }

  Future<void> saveDifficulties(Set<Difficulty> levels) async =>
      (await SharedPreferences.getInstance()).setStringList(_difficultiesKey, [for (final d in levels) d.name]);

  Future<bool> soundEffects() async => (await SharedPreferences.getInstance()).getBool(_soundEffectsKey) ?? true;

  Future<void> saveSoundEffects(bool on) async => (await SharedPreferences.getInstance()).setBool(_soundEffectsKey, on);

  Future<bool> backgroundMusic() async => (await SharedPreferences.getInstance()).getBool(_musicKey) ?? true;

  Future<void> saveBackgroundMusic(bool on) async => (await SharedPreferences.getInstance()).setBool(_musicKey, on);

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
