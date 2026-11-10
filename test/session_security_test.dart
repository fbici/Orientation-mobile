import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/core/network/api_client.dart';
import 'support/fake_transport.dart';

void main() {
  test('unremembered login and refresh never persist the token pair', () async {
    final store = MemorySessions();
    var calls = 0;
    final api = clientFor((r, s) {
      calls++;
      return calls == 1
          ? jsonResponse({}, 401)
          : jsonResponse(sessionData()['user']);
    }, store: store, auth: (r, s) => jsonResponse(sessionData()));
    await api.login('candidate@example.test', 'synthetic-password',
        rememberMe: false);
    expect(api.status, SessionStatus.authenticated);
    expect(store.value, isNull);
    await api.getMe();
    expect(store.value, isNull);
    expect(api.status, SessionStatus.authenticated);
    api.dispose();
  });
  test('successful password change clears the locally revoked session',
      () async {
    final store = MemorySessions();
    final api = clientFor((r, s) {
      expect(r.path, '/auth/me/password');
      expect(r.data, {'currentPassword': 'old', 'newPassword': 'new'});
      return jsonResponse({'message': 'Changed'});
    }, store: store);
    await api.login('test', 'test');
    await api.changePassword('old', 'new');
    expect(store.value, isNull);
    expect(api.status, SessionStatus.signedOut);
    api.dispose();
  });
  test('base URL servlet prefix survives authentication and business requests',
      () async {
    final business = Dio()
      ..httpClientAdapter = TestTransport((r, s) {
        expect(r.uri.path, '/api/v1/auth/me');
        return jsonResponse(sessionData()['user']);
      });
    final auth = Dio()
      ..httpClientAdapter = TestTransport((r, s) {
        expect(r.uri.path, '/api/v1/auth/login');
        return jsonResponse(sessionData());
      });
    final api = ApiClient(
        dio: business,
        authDio: auth,
        storage: MemorySessions(),
        baseUrl: 'http://127.0.0.1:59833/api/v1/');
    await api.login('test', 'test');
    await api.getMe();
    api.dispose();
  });
  test(
      'expired logout rotates once solely to revoke without restoring identity',
      () async {
    final store = MemorySessions();
    int refreshes = 0, revocations = 0;
    final api =
        clientFor((r, s) => jsonResponse({}), store: store, auth: (r, s) {
      if (r.path == '/auth/refresh') {
        refreshes++;
        return jsonResponse(
            sessionData(access: 'access-two', refresh: 'rt1-test-two'));
      }
      if (r.path == '/auth/logout') {
        revocations++;
        if (r.headers['Authorization'] == 'Bearer access-one') {
          return jsonResponse({}, 401);
        }
        expect(r.headers['Authorization'], 'Bearer access-two');
        expect(r.data['refreshToken'], 'rt1-test-two');
        expect(store.value, isNull);
        return jsonResponse({});
      }
      return jsonResponse(sessionData());
    });
    await api.login('test', 'test');
    await api.logout();
    expect(refreshes, 1);
    expect(revocations, 2);
    expect(store.value, isNull);
    expect(api.status, SessionStatus.signedOut);
    api.dispose();
  });
  test('login uses the actual token pair and a secure session envelope',
      () async {
    final store = MemorySessions();
    final api = clientFor((r, s) => jsonResponse({}), store: store);
    await api.login('candidate@example.test', 'synthetic-password');
    expect(api.status, SessionStatus.authenticated);
    expect(jsonDecode(store.value!)['refreshToken'], 'rt1-test-one');
    expect(api.user?['roles'], ['CANDIDAT']);
    api.dispose();
  });
  test('incorrect credentials never refresh', () async {
    int refresh = 0;
    final api = clientFor((r, s) => jsonResponse({}), auth: (r, s) {
      if (r.path.contains('refresh')) refresh++;
      return jsonResponse({'message': 'Refused'}, 401);
    });
    await expectLater(
        api.login('wrong', 'wrong'), throwsA(isA<DioException>()));
    expect(refresh, 0);
    expect(api.status, SessionStatus.signedOut);
    api.dispose();
  });
  test('concurrent expired requests rotate the refresh token exactly once',
      () async {
    int refresh = 0;
    final api = clientFor(
        (r, s) => r.headers['Authorization'] == 'Bearer access-one'
            ? jsonResponse({}, 401)
            : jsonResponse({'id': 'ok'}), auth: (r, s) async {
      if (r.path == '/auth/refresh') {
        refresh++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return jsonResponse(
            sessionData(access: 'access-two', refresh: 'rt1-test-two'));
      }
      return jsonResponse(sessionData());
    });
    await api.login('test', 'test');
    await Future.wait([api.getMe(), api.getMe(), api.getMe()]);
    expect(refresh, 1);
    expect(api.status, SessionStatus.authenticated);
    api.dispose();
  });
  test('a refused refresh clears the local identity without a retry loop',
      () async {
    final store = MemorySessions();
    int refresh = 0;
    final api =
        clientFor((r, s) => jsonResponse({}, 401), store: store, auth: (r, s) {
      if (r.path == '/auth/refresh') {
        refresh++;
        return jsonResponse({}, 401);
      }
      return jsonResponse(sessionData());
    });
    await api.login('test', 'test');
    await expectLater(api.getMe(), throwsA(isA<DioException>()));
    expect(refresh, 1);
    expect(store.value, isNull);
    expect(api.user, isNull);
    expect(api.status, SessionStatus.signedOut);
    api.dispose();
  });
  test(
      'a newly issued access token rejected by the server is not refreshed twice',
      () async {
    int refresh = 0;
    final api = clientFor((r, s) => jsonResponse({}, 401), auth: (r, s) {
      if (r.path == '/auth/refresh') refresh++;
      return jsonResponse(sessionData(
          access: r.path == '/auth/refresh' ? 'access-two' : 'access-one'));
    });
    await api.login('test', 'test');
    await expectLater(api.getMe(), throwsA(isA<DioException>()));
    expect(refresh, 1);
    expect(api.status, SessionStatus.signedOut);
    api.dispose();
  });
  test('restore verifies the server identity before opening the application',
      () async {
    final store = MemorySessions(jsonEncode(sessionData()));
    int me = 0;
    final api = clientFor((r, s) {
      me++;
      return jsonResponse(sessionData()['user']);
    }, store: store);
    await api.restore();
    expect(me, 1);
    expect(api.status, SessionStatus.authenticated);
    api.dispose();
  });
  test(
      'an offline restored session remains locked and its secure credentials survive',
      () async {
    final store = MemorySessions(jsonEncode(sessionData()));
    final api = clientFor(
        (r, s) => throw DioException(
            requestOptions: r, type: DioExceptionType.connectionError),
        store: store);
    await api.restore();
    expect(api.status, SessionStatus.unavailable);
    expect(store.value, isNotNull);
    api.dispose();
  });
  test('an inactive account during restore clears local access', () async {
    final store = MemorySessions(jsonEncode(sessionData()));
    final api = clientFor((r, s) => jsonResponse({}, 403), store: store);
    await api.restore();
    expect(api.status, SessionStatus.signedOut);
    expect(store.value, isNull);
    api.dispose();
  });
  test(
      'logout revokes the real refresh token and immediately clears local access',
      () async {
    final store = MemorySessions();
    String? revoked;
    final api =
        clientFor((r, s) => jsonResponse({}), store: store, auth: (r, s) {
      if (r.path == '/auth/logout') {
        expect(r.headers['Authorization'], 'Bearer access-one');
        revoked = r.data['refreshToken'] as String;
        return jsonResponse({});
      }
      return jsonResponse(sessionData());
    });
    await api.login('test', 'test');
    await api.logout();
    expect(revoked, 'rt1-test-one');
    expect(store.value, isNull);
    expect(api.user, isNull);
    api.dispose();
  });
  test(
      'an offline logout remains local and does not falsely confirm revocation',
      () async {
    final store = MemorySessions();
    final api =
        clientFor((r, s) => jsonResponse({}), store: store, auth: (r, s) {
      if (r.path == '/auth/logout') {
        throw DioException(
            requestOptions: r, type: DioExceptionType.connectionError);
      }
      return jsonResponse(sessionData());
    });
    await api.login('test', 'test');
    await expectLater(api.logout(), throwsA(isA<DioException>()));
    expect(store.value, isNull);
    expect(api.logoutUnconfirmed, isTrue);
    expect(api.status, SessionStatus.signedOut);
    api.dispose();
  });
  test('a late refresh after logout cannot resurrect the stored session',
      () async {
    final pending = Completer<ResponseBody>(), started = Completer<void>();
    final store = MemorySessions();
    final api =
        clientFor((r, s) => jsonResponse({}, 401), store: store, auth: (r, s) {
      if (r.path == '/auth/refresh') {
        started.complete();
        return pending.future;
      }
      return jsonResponse(sessionData());
    });
    await api.login('test', 'test');
    final request = api.getMe();
    final expectation = expectLater(request, throwsA(isA<DioException>()));
    await started.future;
    await api.logout();
    pending.complete(jsonResponse(sessionData(access: 'late')));
    await expectation;
    expect(store.value, isNull);
    expect(api.status, SessionStatus.signedOut);
    api.dispose();
  });
  test(
      'a response from the previous account cannot be consumed by a new account',
      () async {
    final pending = Completer<ResponseBody>(), started = Completer<void>();
    int login = 0;
    final api = clientFor((r, s) {
      started.complete();
      return pending.future;
    }, auth: (r, s) {
      if (r.path == '/auth/login') login++;
      return jsonResponse(sessionData(user: login == 1 ? 'first' : 'second'));
    });
    await api.login('first', 'test');
    final old = api.getMe();
    final expectation = expectLater(old, throwsA(isA<DioException>()));
    await started.future;
    await api.login('second', 'test');
    pending.complete(jsonResponse({'id': 'private-first'}));
    await expectation;
    expect(api.user?['id'], 'second');
    api.dispose();
  });
  test('multipart uploads are rebuilt after a single expired-token response',
      () async {
    int uploads = 0;
    final bodies = <String>[];
    final api = clientFor((r, stream) async {
      uploads++;
      bodies.add(utf8.decode(await stream!.expand((chunk) => chunk).toList()));
      return uploads == 1
          ? jsonResponse({}, 401)
          : jsonResponse({'id': 'uploaded'});
    },
        auth: (r, s) => jsonResponse(sessionData(
            access: r.path == '/auth/refresh' ? 'access-two' : 'access-one')));
    await api.login('test', 'test');
    await api.uploadTranscript(FormData.fromMap({
      'file': MultipartFile.fromBytes(utf8.encode('%PDF-SYNTHETIC'),
          filename: 'releve.pdf'),
      'academicYearId': 'year'
    }));
    expect(uploads, 2);
    expect(
        bodies.every((b) =>
            b.contains('%PDF-SYNTHETIC') && b.contains('academicYearId')),
        isTrue);
    api.dispose();
  });
}
