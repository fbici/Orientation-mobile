import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/core/network/api_client.dart';
import 'package:orientia/core/network/api_failure.dart';
import 'package:orientia/core/widgets/international_phone_field.dart';
import 'package:orientia/features/auth/presentation/register_page.dart';
import 'support/fake_transport.dart';

Future<void> showRegistration(WidgetTester tester, ApiClient api,
    {VoidCallback? onSuccess}) async {
  await tester.pumpWidget(MaterialApp(
      home: RegisterPage(
          apiClient: api,
          onRegisterSuccess: onSuccess ?? () {},
          onBackToLogin: () {})));
  await tester.pumpAndSettle();
  for (final field in {
    'lastName': 'Synthetic',
    'firstName': 'Candidate',
    'email': 'synthetic@example.test',
    'password': 'Only-test-password-42!',
    'confirmation': 'Only-test-password-42!'
  }.entries) {
    await tester.enterText(
        find.byKey(ValueKey('register-${field.key}')), field.value);
  }
  await tester.ensureVisible(find.text('Créer mon compte'));
}

void expectUnconfirmed(ApiClient api, MemorySessions store, int successes) {
  expect(api.user, isNull);
  expect(store.value, isNull);
  expect(store.writes, 0);
  expect(successes, 0);
  expect(find.text('Aller à la connexion'), findsNothing);
  expect(find.textContaining('Demande reçue.'), findsNothing);
  expect(find.byKey(const ValueKey('register-email')), findsOneWidget);
}

void main() {
  testWidgets(
      'mail service failure does not acknowledge registration or delivery',
      (tester) async {
    var calls = 0, successes = 0;
    final store = MemorySessions();
    final api = clientFor((r, s) => jsonResponse({}), auth: (r, s) {
      calls++;
      expect(r.path, '/auth/mobile/register');
      return jsonResponse({
        'message': 'Email delivery unavailable; no delivery is confirmed',
        'internal': 'private-provider-detail'
      }, 503);
    }, store: store);
    await showRegistration(tester, api, onSuccess: () => successes++);
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expectUnconfirmed(api, store, successes);
    expect(find.textContaining('Le service de vérification par e-mail'),
        findsOneWidget);
    expect(find.textContaining('n’ont pas pu être confirmés'), findsOneWidget);
    expect(find.textContaining('private-provider-detail'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets('a proxy 503 remains a generic outage without blaming email',
      (tester) async {
    var calls = 0, successes = 0;
    final store = MemorySessions();
    final api = clientFor((r, s) => jsonResponse({}), auth: (r, s) {
      calls++;
      return ResponseBody.fromString('<html>private-proxy-error</html>', 503,
          headers: {
            Headers.contentTypeHeader: ['text/html']
          });
    }, store: store);
    await showRegistration(tester, api, onSuccess: () => successes++);
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expectUnconfirmed(api, store, successes);
    expect(find.textContaining('Service momentanément indisponible.'),
        findsOneWidget);
    expect(find.textContaining('Le service de vérification par e-mail'),
        findsNothing);
    expect(find.textContaining('private-proxy-error'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
      'a registration timeout remains uncertain and is never retried automatically',
      (tester) async {
    var calls = 0, successes = 0;
    final store = MemorySessions();
    final api = clientFor((r, s) => jsonResponse({}), auth: (request, stream) {
      calls++;
      throw DioException(
          requestOptions: request,
          type: DioExceptionType.receiveTimeout,
          message: 'private-transport-detail');
    }, store: store);
    await showRegistration(tester, api, onSuccess: () => successes++);
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 95));

    expect(calls, 1);
    expectUnconfirmed(api, store, successes);
    expect(find.textContaining('Le délai d’attente a été dépassé.'),
        findsOneWidget);
    expect(
        find.textContaining(
            'La réception de votre demande n’a pas pu être confirmée.'),
        findsOneWidget);
    expect(find.textContaining('private-transport-detail'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets('an HTML 200 response cannot appear as a successful registration',
      (tester) async {
    var calls = 0, successes = 0;
    final store = MemorySessions();
    final api = clientFor((r, s) => jsonResponse({}), auth: (r, s) {
      calls++;
      return ResponseBody.fromString('<html>private-proxy-content</html>', 200,
          headers: {
            Headers.contentTypeHeader: ['text/html']
          });
    }, store: store);
    await showRegistration(tester, api, onSuccess: () => successes++);
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expectUnconfirmed(api, store, successes);
    expect(
        find.textContaining(
            'Le serveur n’a pas confirmé votre demande d’inscription.'),
        findsOneWidget);
    expect(find.textContaining('private-proxy-content'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets('pending registration freezes its inputs and submits once',
      (tester) async {
    var calls = 0, successes = 0;
    final store = MemorySessions();
    final pending = Completer<ResponseBody>();
    final api = clientFor((r, s) => jsonResponse({}), auth: (r, s) {
      calls++;
      return pending.future;
    }, store: store);
    await showRegistration(tester, api, onSuccess: () => successes++);
    await tester.tap(find.text('Créer mon compte'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.ensureVisible(find.text('Création en cours…'));
    await tester.tap(find.text('Création en cours…'));
    await tester.pump();

    expect(calls, 1);
    for (final name in [
      'firstName',
      'lastName',
      'email',
      'password',
      'confirmation'
    ]) {
      expect(
          tester
              .widget<TextFormField>(find.byKey(ValueKey('register-$name')))
              .enabled,
          isFalse);
    }
    expect(
        tester
            .widget<InternationalPhoneField>(
                find.byType(InternationalPhoneField))
            .enabled,
        isFalse);
    final passwordToggles = find.byWidgetPredicate((widget) =>
        widget is IconButton && widget.tooltip == 'Afficher le mot de passe');
    expect(passwordToggles, findsNWidgets(2));
    for (final toggle in tester.widgetList<IconButton>(passwordToggles)) {
      expect(toggle.onPressed, isNull);
    }
    expectUnconfirmed(api, store, successes);

    pending.complete(jsonResponse({
      'challengeId': '11111111-1111-4111-8111-111111111111',
      'message': 'Registration request accepted. If eligible, check your email.'
    }, 202));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(api.user, isNull);
    expect(store.writes, 0);
    expect(find.byKey(const ValueKey('verification-code')), findsOneWidget);
    expect(successes, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  for (final acknowledgement in [
    <String, dynamic>{},
    {'message': ''},
    {'message': 42}
  ]) {
    test('an invalid 202 acknowledgement is rejected: $acknowledgement',
        () async {
      final store = MemorySessions();
      final api = clientFor((r, s) => jsonResponse({}),
          auth: (r, s) => jsonResponse(acknowledgement, 202), store: store);
      await expectLater(api.register({'email': 'synthetic@example.test'}),
          throwsA(isA<DioException>()));
      expect(api.user, isNull);
      expect(store.writes, 0);
      api.dispose();
    });
  }

  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout
  ]) {
    test('a write timeout is described as unconfirmed: $type', () {
      final failure = ApiFailure.from(DioException(
          requestOptions:
              RequestOptions(path: '/auth/register', method: 'POST'),
          type: type));
      expect(failure.message, contains('n’a pas pu être confirmée'));
      expect(failure.message, isNot(contains('compte n’a pas été créé')));
    });
  }
}
