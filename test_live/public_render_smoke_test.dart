import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/core/constants/api_endpoints.dart';
import 'package:orientia/core/network/api_client.dart';
import '../test/support/fake_transport.dart' show MemorySessions;

// Explicit opt-in. Only public GET endpoints, with no account or token.
void main() {
  test('real HTTPS health and public countries through the mobile API client',
      () async {
    final storage = MemorySessions();
    final api = ApiClient(baseUrl: productionApiBaseUrl, storage: storage);
    addTearDown(api.dispose);
    final health = await api.call('/actuator/health');
    expect(health.statusCode, 200);
    expect(health.data['status'], 'UP');
    final countries = await api.getCountries();
    expect(countries.statusCode, 200);
    expect(countries.data, isA<List>());
    for (final country in countries.data as List) {
      expect(country['id'], isA<String>());
      expect(country['name'], isA<String>());
    }
    expect(api.user, isNull);
    expect(storage.value, isNull);
  },
      skip: !const bool.fromEnvironment('ORIENTIA_PUBLIC_SMOKE'),
      timeout: const Timeout(Duration(minutes: 2)));
}
