import 'dart:math';

import 'package:flutter/material.dart';

import '../data/question.dart';
import '../data/question_repository.dart';
import '../sketch/sketch_painter.dart';
import '../sketch/sketch_picture.dart';
import '../widgets/cinema.dart';
import 'result_screen.dart';

const _correctFill = Color(0xFF66BB6A);
const _wrongFill = Color(0xFFE57373);

/// Content is capped to phone width so it doesn't stretch on iPad.
const _maxContentWidth = 560.0;

/// Below this height the screen scrolls instead of squeezing the picture away.
const _minContentHeight = 600.0;

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.questions,
    required this.repository,
    this.roundSize = QuestionRepository.defaultRoundSize,
    this.random,
  });

  final List<Question> questions;
  final QuestionRepository repository;

  /// Questions per round; each round picks a fresh random set.
  final int roundSize;
  final Random? random;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final Random _random = widget.random ?? Random();
  late final List<Question> _order = ([...widget.questions]..shuffle(_random)).take(widget.roundSize).toList();
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          score: _score,
          total: _order.length,
          questions: widget.questions,
          roundSize: widget.roundSize,
          repository: widget.repository,
        ),
      ),
    );
  }

  Color? _fillFor(String option) {
    if (_picked == null) return null;
    if (option == _current.correctOption) return _correctFill;
    if (option == _picked) return _wrongFill;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPlum,
      body: CinemaBackground(
        image: 'assets/images/quiz_bg.png',
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: _content()),
                ),
              );
              // Everything fits on one screen; only very short windows
              // (e.g. landscape phones) fall back to scrolling.
              if (constraints.maxHeight >= _minContentHeight) return content;
              return SingleChildScrollView(
                child: SizedBox(height: _minContentHeight, child: content),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _content() {
    final q = _current;
    final answered = _picked != null;
    final correct = _picked == q.correctOption;
    return Column(
      children: [
        Row(
          children: [
            const _BackButton(),
            Expanded(
              child: Center(child: _CounterPill(text: '${_index + 1} / ${_order.length}')),
            ),
            StarPill(text: 'Score $_score'),
          ],
        ),
        const SizedBox(height: 10),
        // Below the pinned top bar, the question is one block centred in the
        // remaining space: it fills a phone and sits neatly in the middle of
        // an iPad.
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _KindBanner(kind: q.kind),
              ),
              const SizedBox(height: 8),
              // The picture shrinks to whatever height is left, so the screen never scrolls.
              Flexible(
                child: AspectRatio(
                  aspectRatio: SketchPainter.boardSize.aspectRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: kPaper,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kGold, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          SketchPicture(key: ValueKey(q.id), question: q),
                          if (q.imageUrl.isNotEmpty && q.credit.isNotEmpty)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              left: 40,
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  color: Colors.black54,
                                  child: Text(
                                    'Photo: ${q.credit}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 9, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // After answering, the same card shows the verdict and fun fact.
              _CreamCard(
                child: answered
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            correct ? 'Sahi jawab!' : 'Oops! It was "${q.correctOption}".',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: correct ? const Color(0xFF1B7A35) : const Color(0xFFB3261E),
                            ),
                          ),
                          if (q.fact.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              q.fact,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13.5, color: kPlum, height: 1.25),
                            ),
                          ],
                        ],
                      )
                    : Text(
                        q.text,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kPlum, height: 1.25),
                      ),
              ),
              const SizedBox(height: 10),
              for (final (i, option) in _options.indexed) ...[
                _OptionTile(
                  key: ValueKey('option_$i'),
                  letter: String.fromCharCode(65 + i),
                  label: option,
                  fill: _fillFor(option),
                  onTap: answered ? null : () => _pick(option),
                  trailing: answered && option == q.correctOption
                      ? Icons.check
                      : answered && option == _picked
                      ? Icons.close
                      : null,
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),
              FractionallySizedBox(
                widthFactor: 0.6,
                child: GoldButton(
                  label: _index + 1 < _order.length ? 'Next' : 'See result',
                  icon: Icons.chevron_right_rounded,
                  iconAfter: true,
                  height: 50,
                  fontSize: 20,
                  onTap: answered ? _next : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCream,
      shape: const CircleBorder(side: BorderSide(color: Color(0xFFE0B860), width: 2)),
      elevation: 6,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kPlum, size: 20),
        visualDensity: VisualDensity.compact,
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF6D8), Color(0xFFF7DC98)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5304A), width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPlum),
      ),
    );
  }
}

/// Red marquee banner with a clapperboard, naming the question type.
class _KindBanner extends StatelessWidget {
  const _KindBanner({required this.kind});

  final QuestionKind kind;

  static const _icons = {
    QuestionKind.movie: Icons.movie_creation,
    QuestionKind.actor: Icons.person,
    QuestionKind.actress: Icons.face_3,
    QuestionKind.issue: Icons.campaign,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFB0102A), Color(0xFF6E0A1A)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF4D4D), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x88FF3030), blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
            child: Icon(_icons[kind], color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: FittedBox(
              child: Text(
                kind.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: kGold,
                  shadows: [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 3)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreamCard extends StatelessWidget {
  const _CreamCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8E6), Color(0xFFF5E2B8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0B860), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}

/// One answer choice: a cream pill with a lettered badge (A–D).
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.letter,
    required this.label,
    required this.onTap,
    this.fill,
    this.trailing,
  });

  final String letter;
  final String label;
  final VoidCallback? onTap;
  final Color? fill;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFE0B860), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Material(
        color: fill ?? kCream,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4B1C8C), Color(0xFF1E0838)],
                    ),
                    border: Border.all(color: const Color(0xFFE0A030), width: 2.5),
                  ),
                  child: Text(
                    letter,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kPlum),
                  ),
                ),
                if (trailing != null) Icon(trailing, color: kPlum, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
