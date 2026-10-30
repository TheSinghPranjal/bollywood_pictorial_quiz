import 'dart:math';

import 'package:flutter/material.dart';

import '../data/question.dart';
import '../data/image_cache.dart';
import '../data/question_repository.dart';
import '../widgets/cinema.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final QuestionRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Question>? _questions;
  int _best = 0;
  int _roundSize = QuestionRepository.defaultRoundSize;
  Set<Difficulty> _difficulties = {Difficulty.easy};
  String? _error;

  /// Questions at the difficulty levels picked in Settings.
  List<Question>? get _playable => _questions?.where((q) => _difficulties.contains(q.difficulty)).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final questions = await widget.repository.loadLocal();
      final best = await widget.repository.bestScore();
      final roundSize = await widget.repository.roundSize();
      final difficulties = await widget.repository.difficulties();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _best = best;
        _roundSize = roundSize;
        _difficulties = difficulties;
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
    final all = _playable;
    if (all == null) return;
    final questions = kind == null ? all : all.where((q) => q.kind == kind).toList();
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('No questions at this difficulty yet. Pick another in Settings.')));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(questions: questions, repository: widget.repository, roundSize: _roundSize),
      ),
    );
    final best = await widget.repository.bestScore();
    if (mounted) setState(() => _best = best);
  }

  void _showCategories() {
    final questions = _playable;
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
              Builder(
                builder: (_) {
                  final count = questions.where((q) => q.kind == kind).length;
                  return ListTile(
                    title: Text(kind.label),
                    trailing: Text('${min(_roundSize, count)} of $count'),
                    enabled: count > 0,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _start(kind);
                    },
                  );
                },
              ),
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
        content: Text('Best score: $_best'),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _showSettings() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(repository: widget.repository, questions: _questions ?? const []),
      ),
    );
    if (saved != true) return;
    final roundSize = await widget.repository.roundSize();
    final difficulties = await widget.repository.difficulties();
    if (!mounted) return;
    setState(() {
      _roundSize = roundSize;
      _difficulties = difficulties;
    });
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
      backgroundColor: kMaroon,
      body: CinemaBackground(
        image: 'assets/images/home_bg.png',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _RoundIconButton(icon: Icons.settings, label: 'Settings', onTap: _showSettings),
                    const Spacer(),
                    StarPill(text: 'Best $_best'),
                  ],
                ),
                const Spacer(flex: 2),
                const _Title(),
                const Spacer(flex: 5),
                if (status != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                GoldButton(
                  label: 'Play Quiz',
                  icon: Icons.play_arrow_rounded,
                  onTap: _questions == null ? null : _start,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _MenuTile(
                        label: 'Rewards',
                        icon: Icons.emoji_events,
                        colors: const [Color(0xFF9C3FD6), Color(0xFF4A1580)],
                        onTap: _showRewards,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MenuTile(
                        label: 'Categories',
                        icon: Icons.movie_filter,
                        colors: const [Color(0xFF2F7BF0), Color(0xFF0D3A9A)],
                        onTap: _showCategories,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MenuTile(
                        label: 'Leaderboard',
                        icon: Icons.leaderboard,
                        colors: const [Color(0xFF2FB463), Color(0xFF0E6B33)],
                        onTap: () => _comingSoon('Leaderboard'),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Bollywood" in outlined gold letters over a red "Pictorial Quiz" banner.
class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const FittedBox(child: GoldTitleText('Bollywood', fontSize: 54)),
        Transform.translate(
          offset: const Offset(0, -4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE5304A), Color(0xFF9E0F2A)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kGold, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: const Text(
              'Pictorial Quiz',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(color: Color(0xFF6B0A1C), offset: Offset(0, 2))],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.label, required this.icon, required this.colors, required this.onTap});

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return AspectRatio(
      aspectRatio: 1.1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: Colors.white54, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Material(
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
            ),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 40,
                      color: kGold,
                      shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC3A0A10),
      shape: const CircleBorder(side: BorderSide(color: kGold, width: 2)),
      child: IconButton(
        icon: Icon(icon, color: kGold),
        tooltip: label,
        onPressed: onTap,
      ),
    );
  }
}
