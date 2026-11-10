import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orientia/app.dart';
import 'package:orientia/features/launch/presentation/launch_pages.dart';
import 'support/fake_transport.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
      'first launch shows the logo then the illustrated introduction before login',
      (tester) async {
    final api = clientFor((r, s) => jsonResponse([]));
    await tester.pumpWidget(OrientiaApp(apiClient: api));
    expect(find.byType(LaunchSplash), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(
        find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage)
                .assetName
                .endsWith('welcome_reference.png')),
        findsOneWidget);
    await tester.ensureVisible(find.text('Commencer'));
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
        (await SharedPreferences.getInstance())
            .getBool('orientia_intro_seen_v1'),
        isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
      'a completed introduction is skipped while the launch animation remains',
      (tester) async {
    SharedPreferences.setMockInitialValues({'orientia_intro_seen_v1': true});
    final api = clientFor((r, s) => jsonResponse([]));
    await tester.pumpWidget(OrientiaApp(apiClient: api));
    expect(find.byType(LaunchSplash), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(WelcomePage), findsNothing);
    expect(find.text('Connexion'), findsOneWidget);
    await tester.ensureVisible(find.text('Découvrir Orientia'));
    await tester.tap(find.text('Découvrir Orientia'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomePage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets('introduction scrolls on a small screen with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = clientFor((r, s) => jsonResponse([]));
    await tester.pumpWidget(OrientiaApp(apiClient: api));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Commencer'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
