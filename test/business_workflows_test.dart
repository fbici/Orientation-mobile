import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/core/constants/app_constants.dart';
import 'package:orientia/core/network/api_failure.dart';
import 'package:orientia/features/navigation/presentation/workspace_pages.dart';
import 'package:orientia/features/profile/presentation/account_edit_dialog.dart';
import 'package:orientia/features/chat/presentation/chat_page.dart';
import 'package:orientia/core/data/orientation_repository.dart';
import 'package:orientia/features/profile/presentation/account_deletion_page.dart';
import 'support/fake_transport.dart';

void main() {
  test(
      'admission criteria include the second page and preserve the program filter',
      () async {
    final pages = <int>[];
    final api = clientFor((r, s) {
      expect(r.queryParameters['programId'], 'program');
      final page = r.queryParameters['page'] as int;
      pages.add(page);
      return jsonResponse({
        'content': [
          for (var i = page * 100; i < (page == 0 ? 100 : 101); i++)
            {'id': 'rule-$i'}
        ],
        'number': page,
        'size': 100,
        'totalElements': 101
      });
    });
    await api.login('test', 'test');
    final criteria =
        await OrientationRepository(api).admissionCriteria('program');
    expect(criteria.length, 101);
    expect(criteria.last['id'], 'rule-100');
    expect(pages, [0, 1]);
    api.dispose();
  });
  testWidgets(
      'deletion requires explicit confirmation and displays only an acknowledged date',
      (tester) async {
    var calls = 0;
    final api = clientFor((r, s) {
      calls++;
      expect(r.path, '/auth/me/deletion-request');
      expect(r.method, 'POST');
      expect(r.data,
          {'confirmation': 'SUPPRIMER', 'currentPassword': 'test-password'});
      return jsonResponse({'purgeAfter': '2026-12-11T10:00:00Z'});
    });
    await tester.runAsync(() => api.login('test', 'test'));
    await tester.pumpWidget(MaterialApp(
        home: AccountDeletionPage(apiClient: api, onLogout: () {})));
    await tester.ensureVisible(find.text('Confirmer la suppression différée'));
    await tester.tap(find.text('Confirmer la suppression différée'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.enterText(
        find.widgetWithText(TextField, 'Saisissez SUPPRIMER'), 'SUPPRIMER');
    await tester.enterText(
        find.widgetWithText(TextField, 'Mot de passe actuel'), 'test-password');
    await tester.ensureVisible(find.text('Confirmer la suppression différée'));
    await tester.tap(find.text('Confirmer la suppression différée'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Demande enregistrée'), findsOneWidget);
    expect(find.textContaining('11/12/2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  test('inactive registration has actionable guidance and no delivery claim',
      () {
    final request = RequestOptions(path: '/auth/mobile/register');
    final error = DioException(
        requestOptions: request,
        response: Response(
            requestOptions: request,
            statusCode: 400,
            data: {'code': 'ACCOUNT_INACTIVE', 'message': 'Compte désactivé'}));
    final failure = ApiFailure.from(error);
    expect(failure.message, contains('Aucun code n’a été envoyé'));
    expect(failure.message, contains('lestudioviral@gmail.com'));
    expect(failure.message, isNot(contains('30 jours')));
  });
  test('about version matches the distributable version', () {
    final version = RegExp(r'^version: ([^+\r\n]+)', multiLine: true)
        .firstMatch(File('pubspec.yaml').readAsStringSync())!
        .group(1);
    expect(AppConstants.appVersion, version);
  });
  testWidgets('Explorer exposes all existing catalogues', (tester) async {
    final api =
        clientFor((r, s) => jsonResponse({'content': [], 'totalElements': 0}));
    await tester.pumpWidget(
        MaterialApp(home: WorkspacePage(apiClient: api, explore: true)));
    expect(find.text('Universités'), findsOneWidget);
    expect(find.text('Formations et comparaison'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Bourses'), 200);
    expect(find.text('Bourses'), findsOneWidget);
    api.dispose();
  });
  testWidgets(
      'editing the name preserves the stored phone and waits for acknowledgement',
      (tester) async {
    final response = Completer<ResponseBody>();
    Map<String, dynamic>? saved;
    var writes = 0;
    final api = clientFor((r, s) {
      if (r.path == '/auth/me' && r.method == 'PUT') {
        writes++;
        saved = Map<String, dynamic>.from(r.data as Map);
        return response.future;
      }
      return jsonResponse({});
    });
    await tester.runAsync(() => api.login('test', 'test'));
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<bool>(
                        context: context,
                        builder: (_) => AccountEditDialog(
                                apiClient: api,
                                password: false,
                                me: const {
                                  'firstName': 'Ada',
                                  'lastName': 'Test',
                                  'phone': '+2290197000000'
                                })),
                    child: const Text('Modifier'))))));
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Prénom'), 'Amina');
    await tester.tap(find.text('Enregistrer'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(saved?['phone'], '+2290197000000');
    expect(saved?['firstName'], 'Amina');
    expect(writes, 1);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Enregistrer'))
            .onPressed,
        isNull);
    response.complete(
        jsonResponse({'firstName': 'Amina', 'phone': '+2290197000000'}));
    await tester.pumpAndSettle();
    expect(find.byType(AccountEditDialog), findsNothing);
    api.dispose();
  });
  testWidgets(
      'invalid password confirmation stays in the dialog without an API call',
      (tester) async {
    var calls = 0;
    final api = clientFor((r, s) {
      calls++;
      return jsonResponse({});
    });
    await tester.runAsync(() => api.login('test', 'test'));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AccountEditDialog(
                apiClient: api, me: const {}, password: true))));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe actuel'),
        'old-secret');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nouveau mot de passe'),
        'A-new-password-123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmer le nouveau mot de passe'),
        'different');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(
        find.text('Les mots de passe ne correspondent pas.'), findsOneWidget);
    expect(calls, 0);
    api.dispose();
  });
  testWidgets(
      'chat opens latest messages and returns to latest page after sending from older history',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var sent = false;
    final pages = <int>[];
    Map<String, dynamic> row(String question) => {
          'id': question,
          'result': {
            'question': question,
            'content': 'Réponse disponible',
            'status': 'ANSWERED',
            'sources': []
          }
        };
    final api = clientFor((r, s) {
      if (r.path == '/ai/chat/sessions') {
        return jsonResponse({
          'content': [
            {'id': 's', 'computedAt': '2026-11-11T10:00:00Z'}
          ],
          'last': true
        });
      }
      if (r.method == 'POST') {
        sent = true;
        return jsonResponse(row('Question nouvelle')['result']);
      }
      final page = (r.queryParameters['page'] as num).toInt();
      pages.add(page);
      return jsonResponse({
        'content': page == 0
            ? [row('Question ancienne')]
            : [row('Question récente'), if (sent) row('Question nouvelle')],
        'totalPages': 2,
        'last': page == 1
      });
    });
    await tester.runAsync(() => api.login('test', 'test'));
    await tester.pumpWidget(MaterialApp(home: ChatPage(apiClient: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reprendre une conversation'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Conversation du'));
    await tester.pumpAndSettle();
    expect(pages, [0, 1]);
    expect(find.text('Question récente'), findsOneWidget);
    await tester.ensureVisible(find.text('Messages précédents'));
    await tester.tap(find.text('Messages précédents'));
    await tester.pumpAndSettle();
    expect(find.text('Question ancienne'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Votre question'), 'Question nouvelle');
    await tester.tap(find.byTooltip('Envoyer la question'));
    await tester.pumpAndSettle();
    expect(sent, isTrue);
    expect(pages.sublist(pages.length - 2), [0, 1]);
    expect(find.text('Question nouvelle'), findsOneWidget);
    expect(find.text('Question ancienne'), findsNothing);
    expect(tester.takeException(), isNull);
    api.dispose();
  });
}
