import 'package:bollywood_pictorial_quiz/data/question_repository.dart';
import 'package:bollywood_pictorial_quiz/screens/splash_screen.dart';
import 'package:bollywood_pictorial_quiz/widgets/cinema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> showSplash(
    WidgetTester tester, {
    required Size logicalSize,
    ThemeMode themeMode = ThemeMode.light,
    double textScale = 1,
    double bottomInset = 0,
  }) async {
    tester.view
      ..physicalSize = logicalSize * 3
      ..devicePixelRatio = 3
      ..viewPadding = FakeViewPadding(bottom: bottomInset * 3, top: 47 * 3)
      ..padding = FakeViewPadding(bottom: bottomInset * 3, top: 47 * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: SplashScreen(repository: QuestionRepository()),
      ),
    );
    await tester.pump();
  }

  void expectByline(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    expect(find.text('by'), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);
    expect(find.textContaining('Loading'), findsOneWidget);

    final name = tester.widget<Text>(find.text('The Lazy Bear Club'));
    final by = tester.widget<Text>(find.text('by'));
    expect(name.style?.color, Colors.white);
    expect(by.style?.color, kGold);

    final images = tester.widgetList<Image>(find.byType(Image));
    expect(
      images.map((image) => image.image).whereType<AssetImage>().map((image) => image.assetName),
      contains('assets/branding/lazy_bear_club.png'),
    );

    final nameBox = tester.getRect(find.text('The Lazy Bear Club'));
    final byBox = tester.getRect(find.text('by'));
    final loadingBox = tester.getRect(find.textContaining('Loading'));
    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final safeBottom = screenHeight - tester.view.padding.bottom / tester.view.devicePixelRatio;

    expect(byBox.bottom, lessThanOrEqualTo(nameBox.top + 1));
    expect(loadingBox.bottom, lessThan(byBox.top));
    expect(nameBox.bottom, lessThanOrEqualTo(safeBottom));
    expect(safeBottom - nameBox.bottom, lessThan(48));
    expect(nameBox.left, greaterThanOrEqualTo(0));
    expect(nameBox.right, lessThanOrEqualTo(tester.view.physicalSize.width / tester.view.devicePixelRatio));
  }

  testWidgets('splash byline fits a phone in light and dark themes', (tester) async {
    const phone = Size(390, 844);
    await showSplash(tester, logicalSize: phone, bottomInset: 34);
    expectByline(tester);

    await showSplash(tester, logicalSize: phone, themeMode: ThemeMode.dark, bottomInset: 34);
    expectByline(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('splash byline fits a small phone, a tablet, and large text', (tester) async {
    await showSplash(tester, logicalSize: const Size(320, 568), textScale: 1.4, bottomInset: 16);
    expectByline(tester);

    await showSplash(tester, logicalSize: const Size(800, 1280), themeMode: ThemeMode.dark);
    expectByline(tester);

    await showSplash(tester, logicalSize: const Size(844, 390), bottomInset: 20);
    expectByline(tester);

    await showSplash(tester, logicalSize: const Size(360, 640), textScale: 2);
    expectByline(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
