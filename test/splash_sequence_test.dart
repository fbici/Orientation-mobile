import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/features/launch/presentation/launch_pages.dart';

import 'support/launch_logo.dart';

void main() {
  testWidgets('logo animation has a readable hold before opening the next page',
      (tester) async {
    var finished = 0;
    await tester.pumpWidget(
        MaterialApp(home: LaunchSplash(onFinished: () => finished++)));
    await loadSplashLogo(tester);
    // Let the asset decode before measuring the logo's actual visible timeline.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1800));
    expect(finished, 0);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Image && widget.semanticLabel == 'Logo Orientia'),
        findsOneWidget);
    final motion = tester
        .widget<Transform>(find.byKey(const ValueKey('splash-logo-motion')));
    expect(motion.transform.getMaxScaleOnAxis(), closeTo(1, .01));
    expect(
        tester
            .widget<Opacity>(find.byKey(const ValueKey('splash-stage')))
            .opacity,
        1);
    await tester.pump(const Duration(milliseconds: 700));
    expect(finished, 0);
    expect(
        tester
            .widget<Opacity>(find.byKey(const ValueKey('splash-stage')))
            .opacity,
        1);
    await tester.pumpAndSettle();
    expect(finished, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion keeps a static logo before continuing once',
      (tester) async {
    var finished = 0;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: LaunchSplash(onFinished: () => finished++))));
    await loadSplashLogo(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(finished, 0);
    expect(
        tester
            .widget<Transform>(find.byKey(const ValueKey('splash-logo-motion')))
            .transform
            .getMaxScaleOnAxis(),
        1);
    expect(
        tester
            .widget<Opacity>(find.byKey(const ValueKey('splash-stage')))
            .opacity,
        1);
    await tester.pumpAndSettle();
    expect(finished, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leaving the splash does not trigger a late navigation',
      (tester) async {
    var finished = 0;
    await tester.pumpWidget(
        MaterialApp(home: LaunchSplash(onFinished: () => finished++)));
    await loadSplashLogo(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    expect(finished, 0);
    expect(tester.takeException(), isNull);
  });
}
