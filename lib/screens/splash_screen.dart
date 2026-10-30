import 'package:flutter/material.dart';

import '../data/question_repository.dart';
import 'home_screen.dart';

/// How long the splash picture stays up before the home screen.
const _splashDuration = Duration(seconds: 2);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.repository});

  final QuestionRepository repository;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _openHome();
  }

  Future<void> _openHome() async {
    // Decode the home picture while the splash is showing so it appears at once.
    await Future.wait([
      precacheImage(const AssetImage('assets/images/home_bg.png'), context),
      Future<void>.delayed(_splashDuration),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, _, _) => HomeScreen(repository: widget.repository),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5A0E14),
      body: SizedBox.expand(
        child: Image.asset('assets/images/splash_bg.png', fit: BoxFit.cover),
      ),
    );
  }
}
