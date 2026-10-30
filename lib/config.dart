/// App-wide settings.
class AppConfig {
  /// Optional URL of a questions.json file hosted anywhere (GitHub raw, Gist,
  /// Firebase Hosting...). It uses the same format as
  /// assets/data/questions.json. New questions are merged with the bundled
  /// ones and saved on the phone so they keep working offline.
  /// Leave empty to only use the bundled questions.
  static const String remoteQuestionsUrl = '';
}
