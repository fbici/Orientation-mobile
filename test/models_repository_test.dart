import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:orientia/core/constants/app_constants.dart';
import 'package:orientia/core/data/orientation_repository.dart';
import 'package:orientia/core/models/academic_models.dart';
import 'package:orientia/core/network/api_failure.dart';
import 'support/fake_transport.dart';

void main() {
  test('unverified email keeps verification guidance', () {
    for (final status in [401, 403]) {
      final request = RequestOptions(path: '/auth/login');
      final failure = ApiFailure.from(DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: status,
          data: {'message': 'EMAIL_NOT_VERIFIED'},
        ),
      ));
      expect(failure.message, contains('email'));
      expect(failure.message, contains('spams'));
    }
  });
  test(
      'unknown eligibility is never favorable and an unknown score remains null',
      () {
    final r = Recommendation.fromJson({
      'id': 'r',
      'programId': 'p',
      'eligibilityStatus': 'FUTURE_STATE',
      'score': null,
      'dataCoverage': null,
      'sourceCurrent': false,
      'stale': true,
      'explanation': {}
    });
    expect(r.eligibility, Eligibility.insufficientData);
    expect(r.score, isNull);
    expect(r.stale, isTrue);
    expect(r.sourceCurrent, isFalse);
  });
  test('profile writes preserve the current version and explicit unknowns', () {
    final p = AcademicProfileView.fromJson({
      'candidateId': 'c',
      'version': 7,
      'confirmedAt': null,
      'data': {'bacSeries': 'D', 'generalAverage': null}
    });
    final request = p.request({'confirmed': false});
    expect(request['version'], 7);
    expect(request['bacSeries'], 'D');
    expect(request['generalAverage'], isNull);
    expect(p.confirmed, isFalse);
  });
  test('page bounds come from server metadata without manufacturing rows', () {
    final p = PageData<Json>.parse(
        {'content': [], 'number': 1, 'size': 20, 'totalElements': 20},
        (j) => j);
    expect(p.hasNext, isFalse);
    expect(p.content, isEmpty);
  });
  test('production and remote hosts require HTTPS', () {
    for (final host in [
      '10.attacker.example',
      '192.168.attacker.example',
      '172.16.300.4',
      '010.0.0.1'
    ]) {
      expect(
          () => AppConstants.validateBaseUrl('http://$host',
              release: false, env: 'development'),
          throwsArgumentError);
    }
    expect(
        AppConstants.validateBaseUrl('http://192.168.1.20:8080/api/v1/',
                release: false, env: 'development')
            .path,
        '/api/v1');
    expect(
        () =>
            AppConstants.validateBaseUrl('http://10.0.2.2:8080', release: true),
        throwsArgumentError);
    expect(
        () => AppConstants.validateBaseUrl('http://remote.example',
            release: false, env: 'development'),
        throwsArgumentError);
    expect(
        AppConstants.validateBaseUrl('https://api.example.test/api',
                release: true)
            .path,
        '/api');
    expect(
        () => AppConstants.validateBaseUrl(
            'https://user:secret@api.example.test'),
        throwsArgumentError);
  });
  test('simulation calls only its dedicated API and never writes the profile',
      () async {
    final paths = <String>[];
    final api = clientFor((r, s) {
      paths.add('${r.method} ${r.path}');
      return jsonResponse({
        'id': 'd',
        'kind': 'SIMULATION',
        'result': {'isSimulation': true, 'before': [], 'after': []}
      });
    });
    await api.login('test', 'test');
    final d = await OrientationRepository(api)
        .simulate({'modifiedGeneralAverage': 13});
    expect(d.kind, 'SIMULATION');
    expect(paths, ['POST /recommendations/simulate']);
    api.dispose();
  });
  test('generation refuses an unconfirmed profile before calling the engine',
      () async {
    final paths = <String>[];
    final api = clientFor((r, s) {
      paths.add(r.path);
      return jsonResponse(
          {'candidateId': 'c', 'version': 0, 'confirmedAt': null, 'data': {}});
    });
    await api.login('test', 'test');
    await expectLater(
        OrientationRepository(api).generate(), throwsFormatException);
    expect(paths, ['/candidates/me/academic-profile']);
    api.dispose();
  });
  test('binary exports request bytes and validate the actual PDF signature',
      () async {
    final api = clientFor((r, s) {
      expect(r.responseType, ResponseType.bytes);
      return ResponseBody.fromBytes(utf8.encode('%PDF-1.7 SYNTHETIC'), 200);
    });
    await api.login('test', 'test');
    final bytes = await OrientationRepository(api).export('d', 'pdf');
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    api.dispose();
  });
  test('a JSON error disguised as PDF is never shared', () async {
    final api = clientFor((r, s) =>
        ResponseBody.fromBytes(utf8.encode('{"error":"denied"}'), 200));
    await api.login('test', 'test');
    await expectLater(
        OrientationRepository(api).export('d', 'pdf'), throwsFormatException);
    api.dispose();
  });
  test(
      'unsupported file signatures are rejected before transmitting private data',
      () async {
    int requests = 0;
    final api = clientFor((r, s) {
      requests++;
      return jsonResponse({});
    });
    await api.login('test', 'test');
    await expectLater(
        OrientationRepository(api)
            .upload(Uint8List.fromList([1, 2, 3]), 'pdf', 'year'),
        throwsFormatException);
    expect(requests, 0);
    api.dispose();
  });
  test('403 409 422 and 503 remain distinct user-facing failures', () {
    for (final status in [403, 409, 422, 503]) {
      final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: status,
              data: {'message': 'Published rule unavailable'}));
      expect(ApiFailure.from(error).status, status);
      expect(ApiFailure.from(error).message, isNotEmpty);
    }
  });
}
