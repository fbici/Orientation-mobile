import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orientia/app.dart';
import 'package:orientia/core/models/academic_models.dart';
import 'package:orientia/features/documents/presentation/documents_page.dart';
import 'package:orientia/features/chat/presentation/chat_page.dart';
import 'package:orientia/core/widgets/academic_widgets.dart';
import 'support/fake_transport.dart';
import 'support/launch_logo.dart';

Json profileFixture() => {
      'candidateId': '33333333-3333-4333-8333-333333333333',
      'version': 0,
      'confirmedAt': null,
      'data': {}
    };
ResponseBody publicFixture(RequestOptions r) {
  if (r.path == '/auth/me') return jsonResponse(sessionData()['user']);
  if (r.path == '/candidates/me/academic-profile') {
    return jsonResponse(profileFixture());
  }
  if (['/locations/countries', '/academic-years', '/subjects', '/grade-scales']
      .contains(r.path)) {
    return jsonResponse([]);
  }
  return jsonResponse({
    'content': [],
    'totalElements': 0,
    'size': 20,
    'number': 0,
    'last': true
  });
}

void main() {
  setUp(() =>
      SharedPreferences.setMockInitialValues({'orientia_intro_seen_v1': true}));
  testWidgets(
      'documentary chat facts link to the catalogue without an eligibility verdict',
      (tester) async {
    final api = clientFor((r, s) {
      if (r.path == '/ai/chat/sessions' && r.method == 'POST') {
        return jsonResponse({'sessionId': 'session'});
      }
      if (r.path.endsWith('/messages') && r.method == 'POST') {
        return jsonResponse({
          'id': 'message',
          'status': 'ANSWERED',
          'intent': 'SEARCH',
          'content': 'Faits documentaires',
          'sources': [],
          'data': [
            {
              'entityId': 'program',
              'entityType': 'PROGRAM',
              'name': 'Formation sourcee',
              'content': 'SYNTHETIC NOT OFFICIAL',
              'sources': []
            }
          ]
        });
      }
      if (r.path == '/programs/program') {
        return jsonResponse(
            {'id': 'program', 'name': 'Formation sourcee', 'verified': true});
      }
      if (r.path.endsWith('/sources')) return jsonResponse([]);
      return jsonResponse({
        'content': [],
        'totalElements': 0,
        'number': 0,
        'size': 20,
        'last': true
      });
    });
    await tester.runAsync(() => api.login('test', 'test'));
    await tester.pumpWidget(MaterialApp(home: ChatPage(apiClient: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer une conversation'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).last, 'Rechercher une formation');
    await tester.tap(find.byTooltip('Envoyer la question'));
    await tester.pumpAndSettle();
    expect(find.text('Formation sourcee'), findsOneWidget);
    expect(find.byType(EligibilityChip), findsNothing);
    await tester.ensureVisible(find.text('Consulter la fiche'));
    await tester.tap(find.text('Consulter la fiche'));
    await tester.pumpAndSettle();
    expect(find.text('Détails et sources'), findsOneWidget);
    expect(find.text('Formation sourcee'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('login remains usable on a small screen with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = clientFor((r, s) => publicFixture(r));
    await tester.pumpWidget(OrientiaApp(apiClient: api));
    await loadSplashLogo(tester);
    await tester.pumpAndSettle();
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets(
      'real application navigation reaches catalogues and clears identity on logout',
      (tester) async {
    final api = clientFor((r, s) => publicFixture(r));
    await tester.pumpWidget(OrientiaApp(apiClient: api));
    await loadSplashLogo(tester);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).at(0), 'synthetic@example.test');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'synthetic-password');
    await tester.ensureVisible(find.text('Se connecter'));
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Mon profil académique'), findsOneWidget);
    await tester.tap(find.text('Explorer').last);
    await tester.pumpAndSettle();
    expect(
        find.text('Aucun résultat vérifié pour ces filtres.'), findsOneWidget);
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    expect(find.text('synthetic@example.test'), findsOneWidget);
    await tester.ensureVisible(find.text('Se déconnecter'));
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('synthetic@example.test'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets(
      'restoring an offline session does not reveal the protected pages',
      (tester) async {
    final api = clientFor(
        (r, s) => throw DioException(
            requestOptions: r, type: DioExceptionType.connectionError),
        store: MemorySessions(jsonEncode(sessionData())));
    await tester.pumpWidget(OrientiaApp(apiClient: api));
    await loadSplashLogo(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('Vos données privées restent verrouillées'),
        findsOneWidget);
    expect(find.text('Mon profil académique'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets(
      'OCR unknown grades stay blank and edits must be saved before confirmation',
      (tester) async {
    final fixture = {
      'id': 'analysis',
      'transcriptId': 'transcript',
      'status': 'DRAFT',
      'data': {
        'review': {
          'gradeScaleId': 'scale',
          'period': 'YEAR',
          'average': null,
          'marks': [
            {
              'rawSubject': 'MATH',
              'subjectId': null,
              'rawGrade': '? /20',
              'value': null,
              'coefficient': null,
              'page': 1,
              'passage': 'SYNTHETIC SCHOOL REPORT: MATH ? /20'
            }
          ]
        }
      }
    };
    final api = clientFor((r, s) => jsonResponse([]));
    await tester.runAsync(() => api.login('test', 'test'));
    await tester.pumpWidget(MaterialApp(
        home: AnalysisPage(
            apiClient: api,
            analysis: TranscriptAnalysis.fromJson(fixture),
            transcript: const {'academicYearId': 'year'})));
    await tester.pumpAndSettle();
    final numeric = find.byType(TextField);
    expect(tester.widget<TextField>(numeric.at(0)).controller!.text, '');
    expect(tester.widget<TextField>(numeric.at(1)).controller!.text, '');
    await tester.enterText(numeric.at(1), '14');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Confirmer la version enregistrée'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    final confirm = tester.widget<OutlinedButton>(find.widgetWithText(
        OutlinedButton, 'Confirmer la version enregistrée'));
    expect(confirm.onPressed, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
