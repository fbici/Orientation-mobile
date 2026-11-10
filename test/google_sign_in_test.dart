import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/core/network/api_client.dart';
import 'package:orientia/features/auth/data/google_identity.dart';
import 'package:orientia/features/auth/presentation/login_page.dart';
import 'support/fake_transport.dart';

class FakeGoogleIdentity implements GoogleIdentityProvider {
  final Future<String?> Function() result;
  int calls = 0;
  FakeGoogleIdentity(this.result);

  @override
  Future<String?> authenticate() {
    calls++;
    return result();
  }
}

void main() {
  testWidgets(
      'Google identity is exchanged for an Orientia session before login success',
      (tester) async {
    final identity =
        FakeGoogleIdentity(() async => 'synthetic-google-id-token');
    final store = MemorySessions();
    var requests = 0;
    var successes = 0;
    final api = clientFor((r, s) {
      fail('Google sign-in must not call a private endpoint.');
    }, auth: (request, stream) {
      requests++;
      expect(request.method, 'POST');
      expect(request.path, '/auth/google');
      expect(request.data, {'idToken': 'synthetic-google-id-token'});
      expect(request.headers.containsKey('Authorization'), isFalse);
      return jsonResponse(sessionData());
    }, store: store);
    await tester.pumpWidget(MaterialApp(
        home: LoginPage(
            apiClient: api,
            googleIdentity: identity,
            onLoginSuccess: () {
              expect(api.status, SessionStatus.authenticated);
              successes++;
            })));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuer avec Google'));
    await tester.tap(find.text('Continuer avec Google'));
    await tester.pumpAndSettle();

    expect(identity.calls, 1);
    expect(requests, 1);
    expect(successes, 1);
    expect(api.user?['email'], 'synthetic@example.test');
    expect(store.writes, 1);
    final saved = jsonDecode(store.value!) as Map<String, dynamic>;
    expect(saved['accessToken'], 'access-one');
    expect(saved['refreshToken'], 'rt1-test-one');
    expect(saved.containsKey('idToken'), isFalse);
    expect(find.text('Adresse email valide requise.'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
      'canceling the Google picker sends no request and leaves no session',
      (tester) async {
    final identity = FakeGoogleIdentity(() async => null);
    final store = MemorySessions();
    var requests = 0;
    var successes = 0;
    final api = clientFor((r, s) {
      requests++;
      return jsonResponse({});
    }, auth: (r, s) {
      requests++;
      return jsonResponse(sessionData());
    }, store: store);
    await tester.pumpWidget(MaterialApp(
        home: LoginPage(
            apiClient: api,
            googleIdentity: identity,
            onLoginSuccess: () => successes++)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuer avec Google'));
    await tester.tap(find.text('Continuer avec Google'));
    await tester.pumpAndSettle();

    expect(identity.calls, 1);
    expect(requests, 0);
    expect(successes, 0);
    expect(api.user, isNull);
    expect(store.writes, 0);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Action impossible'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
      'an existing password account is explained in French without linking or signing in',
      (tester) async {
    final identity =
        FakeGoogleIdentity(() async => 'synthetic-google-id-token');
    final store = MemorySessions();
    var requests = 0;
    var successes = 0;
    final api = clientFor((r, s) => jsonResponse({}), auth: (request, stream) {
      requests++;
      expect(request.path, '/auth/google');
      return jsonResponse({'message': 'GOOGLE_ACCOUNT_EXISTS'}, 409);
    }, store: store);
    await tester.pumpWidget(MaterialApp(
        home: LoginPage(
            apiClient: api,
            googleIdentity: identity,
            onLoginSuccess: () => successes++)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuer avec Google'));
    await tester.tap(find.text('Continuer avec Google'));
    await tester.pumpAndSettle();

    expect(requests, 1);
    expect(successes, 0);
    expect(api.user, isNull);
    expect(store.value, isNull);
    expect(store.writes, 0);
    expect(
        find.text(
            'Un compte Orientia existe déjà avec cette adresse. Connectez-vous avec votre mot de passe ; les comptes ne sont pas liés automatiquement.'),
        findsOneWidget);
    expect(find.textContaining('Le dossier a changé'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
      'Google picker is not opened twice while authentication is pending',
      (tester) async {
    final pending = Completer<String?>();
    final identity = FakeGoogleIdentity(() => pending.future);
    var requests = 0;
    final api = clientFor((r, s) => jsonResponse({}), auth: (r, s) {
      requests++;
      return jsonResponse(sessionData());
    });
    await tester.pumpWidget(MaterialApp(
        home: LoginPage(
            apiClient: api, googleIdentity: identity, onLoginSuccess: () {})));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuer avec Google'));
    await tester.tap(find.text('Continuer avec Google'));
    await tester.pump();
    await tester.tap(find.text('Continuer avec Google'));
    await tester.pump();

    expect(identity.calls, 1);
    expect(requests, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
