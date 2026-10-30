import 'package:flutter/material.dart';

import 'data/question_repository.dart';
import 'screens/splash_screen.dart';
import 'sketch/sketch_painter.dart';

void main() {
  runApp(BollywoodQuizApp(repository: QuestionRepository()));
}

class BollywoodQuizApp extends StatelessWidget {
  const BollywoodQuizApp({super.key, required this.repository});

  final QuestionRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bollywood Pictorial Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF6C343), surface: kPaper),
        scaffoldBackgroundColor: kPaper,
        appBarTheme: const AppBarTheme(
          backgroundColor: kPaper,
          foregroundColor: kInk,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            color: kInk,
          ),
        ),
        textTheme: ThemeData.light().textTheme.apply(bodyColor: kInk, displayColor: kInk),
      ),
      home: SplashScreen(repository: repository),
    );
  }
}
