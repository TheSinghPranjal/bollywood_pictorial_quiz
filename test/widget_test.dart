import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bollywood_pictorial_quiz/data/question.dart';
import 'package:bollywood_pictorial_quiz/data/question_repository.dart';
import 'package:bollywood_pictorial_quiz/screens/quiz_screen.dart';
import 'package:bollywood_pictorial_quiz/screens/settings_screen.dart';
import 'package:bollywood_pictorial_quiz/sketch/sketch_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final bank = QuestionBank.fromJson(
    jsonDecode(File('assets/data/questions.json').readAsStringSync()) as Map<String, dynamic>,
  );

  test('bundled JSON has 545 questions, each with a picture and 4 options', () {
    expect(bank.questions, hasLength(545));
    expect(bank.questions.map((q) => q.id).toSet(), hasLength(545));
    for (final q in bank.questions) {
      expect(q.sketch.isNotEmpty || q.imageUrl.isNotEmpty, isTrue, reason: q.id);
      expect(q.options.toSet(), hasLength(4), reason: q.id);
      if (q.hasBundledImage) {
        expect(File(q.imageUrl).existsSync(), isTrue, reason: q.id);
      } else if (q.imageUrl.isNotEmpty) {
        expect(Uri.parse(q.imageUrl).isScheme('https'), isTrue, reason: q.id);
        expect(q.credit, isNotEmpty, reason: q.id);
      }
    }
    expect(bank.questions.map((q) => q.kind).toSet(), QuestionKind.values.toSet());
  });

  testWidgets('every sketch paints without errors', (tester) async {
    for (final q in bank.questions) {
      await tester.pumpWidget(
        Center(
          child: SizedBox(width: 320, height: 220, child: CustomPaint(painter: SketchPainter(q.sketch, seed: 1))),
        ),
      );
      expect(tester.takeException(), isNull, reason: q.id);
    }
  });

  testWidgets('answering reveals the correct option and scores it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final q = bank.questions.first;
    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(questions: [q], repository: QuestionRepository(), random: Random(1)),
      ),
    );

    expect(find.text(q.text), findsOneWidget);
    await tester.tap(find.text(q.correctOption));
    await tester.pump();

    expect(find.text('Sahi jawab!'), findsOneWidget);
    expect(find.text('Score 1'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  test('round size defaults to 10 and remembers the chosen value', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = QuestionRepository();
    expect(await repository.roundSize(), 10);
    await repository.saveRoundSize(30);
    expect(await repository.roundSize(), 30);
  });

  testWidgets('a round uses the chosen number of questions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(questions: bank.questions, repository: QuestionRepository(), roundSize: 20, random: Random(1)),
      ),
    );
    expect(find.text('1 / 20'), findsOneWidget);
  });

  test('difficulty defaults to easy only and remembers any mix', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = QuestionRepository();
    expect(await repository.difficulties(), {Difficulty.easy});
    await repository.saveDifficulties({Difficulty.medium, Difficulty.hard});
    expect(await repository.difficulties(), {Difficulty.medium, Difficulty.hard});
  });

  test('questions without a difficulty count as easy', () {
    final q = Question.fromJson({
      'id': 'x',
      'q': 'Which film?',
      'o': ['A', 'B', 'C', 'D'],
      'a': 0,
      'img': 'https://example.com/x.jpg',
    });
    expect(q.difficulty, Difficulty.easy);
  });

  testWidgets('settings are stored only when Save is tapped', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view
      ..physicalSize = const Size(1179, 2556)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repository = QuestionRepository();
    // Open Settings from a page underneath, as the home screen does.
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(repository: repository, questions: bank.questions),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    Future<void> open() async {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    await open();
    await tester.tap(find.text('30'));
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(await repository.roundSize(), 10);

    await open();
    await tester.tap(find.text('20'));
    await tester.tap(find.text('Medium'));
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(await repository.roundSize(), 20);
    expect(await repository.difficulties(), {Difficulty.easy, Difficulty.medium});
    expect(await repository.soundEffects(), isFalse);
  });
}
