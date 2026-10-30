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
    await Future.wait([
      precacheImage(const AssetImage('assets/images/home_bg.png'), context),
      _progress.forward().orCancel,
    ]);
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
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 48, 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: AnimatedBuilder(animation: _progress, builder: (_, _) => _LoadingBar(value: _progress.value)),
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
