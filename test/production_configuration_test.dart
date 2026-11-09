import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/core/constants/api_endpoints.dart';
import 'package:orientia/core/constants/app_constants.dart';
import 'package:orientia/core/network/api_client.dart';
import 'support/fake_transport.dart';

void main() {
  test('environment selects production without changing local development', () {
    expect(
        AppConstants.apiBaseUrl,
        AppConstants.environment == 'production'
            ? productionApiBaseUrl
            : localApiBaseUrl);
    expect(
        AppConstants.validateBaseUrl(localApiBaseUrl,
                release: false, env: 'development')
            .path,
        '/api/v1');
  });

  test('the deployed Render service accepts only its HTTPS root', () {
    expect(
        AppConstants.validateBaseUrl('$productionApiBaseUrl/',
                release: true, env: 'production')
            .toString(),
        productionApiBaseUrl);
    for (final suffix in ['/api/v1', '/api/v1/api/v1', '/auth/login']) {
      expect(() => AppConstants.validateBaseUrl('$productionApiBaseUrl$suffix'),
          throwsArgumentError);
    }
  });

  test('production login refresh and protected requests keep the root contract',
      () async {
    final authCalls = <String>[];
    final auth = Dio()
      ..httpClientAdapter = TestTransport((r, _) {
        expect(r.uri.origin, productionApiBaseUrl);
        authCalls.add('${r.method} ${r.uri.path}');
        if (r.uri.path == '/auth/refresh') {
          expect(r.data, {'refreshToken': 'rt1-test-one'});
          return jsonResponse(
              sessionData(access: 'new-access', refresh: 'new-refresh'));
        }
        expect(r.data, {'email': 'test', 'password': 'test'});
        return jsonResponse(sessionData());
      });
    final business = Dio()
      ..httpClientAdapter = TestTransport((r, _) {
        expect(r.uri.toString(), '$productionApiBaseUrl/auth/me');
        if (r.headers['Authorization'] == 'Bearer access-one') {
          return jsonResponse({}, 401);
        }
        expect(r.headers['Authorization'], 'Bearer new-access');
        return jsonResponse(sessionData()['user']);
      });
    final api = ApiClient(
        dio: business,
        authDio: auth,
        storage: MemorySessions(),
        baseUrl: productionApiBaseUrl);
    addTearDown(api.dispose);
    await api.login('test', 'test');
    await api.getMe();
    expect(authCalls, ['POST /auth/login', 'POST /auth/refresh']);
    expect(api.status, SessionStatus.authenticated);
  });
}
