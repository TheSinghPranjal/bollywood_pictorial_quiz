import 'package:flutter/material.dart';

import '../data/question_repository.dart';
import '../widgets/cinema.dart';
import 'home_screen.dart';

/// How long the splash picture stays up before the home screen.
const _splashDuration = Duration(seconds: 2);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.repository});

  final QuestionRepository repository;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this, duration: _splashDuration);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _openHome();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _openHome() async {
    // Decode the home picture while the bar fills so it appears at once.
    try {
      await Future.wait([
        precacheImage(const AssetImage('assets/images/home_bg.png'), context),
        _progress.forward().orCancel,
      ]);
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => HomeScreen(repository: widget.repository),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMaroon,
      body: CinemaBackground(
        image: 'assets/images/splash_bg.png',
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Pin the bar and byline to the bottom, and scroll only if a
              // small screen or a large text scale cannot fit both.
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: AnimatedBuilder(
                                animation: _progress,
                                builder: (_, _) => _LoadingBar(value: _progress.value),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _StudioByline(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// "by The Lazy Bear Club" credit, kept readable over the poster.
class _StudioByline extends StatelessWidget {
  const _StudioByline();

  static const _nameStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.1,
    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'by The Lazy Bear Club',
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xCC2A0610),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kGold, width: 1.5),
            ),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'by',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: kGold,
                      height: 1,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        child: Image(
                          image: AssetImage('assets/branding/lazy_bear_club.png'),
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('The Lazy Bear Club', style: _nameStyle),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gold bar that fills from left to right, with the percentage above it.
class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Loading... ${(value * 100).round()}%',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black, blurRadius: 6)],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 18,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xCC2A0610),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: kGold, width: 2),
            boxShadow: const [BoxShadow(color: Color(0x88FFB300), blurRadius: 14)],
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFF3A0), kGold, Color(0xFFF08A00)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
