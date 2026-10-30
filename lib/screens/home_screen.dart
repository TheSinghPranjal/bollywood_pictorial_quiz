import 'dart:math';

import 'package:flutter/material.dart';

import '../data/question.dart';
import '../data/image_cache.dart';
import '../data/question_repository.dart';
import 'quiz_screen.dart';

/// Size in pixels of assets/images/home_bg.png. Tap areas below are measured
/// in the same pixels so they stay on top of the buttons drawn in the image.
const _bgSize = Size(869, 1810);
const _settingsRect = Rect.fromLTRB(40, 30, 132, 120);
const _playRect = Rect.fromLTRB(115, 1065, 755, 1250);
const _rewardsRect = Rect.fromLTRB(68, 1378, 290, 1568);
const _categoriesRect = Rect.fromLTRB(325, 1378, 548, 1568);
const _leaderboardRect = Rect.fromLTRB(582, 1378, 805, 1568);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final QuestionRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Question>? _questions;
  int _best = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final questions = await widget.repository.loadLocal();
      final best = await widget.repository.bestScore();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _best = best;
      });
      // Pull extra questions and save their photos on the phone, without
      // blocking the game.
      final fresh = await widget.repository.refreshFromInternet();
      if (fresh != null && mounted) setState(() => _questions = fresh);
      await QuizImageCache.downloadAll(fresh ?? questions);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load questions: $e');
    }
  }

  Future<void> _start([QuestionKind? kind]) async {
    final all = _questions;
    if (all == null) return;
    final questions = kind == null ? all : all.where((q) => q.kind == kind).toList();
    if (questions.isEmpty) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuizScreen(questions: questions, repository: widget.repository),
    ));
    final best = await widget.repository.bestScore();
    if (mounted) setState(() => _best = best);
  }

  void _showCategories() {
    final questions = _questions;
    if (questions == null) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            for (final kind in QuestionKind.values)
              Builder(builder: (_) {
                final count = questions.where((q) => q.kind == kind).length;
                return ListTile(
                  title: Text(kind.label),
                  trailing: Text('${min(kRoundSize, count)} of $count'),
                  enabled: count > 0,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _start(kind);
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showRewards() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rewards'),
        content: Text('Best score: $_best / $kRoundSize'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final status = _error ?? (_questions == null ? 'Loading questions...' : null);
    return Scaffold(
      backgroundColor: const Color(0xFF5A0E14),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Same maths as BoxFit.cover with centered alignment, so tap areas
          // line up with the picture on any screen shape.
          final screen = constraints.biggest;
          final scale = max(screen.width / _bgSize.width, screen.height / _bgSize.height);
          final offset = Offset(
            (screen.width - _bgSize.width * scale) / 2,
            (screen.height - _bgSize.height * scale) / 2,
          );
          Rect place(Rect r) => Rect.fromLTRB(
            offset.dx + r.left * scale,
            offset.dy + r.top * scale,
            offset.dx + r.right * scale,
            offset.dy + r.bottom * scale,
          );

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset('assets/images/home_bg.png', fit: BoxFit.cover),
              ),
              _Hotspot(rect: place(_settingsRect), label: 'Settings', round: true, onTap: () => _comingSoon('Settings')),
              _Hotspot(rect: place(_playRect), label: 'Play Quiz', onTap: _start),
              _Hotspot(rect: place(_rewardsRect), label: 'Rewards', onTap: _showRewards),
              _Hotspot(rect: place(_categoriesRect), label: 'Categories', onTap: _showCategories),
              _Hotspot(rect: place(_leaderboardRect), label: 'Leaderboard', onTap: () => _comingSoon('Leaderboard')),
              if (status != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Invisible button laid over a button that is part of the background image.
class _Hotspot extends StatelessWidget {
  const _Hotspot({required this.rect, required this.label, required this.onTap, this.round = false});

  final Rect rect;
  final String label;
  final VoidCallback onTap;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final shape = round
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(rect.height / 4));
    return Positioned.fromRect(
      rect: rect,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          type: MaterialType.transparency,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, splashColor: Colors.white24, highlightColor: Colors.white10),
        ),
      ),
    );
  }
}
