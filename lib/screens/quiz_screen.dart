import 'dart:math';

import 'package:flutter/material.dart';

import '../data/question.dart';
import '../data/question_repository.dart';
import '../sketch/sketch_painter.dart';
import '../sketch/sketch_picture.dart';
import '../widgets/sketch_box.dart';
import 'result_screen.dart';

const _correctFill = Color(0xFF66BB6A);
const _wrongFill = Color(0xFFE57373);

/// Questions per round; each round picks a fresh random set.
const kRoundSize = 10;

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.questions, required this.repository, this.random});

  final List<Question> questions;
  final QuestionRepository repository;
  final Random? random;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final Random _random = widget.random ?? Random();
  late final List<Question> _order = ([...widget.questions]..shuffle(_random)).take(kRoundSize).toList();
  late List<String> _options;
  int _index = 0;
  int _score = 0;
  String? _picked;

  Question get _current => _order[_index];

  @override
  void initState() {
    super.initState();
    _shuffleOptions();
  }

  void _shuffleOptions() => _options = [..._current.options]..shuffle(_random);

  void _pick(String option) {
    if (_picked != null) return;
    setState(() {
      _picked = option;
      if (option == _current.correctOption) _score++;
    });
  }

  Future<void> _next() async {
    if (_index + 1 < _order.length) {
      setState(() {
        _index++;
        _picked = null;
        _shuffleOptions();
      });
      return;
    }
    await widget.repository.saveScore(_score);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultScreen(score: _score, total: _order.length, questions: widget.questions,
          repository: widget.repository),
    ));
  }

  Color? _fillFor(String option) {
    if (_picked == null) return null;
    if (option == _current.correctOption) return _correctFill;
    if (option == _picked) return _wrongFill;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final q = _current;
    final answered = _picked != null;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_index + 1} / ${_order.length}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('Score $_score', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            LinearProgressIndicator(
              value: (_index + (answered ? 1 : 0)) / _order.length,
              color: kInk,
              backgroundColor: Colors.black12,
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: SketchBox(
                fill: const Color(0xFFF6C343),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                seed: _index + 11,
                child: Text(q.kind.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            SketchBox(
              padding: const EdgeInsets.all(6),
              seed: _index + 5,
              child: AspectRatio(
                aspectRatio: SketchPainter.boardSize.aspectRatio,
                child: ClipRect(child: SketchPicture(key: ValueKey(q.id), question: q)),
              ),
            ),
            if (q.imageUrl.isNotEmpty && q.credit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Photo: ${q.credit}',
                    textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ),
            const SizedBox(height: 14),
            Text(q.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 14),
            for (final (i, option) in _options.indexed) ...[
              SketchButton(
                key: ValueKey('option_$i'),
                label: option,
                seed: _index * 4 + i,
                fill: _fillFor(option),
                onTap: answered ? null : () => _pick(option),
                trailing: answered && option == q.correctOption
                    ? const Icon(Icons.check, color: kInk)
                    : answered && option == _picked
                        ? const Icon(Icons.close, color: kInk)
                        : null,
              ),
              const SizedBox(height: 10),
            ],
            if (answered) ...[
              const SizedBox(height: 4),
              Text(
                _picked == q.correctOption ? 'Sahi jawab!' : 'Oops! It was "${q.correctOption}".',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic),
              ),
              if (q.fact.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(q.fact, style: const TextStyle(fontSize: 15, color: Colors.black87)),
              ],
              const SizedBox(height: 16),
              SketchButton(
                label: _index + 1 < _order.length ? 'Next question' : 'See result',
                onTap: _next,
                fill: const Color(0xFF90CAF9),
                seed: 99,
                trailing: const Icon(Icons.arrow_forward, color: kInk),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
