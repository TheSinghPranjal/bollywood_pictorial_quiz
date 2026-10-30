import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bollywood_pictorial_quiz/data/question.dart';
import 'package:bollywood_pictorial_quiz/data/question_repository.dart';
import 'package:bollywood_pictorial_quiz/screens/quiz_screen.dart';
import 'package:bollywood_pictorial_quiz/sketch/sketch_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final bank = QuestionBank.fromJson(
    jsonDecode(File('assets/data/questions.json').readAsStringSync()) as Map<String, dynamic>,
  );

  test('bundled JSON has 50 questions, each with a picture and 4 options', () {
    expect(bank.questions, hasLength(50));
    expect(bank.questions.map((q) => q.id).toSet(), hasLength(50));
    for (final q in bank.questions) {
      expect(q.sketch.isNotEmpty || q.imageUrl.isNotEmpty, isTrue, reason: q.id);
      expect(q.options.toSet(), hasLength(4), reason: q.id);
      if (q.imageUrl.isNotEmpty) {
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
}
