import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/core/constants/app_constants.dart';
import 'package:orientia/core/constants/google_oauth.dart';
import 'package:orientia/features/auth/data/google_identity.dart';

void main() {
  test(
      'production uses the owner supplied Web audience, preserving overrides and local setup',
      () {
    const override = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    if (override.isNotEmpty) {
      expect(googleWebClientId, override);
    } else if (AppConstants.environment == 'production') {
      expect(googleWebClientId,
          '1048361062873-j7dmfajmue27jhbs1ms7jmbpnpa5pcp3.apps.googleusercontent.com');
    } else {
      expect(googleWebClientId, isEmpty);
    }
    expect(
        productionGoogleWebClientId,
        isNot(
            '1048361062873-9p9jrn2umec435bddqen2epn6fur93d8.apps.googleusercontent.com'));
  });
}
