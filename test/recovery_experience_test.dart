import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/features/auth/presentation/recovery_page.dart';
import 'support/fake_transport.dart';

void main() {
  testWidgets(
      'forgot password validates email and reports a request without claiming delivery',
      (tester) async {
    final calls = <String>[];
    final api = clientFor((r, s) => jsonResponse({}), auth: (r, s) {
      calls.add(r.path);
      expect(r.data, {'email': 'synthetic@example.test'});
      return jsonResponse({});
    });
    await tester.pumpWidget(MaterialApp(home: RecoveryPage(apiClient: api)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Envoyer le lien'));
    await tester.tap(find.text('Envoyer le lien'));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    expect(find.text('Adresse email valide requise.'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('recovery-email')), 'synthetic@example.test');
    await tester.tap(find.text('Envoyer le lien'));
    await tester.pumpAndSettle();
    expect(calls, ['/auth/forgot-password']);
    expect(find.textContaining('Si votre compte est éligible'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets(
      'reset extracts the actual email token and requires matching passwords',
      (tester) async {
    Map<String, dynamic>? sent;
    final api = clientFor((r, s) => jsonResponse({}), auth: (r, s) {
      expect(r.path, '/auth/reset-password');
      sent = Map<String, dynamic>.from(r.data as Map);
      return jsonResponse({});
    });
    await tester.pumpWidget(MaterialApp(home: RecoveryPage(apiClient: api)));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.text('J’ai déjà un lien de réinitialisation'));
    await tester.tap(find.text('J’ai déjà un lien de réinitialisation'));
    await tester.pumpAndSettle();
    final token = 'a' * 43;
    await tester.enterText(find.byKey(const ValueKey('recovery-token')),
        'https://orientation-backend-d0ys.onrender.com/auth/reset-password?token=$token');
    await tester.enterText(find.byKey(const ValueKey('recovery-password')),
        'Only-test-password-42!');
    await tester.enterText(
        find.byKey(const ValueKey('recovery-confirmation')), 'different-value');
    await tester.ensureVisible(find.text('Enregistrer le mot de passe'));
    await tester.tap(find.text('Enregistrer le mot de passe'));
    await tester.pumpAndSettle();
    expect(sent, isNull);
    expect(find.text('Les mots de passe diffèrent.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('recovery-confirmation')),
        'Only-test-password-42!');
    await tester.ensureVisible(find.text('Enregistrer le mot de passe'));
    await tester.tap(find.text('Enregistrer le mot de passe'));
    await tester.pumpAndSettle();
    expect(sent, {'token': token, 'newPassword': 'Only-test-password-42!'});
    expect(api.user, isNull);
    expect(find.textContaining('a été modifié'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('expired verification is explained without opening a session',
      (tester) async {
    final api = clientFor((r, s) => jsonResponse({}), auth: (r, s) {
      expect(r.path, '/auth/verify');
      return jsonResponse({'message': 'Invalid or expired account token'}, 400);
    });
    await tester.pumpWidget(MaterialApp(home: RecoveryPage(apiClient: api)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Vérifier mon adresse e-mail'));
    await tester.tap(find.text('Vérifier mon adresse e-mail'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('recovery-token')), 'a' * 43);
    await tester.ensureVisible(find.text('Vérifier mon e-mail').last);
    await tester.tap(find.text('Vérifier mon e-mail').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('invalide, expiré ou déjà utilisé'),
        findsOneWidget);
    expect(api.user, isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets(
      'recovery is scrollable with large text and invalid links never reach the server',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    var calls = 0;
    final api = clientFor((r, s) => jsonResponse({}), auth: (r, s) {
      calls++;
      return jsonResponse({});
    });
    await tester.pumpWidget(MaterialApp(home: RecoveryPage(apiClient: api)));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.text('J’ai déjà un lien de réinitialisation'));
    await tester.tap(find.text('J’ai déjà un lien de réinitialisation'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('recovery-token')), 'not-a-valid-token');
    await tester.enterText(
        find.byKey(const ValueKey('recovery-password')), 'é' * 40);
    await tester.enterText(
        find.byKey(const ValueKey('recovery-confirmation')), 'é' * 40);
    await tester.ensureVisible(find.text('Enregistrer le mot de passe'));
    await tester.tap(find.text('Enregistrer le mot de passe'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(
        find.text('12 caractères minimum, 72 octets maximum.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
