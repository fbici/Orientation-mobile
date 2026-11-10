import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/features/auth/presentation/verification_code_page.dart';
import 'support/fake_transport.dart';

const challenge = '11111111-1111-4111-8111-111111111111';
void main() {
  testWidgets('verification stays inside the app and never opens a session',
      (tester) async {
    var verified = 0;
    final store = MemorySessions();
    final api =
        clientFor((r, s) => jsonResponse({}), store: store, auth: (r, s) {
      expect(r.path, '/auth/mobile/verify-email');
      expect(r.method, 'POST');
      expect(r.data, {'challengeId': challenge, 'code': '123456'});
      return jsonResponse({'message': 'Adresse vérifiée'});
    });
    await tester.pumpWidget(MaterialApp(
        home: VerificationCodePage(
            apiClient: api,
            challengeId: challenge,
            email: 'synthetic@example.test',
            onVerified: () => verified++,
            onBack: () {})));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('verification-code')), '123456');
    await tester.ensureVisible(find.text('Vérifier mon compte'));
    await tester.tap(find.text('Vérifier mon compte'));
    await tester.pumpAndSettle();
    expect(find.text('Adresse vérifiée !'), findsOneWidget);
    expect(api.user, isNull);
    expect(store.writes, 0);
    expect(verified, 0);
    await tester.ensureVisible(find.text('Aller à la connexion'));
    await tester.tap(find.text('Aller à la connexion'));
    expect(verified, 1);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('refused code keeps the input and cannot show success',
      (tester) async {
    final api = clientFor((r, s) => jsonResponse({}),
        auth: (r, s) => jsonResponse(
            {'message': 'Code invalide, expiré ou nombre d’essais dépassé.'},
            400));
    await tester.pumpWidget(MaterialApp(
        home: VerificationCodePage(
            apiClient: api,
            challengeId: challenge,
            email: 'synthetic@example.test',
            onVerified: () {
              fail('No success');
            },
            onBack: () {})));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('verification-code')), '000000');
    await tester.ensureVisible(find.text('Vérifier mon compte'));
    await tester.tap(find.text('Vérifier mon compte'));
    await tester.pumpAndSettle();
    expect(find.text('Adresse vérifiée !'), findsNothing);
    expect(find.byKey(const ValueKey('verification-code')), findsOneWidget);
    expect(find.text('Aller à la connexion'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('pending verification blocks duplicate submissions and editing',
      (tester) async {
    var calls = 0;
    final pending = Completer<ResponseBody>();
    final api = clientFor((r, s) => jsonResponse({}), auth: (r, s) {
      calls++;
      return pending.future;
    });
    await tester.pumpWidget(MaterialApp(
        home: VerificationCodePage(
            apiClient: api,
            challengeId: challenge,
            email: 'synthetic@example.test',
            onVerified: () {},
            onBack: () {})));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('verification-code')), '123456');
    await tester.ensureVisible(find.text('Vérifier mon compte'));
    await tester.tap(find.text('Vérifier mon compte'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.ensureVisible(find.text('Vérification en cours…'));
    await tester.tap(find.text('Vérification en cours…'));
    await tester.pump();
    expect(calls, 1);
    expect(
        tester
            .widget<TextFormField>(
                find.byKey(const ValueKey('verification-code')))
            .enabled,
        isFalse);
    pending.complete(jsonResponse({'message': 'Adresse vérifiée'}));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  test('mobile registration rejects a 202 without a usable challenge',
      () async {
    final api = clientFor((r, s) => jsonResponse({}),
        auth: (r, s) => jsonResponse({'message': 'Accepted'}, 202));
    await expectLater(api.registerMobile({'email': 'synthetic@example.test'}),
        throwsA(isA<DioException>()));
    expect(api.user, isNull);
    api.dispose();
  });
}
