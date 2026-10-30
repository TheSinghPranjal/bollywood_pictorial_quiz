import 'package:flutter/material.dart';

import '../data/question.dart';
import '../data/question_repository.dart';
import '../sketch/sketch_painter.dart';
import '../widgets/sketch_box.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.questions,
    required this.repository,
  });

  final int score;
  final int total;
  final List<Question> questions;
  final QuestionRepository repository;

  String get _title {
    final ratio = score / total;
    if (ratio == 1) return 'Superstar!';
    if (ratio >= 0.7) return 'Blockbuster!';
    if (ratio >= 0.4) return 'Hit hai!';
    return 'Picture abhi baaki hai...';
  }

  @override
  Widget build(BuildContext context) {
    // Arms up when winning, arms down otherwise.
    final happy = score / total >= 0.5;
    final figure = <Map<String, dynamic>>[
      {'t': 'l', 'p': [0, 200, 320, 200]},
      {
        't': 'fig',
        'p': [160, 92, 1],
        'a': happy ? [220, 250, 320, 290, 105, 95, 75, 85] : [110, 95, 70, 85, 100, 90, 80, 90],
      },
      if (happy) {'t': 'c', 'p': [60, 50, 14], 'c': '#E39B19', 'f': '#F6C343'},
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(_title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
              const SizedBox(height: 8),
              Text('You scored $score out of $total',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: SketchPainter.boardSize.aspectRatio,
                child: CustomPaint(painter: SketchPainter(figure, seed: score)),
              ),
              const Spacer(),
              SketchButton(
                label: 'Play again',
                fill: const Color(0xFFF6C343),
                seed: 5,
                trailing: const Icon(Icons.replay, color: kInk),
                onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => QuizScreen(questions: questions, repository: repository),
                )),
              ),
              const SizedBox(height: 12),
              SketchButton(
                label: 'Home',
                seed: 6,
                trailing: const Icon(Icons.home_outlined, color: kInk),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
