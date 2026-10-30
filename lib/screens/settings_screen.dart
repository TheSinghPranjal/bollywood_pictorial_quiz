import 'package:flutter/material.dart';

import '../data/question.dart';
import '../data/question_repository.dart';
import '../widgets/cinema.dart';

const _cardCream = Color(0xFFFFF6E3);
const _sectionCream = Color(0xFFFCEBCB);
const _goldEdge = Color(0xFFE0B860);

/// Full-screen settings. Changes are only stored when the player taps Save;
/// the screen pops with `true` in that case.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.repository, required this.questions});

  final QuestionRepository repository;

  /// Used to warn when the chosen difficulty levels have no questions yet.
  final List<Question> questions;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _roundSize = QuestionRepository.defaultRoundSize;
  Set<Difficulty> _difficulties = {Difficulty.easy};
  bool _soundEffects = true;
  bool _music = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = widget.repository;
    final roundSize = await repo.roundSize();
    final difficulties = await repo.difficulties();
    final sound = await repo.soundEffects();
    final music = await repo.backgroundMusic();
    if (!mounted) return;
    setState(() {
      _roundSize = roundSize;
      _difficulties = difficulties;
      _soundEffects = sound;
      _music = music;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final repo = widget.repository;
    await repo.saveRoundSize(_roundSize);
    await repo.saveDifficulties(_difficulties);
    await repo.saveSoundEffects(_soundEffects);
    await repo.saveBackgroundMusic(_music);
    if (mounted) Navigator.of(context).pop(true);
  }

  void _toggleDifficulty(Difficulty level) {
    final next = {..._difficulties};
    if (!next.remove(level)) next.add(level);
    // At least one level has to stay selected.
    if (next.isNotEmpty) setState(() => _difficulties = next);
  }

  int get _available => widget.questions.where((q) => _difficulties.contains(q.difficulty)).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMaroon,
      body: CinemaBackground(
        image: 'assets/images/home_bg.png',
        child: Container(
          color: Colors.black38,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _loaded ? _panel() : const SizedBox(height: 200),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The cream card starts below the sign so the sign overlaps its top edge.
        Container(
          margin: const EdgeInsets.only(top: 80),
          padding: const EdgeInsets.fromLTRB(16, 88, 16, 18),
          decoration: BoxDecoration(
            color: _cardCream,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: kGold, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Section(
                icon: Icons.quiz_outlined,
                title: 'Questions per round',
                subtitle: 'Choose how many questions you want to play in each round',
                below: _PillChoices<int>(
                  values: QuestionRepository.roundSizes,
                  label: (size) => '$size',
                  isSelected: (size) => size == _roundSize,
                  onTap: (size) => setState(() => _roundSize = size),
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                icon: Icons.bar_chart_rounded,
                title: 'Difficulty',
                subtitle: 'Pick one or more levels',
                below: Column(
                  children: [
                    _PillChoices<Difficulty>(
                      values: Difficulty.values,
                      label: (level) => level.label,
                      isSelected: _difficulties.contains,
                      onTap: _toggleDifficulty,
                    ),
                    if (_available == 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'No questions at this level yet. Add Easy to play.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFB3261E)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                icon: Icons.volume_up_rounded,
                title: 'Sound Effects',
                subtitle: 'Play sounds during the quiz',
                trailing: _GoldSwitch(value: _soundEffects, onChanged: (on) => setState(() => _soundEffects = on)),
              ),
              const SizedBox(height: 12),
              _Section(
                icon: Icons.music_note_rounded,
                title: 'Background Music',
                subtitle: 'Play background music',
                trailing: _GoldSwitch(value: _music, onChanged: (on) => setState(() => _music = on)),
              ),
              const SizedBox(height: 20),
              _SaveButton(onTap: _save),
            ],
          ),
        ),
        const Positioned(left: 0, right: 0, top: 0, child: _Header()),
        Positioned(right: -6, top: 70, child: _CloseButton(onTap: () => Navigator.of(context).pop(false))),
      ],
    );
  }
}

/// Stars, a red bulb-lit "Settings" sign and the tagline beneath it.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StarCrown(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: CustomPaint(
            painter: const MarqueePainter(inner: [Color(0xFFC4162E), Color(0xFF7A0A1E)], radius: 24, frame: 13),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, 16),
              child: Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: GoldTitleText('Settings', fontSize: 44)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Customize your quiz experience',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kPlum),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.subtitle, this.below, this.trailing});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? below;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _sectionCream,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFFFF3D6), Color(0xFFF5DCA8)]),
                  boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Icon(icon, color: kPlum, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPlum),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B5A6E))),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (below != null) ...[const SizedBox(height: 12), below!],
        ],
      ),
    );
  }
}

/// Three joined pill segments; selected ones turn gold with a tick.
class _PillChoices<T> extends StatelessWidget {
  const _PillChoices({required this.values, required this.label, required this.isSelected, required this.onTap});

  final List<T> values;
  final String Function(T) label;
  final bool Function(T) isSelected;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _goldEdge, width: 1.5),
      ),
      child: Row(
        children: [
          for (final (i, value) in values.indexed) ...[
            if (i > 0) const VerticalDivider(width: 1, thickness: 1, color: _goldEdge),
            Expanded(child: _segment(value)),
          ],
        ],
      ),
    );
  }

  Widget _segment(T value) {
    final selected = isSelected(value);
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFE680), Color(0xFFFFC21A)],
                  ),
                  border: Border.all(color: const Color(0xFFE0A030), width: 1.5),
                  boxShadow: const [BoxShadow(color: Color(0x44B86E00), blurRadius: 4, offset: Offset(0, 2))],
                )
              : null,
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[const Icon(Icons.check_rounded, size: 20, color: kPlum), const SizedBox(width: 6)],
                Text(
                  label(value),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kPlum),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldSwitch extends StatelessWidget {
  const _GoldSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: const Color(0xFFFFB300),
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: const Color(0xFFD7C9B0),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(30);
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: kGold, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Material(
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD42A3E), Color(0xFF8E0C22)],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.white, size: 28),
                  Expanded(
                    child: Text(
                      'Save',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFB0102A),
      shape: const CircleBorder(side: BorderSide(color: kGold, width: 3)),
      elevation: 6,
      child: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
        tooltip: 'Close',
        onPressed: onTap,
      ),
    );
  }
}
