import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/features/launch/presentation/launch_pages.dart';

Future<void> showWelcome(WidgetTester tester,
    {bool disableAnimations = false,
    bool accessibleNavigation = false,
    VoidCallback? onContinue}) async {
  await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
          data: MediaQueryData(
              disableAnimations: disableAnimations,
              accessibleNavigation: accessibleNavigation),
          child: WelcomePage(onContinue: onContinue ?? () {}))));
  await tester.pumpAndSettle();
}

int currentSlide(WidgetTester tester) => tester
    .widget<PageView>(find.byKey(const ValueKey('welcome-pages')))
    .controller!
    .page!
    .round();

Future<void> waitForSlide(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 7));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('welcome rotates through all three illustrated slides and loops',
      (tester) async {
    await showWelcome(tester);
    expect(currentSlide(tester), 0);
    await tester.pump(const Duration(seconds: 5));
    expect(currentSlide(tester), 0);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(currentSlide(tester), 1);
    expect(find.text('Un parcours qui\nvous ressemble,'), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage)
                .assetName
                .endsWith('welcome_orientation.png')),
        findsOneWidget);
    await waitForSlide(tester);
    expect(currentSlide(tester), 2);
    expect(find.text('Des opportunités\npour aller'), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage)
                .assetName
                .endsWith('welcome_scholarships.png')),
        findsOneWidget);
    await waitForSlide(tester);
    expect(currentSlide(tester), 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('welcome supports swipe, navigation dots, skip and continue',
      (tester) async {
    var continued = 0;
    await showWelcome(tester, onContinue: () => continued++);
    await tester.drag(
        find.byKey(const ValueKey('welcome-pages')), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(currentSlide(tester), 1);
    await tester.tap(find.byKey(const ValueKey('welcome-dot-2')));
    await tester.pumpAndSettle();
    expect(currentSlide(tester), 2);
    await tester.tap(find.byKey(const ValueKey('welcome-dot-0')));
    await tester.pumpAndSettle();
    expect(currentSlide(tester), 0);
    await tester.tap(find.text('Passer'));
    expect(continued, 1);
    await tester.tap(find.text('Commencer'));
    expect(continued, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'welcome pauses rotation explicitly and while the app is inactive',
      (tester) async {
    await showWelcome(tester);
    await tester.tap(find.byKey(const ValueKey('welcome-pause')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Reprendre le défilement'), findsOneWidget);
    await tester.pump(const Duration(seconds: 20));
    expect(currentSlide(tester), 0);
    await tester.tap(find.byKey(const ValueKey('welcome-pause')));
    await tester.pumpAndSettle();
    await waitForSlide(tester);
    expect(currentSlide(tester), 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 20));
    expect(currentSlide(tester), 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await waitForSlide(tester);
    expect(currentSlide(tester), 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final accessibility in ['reduced motion', 'accessible navigation']) {
    testWidgets('welcome keeps manual navigation with $accessibility',
        (tester) async {
      await showWelcome(tester,
          disableAnimations: accessibility == 'reduced motion',
          accessibleNavigation: accessibility == 'accessible navigation');
      await tester.pump(const Duration(seconds: 30));
      expect(currentSlide(tester), 0);
      final pause = tester
          .widget<IconButton>(find.byKey(const ValueKey('welcome-pause')));
      expect(pause.onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('welcome-dot-2')));
      await tester.pumpAndSettle();
      expect(currentSlide(tester), 2);
      await tester.pump(const Duration(seconds: 30));
      expect(currentSlide(tester), 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
