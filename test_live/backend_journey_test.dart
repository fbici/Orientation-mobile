import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/core/data/orientation_repository.dart';
import 'package:orientia/core/models/academic_models.dart';
import 'package:orientia/core/network/api_client.dart';
import '../test/support/fake_transport.dart' show MemorySessions;

// Explicitly invoked by MobileFlutterJourneyIT while its isolated server runs.
// No test server, fixture, credential or synthetic catalogue enters production.
void main() {
  test('real HTTP candidate journey against isolated Spring/PostgreSQL',
      () async {
    final path = Platform.environment['F33_LIVE_FIXTURE'];
    expect(path, isNotNull,
        reason: 'Start the isolated Java integration harness');
    final fixture = object(jsonDecode(await File(path!).readAsString()));
    final uri = Uri.parse(fixture['url'] as String);
    expect(uri.host, '127.0.0.1');
    expect(uri.port, 59833);
    final storage = MemorySessions();
    final api = ApiClient(baseUrl: uri.toString(), storage: storage);
    final other = ApiClient(baseUrl: uri.toString(), storage: MemorySessions());
    addTearDown(api.dispose);
    addTearDown(other.dispose);
    final repo = OrientationRepository(api);
    await api.login(fixture['email'] as String, fixture['password'] as String);
    expect((await api.getMe()).statusCode, 200);
    final original = await repo.profile();
    final draft = await repo.saveProfile(original.request({
      'transcriptAnalysisId': null,
      'generalAverage': 13,
      'confirmed': false,
    }));
    expect(draft.confirmed, isFalse);
    final report = await repo.upload(
        await File(fixture['pdf'] as String).readAsBytes(),
        'pdf',
        draft.data['gradesAcademicYearId'] as String);
    var analysis = await repo.analyze(
        report['id'] as String, draft.data['gradeScaleId'] as String, 'YEAR');
    expect(analysis.confirmed, isFalse);
    final review = Map<String, dynamic>.from(analysis.review);
    final marks = objects(review['marks']);
    expect(marks, isNotEmpty);
    expect(marks.any((m) => m['value'] == null), isTrue);
    final known = marks.firstWhere((m) => m['value'] != null);
    known['value'] = 14;
    review['marks'] = marks;
    analysis = await repo.correct(analysis, review);
    analysis = await repo.confirm(analysis);
    expect(analysis.confirmed, isTrue);
    expect((await repo.analyses(report['id'] as String)).total, 3);
    final current = await repo.profile();
    final confirmed = await repo.saveProfile(current.request({
      'transcriptAnalysisId': analysis.id,
      'confirmed': true,
    }));
    expect(confirmed.confirmed, isTrue);
    final runId = await repo.generate();
    final recommendations = await repo.recommendations(runId: runId);
    expect(recommendations.content.length, 3);
    expect(
        recommendations.content
            .any((r) => r.eligibility == Eligibility.eligible),
        isTrue);
    expect(
        recommendations.content
            .any((r) => r.eligibility == Eligibility.insufficientData),
        isTrue);
    expect(
        recommendations.content
            .any((r) => r.explanation.toString().contains('sourceFactId')),
        isTrue);
    final before = await repo.profile();
    final simulation = await repo.simulate({'modifiedGeneralAverage': 11});
    expect(simulation.kind, 'SIMULATION');
    expect(simulation.result.toString(), contains('becameNotEligible'));
    final after = await repo.profile();
    expect(after.version, before.version);
    expect(after.data, before.data);
    final ids =
        recommendations.content.take(3).map((r) => r.programId).toList();
    final comparison = await repo.compare(ids);
    expect(comparison.kind, 'COMPARISON');
    expect(objects(comparison.result['programs']).length, 3);
    final funding = await repo.scholarships();
    expect(funding.kind, 'SCHOLARSHIP');
    expect(objects(funding.result['scholarships']), isNotEmpty);
    final session =
        object((await api.call('/ai/chat/sessions', method: 'POST')).data);
    final sessionId = session['sessionId'] as String;
    final answer = object((await api.call(
            '/ai/chat/sessions/$sessionId/messages',
            method: 'POST',
            data: {'message': 'Compare ces formations', 'programIds': ids}))
        .data);
    expect(answer['status'], 'ANSWERED');
    expect(answer['decisionId'], isNotNull);
    expect(
        object((await api.call('/ai/chat/sessions/$sessionId/messages')).data)[
            'totalElements'],
        1);
    expect(
        (await repo.history('SIMULATION'))
            .content
            .any((d) => d.id == simulation.id),
        isTrue);
    for (final format in ['pdf', 'csv', 'excel']) {
      expect(
          (await repo.export(comparison.id, format)).length, greaterThan(100));
    }
    await other.login(
        fixture['otherEmail'] as String, fixture['password'] as String);
    await expectLater(
        OrientationRepository(other).decision(comparison.id),
        throwsA(isA<DioException>()
            .having((e) => e.response?.statusCode, 'status', 403)));
    await expectLater(
        OrientationRepository(other).export(comparison.id, 'pdf'),
        throwsA(isA<DioException>()
            .having((e) => e.response?.statusCode, 'status', 403)));
    await api.logout();
    expect(storage.value, isNull);
    expect(api.user, isNull);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
