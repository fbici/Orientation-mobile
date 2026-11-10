import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/features/auth/presentation/register_page.dart';
import 'package:orientia/features/auth/presentation/auth_widgets.dart';
import 'support/fake_transport.dart';

void main() {
  testWidgets(
      'reference registration sends separate family and given names without auto-login',
      (tester) async {
    Map<String, dynamic>? sent;
    final api = clientFor((r, s) => jsonResponse({}), auth: (r, s) {
      expect(r.path, '/auth/register');
      sent = Map<String, dynamic>.from(r.data as Map);
      return jsonResponse({}, 202);
    });
    await tester.pumpWidget(MaterialApp(
        home: RegisterPage(
            apiClient: api, onRegisterSuccess: () {}, onBackToLogin: () {})));
    await tester.pumpAndSettle();
    for (final field in {
      'lastName': 'Famille',
      'firstName': 'Prénom',
      'email': 'synthetic@example.test',
      'password': 'Only-test-password-42!',
      'confirmation': 'Only-test-password-42!'
    }.entries) {
      await tester.enterText(
          find.byKey(ValueKey('register-${field.key}')), field.value);
    }
    await tester.ensureVisible(find.text('Créer mon compte'));
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();
    expect(sent?['lastName'], 'Famille');
    expect(sent?['firstName'], 'Prénom');
    expect(sent?.containsKey('confirmation'), isFalse);
    expect(api.user, isNull);
    expect(find.text('Aller à la connexion'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('registration and Google button remain usable with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final api = clientFor((r, s) => jsonResponse({}));
    await tester.pumpWidget(MaterialApp(
        home: RegisterPage(
            apiClient: api, onRegisterSuccess: () {}, onBackToLogin: () {})));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Créer mon compte'));
    expect(tester.takeException(), isNull);
    var continuedWithGoogle = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: GoogleAuthButton(
                onPressed: () => continuedWithGoogle = true))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer avec Google'));
    await tester.pumpAndSettle();
    expect(continuedWithGoogle, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
