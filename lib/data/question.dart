/// What the four options of a question refer to.
enum QuestionKind {
  movie('Guess the Movie'),
  actor('Guess the Actor'),
  actress('Guess the Actress'),
  issue('Spot the Issue');

  const QuestionKind(this.label);
  final String label;

  static QuestionKind parse(String? value) =>
      QuestionKind.values.firstWhere((k) => k.name == value, orElse: () => QuestionKind.movie);
}

/// How hard a question is; players pick which levels to play in Settings.
enum Difficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const Difficulty(this.label);
  final String label;

  static Difficulty parse(String? value) =>
      Difficulty.values.firstWhere((d) => d.name == value, orElse: () => Difficulty.easy);
}

/// One quiz question. JSON uses short keys to keep the stored data small:
/// id, k (kind), d (difficulty, default easy), q (question), o (4 options), a (answer index), f (fact),
/// img (optional internet image URL), cr (image credit, needed for
/// Creative Commons photos), s (vector sketch elements).
class Question {
  const Question({
    required this.id,
    required this.kind,
    required this.difficulty,
    required this.text,
    required this.options,
    required this.answer,
    required this.fact,
    required this.imageUrl,
    required this.credit,
    required this.sketch,
  });

  final String id;
  final QuestionKind kind;
  final Difficulty difficulty;
  final String text;
  final List<String> options;
  final int answer;
  final String fact;
  final String imageUrl;
  final String credit;
  final List<Map<String, dynamic>> sketch;

  String get correctOption => options[answer];

  /// `img` can also name a picture bundled with the app, e.g. assets/images/questions/dhol.jpg.
  bool get hasBundledImage => imageUrl.startsWith('assets/');

  factory Question.fromJson(Map<String, dynamic> json) {
    final options = List<String>.from(json['o'] as List);
    final answer = json['a'] as int;
    if (options.length != 4 || answer < 0 || answer >= options.length) {
      throw FormatException('Question ${json['id']} needs 4 options and a valid answer');
    }
    final sketch = (json['s'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final imageUrl = (json['img'] as String? ?? '').trim();
    if (sketch.isEmpty && imageUrl.isEmpty) {
      throw FormatException('Question ${json['id']} needs a picture (s or img)');
    }
    return Question(
      id: json['id'] as String,
      kind: QuestionKind.parse(json['k'] as String?),
      difficulty: Difficulty.parse(json['d'] as String?),
      text: json['q'] as String,
      options: options,
      answer: answer,
      fact: json['f'] as String? ?? '',
      imageUrl: imageUrl,
      credit: json['cr'] as String? ?? '',
      sketch: sketch,
    );
  }
}

/// A versioned set of questions, as stored in questions.json.
class QuestionBank {
  const QuestionBank({required this.version, required this.questions});

  final int version;
  final List<Question> questions;

  factory QuestionBank.fromJson(Map<String, dynamic> json) => QuestionBank(
    version: json['v'] as int? ?? 0,
    questions: (json['q'] as List).map((e) => Question.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
  );
}
