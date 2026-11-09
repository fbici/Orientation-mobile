import 'package:flutter/foundation.dart';
import 'api_endpoints.dart' as endpoints;

class AppConstants {
  static const environment =
      String.fromEnvironment('APP_ENV', defaultValue: 'development');
  static const productionApiBaseUrl = endpoints.productionApiBaseUrl;
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: environment == 'production'
          ? endpoints.productionApiBaseUrl
          : endpoints.localApiBaseUrl);
  static const tokenKey = 'access_token',
      refreshTokenKey = 'refresh_token',
      userKey = 'user_data',
      onboardingDone = 'onboarding_done';
  static const sessionKey = 'orientia.session.v2';
  static const connectTimeoutMs = 15000,
      receiveTimeoutMs = 90000,
      defaultPageSize = 20;
  static const appName = 'Orientia', appVersion = '1.0.0';
  static Uri validateBaseUrl(String value,
      {bool release = kReleaseMode, String env = environment}) {
    final uri = Uri.parse(value);
    if (!uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !['http', 'https'].contains(uri.scheme)) {
      throw ArgumentError('URL API invalide.');
    }
    if ((release || env == 'production') && uri.scheme != 'https') {
      throw ArgumentError('HTTPS obligatoire en production.');
    }
    if (uri.host == Uri.parse(productionApiBaseUrl).host &&
        !['', '/'].contains(uri.path)) {
      throw ArgumentError(
          'Le backend Render de production expose les API à la racine, sans /api/v1.');
    }
    final octets = uri.host.split('.').map(int.tryParse).toList();
    final ipv4 = octets.length == 4 &&
        uri.host == octets.join('.') &&
        octets.every((n) => n != null && n >= 0 && n <= 255);
    final privateAddress = ipv4 &&
        (octets[0] == 10 ||
            octets[0] == 192 && octets[1] == 168 ||
            octets[0] == 172 && octets[1]! >= 16 && octets[1]! <= 31);
    if (uri.scheme == 'http' &&
        !(uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            privateAddress)) {
      throw ArgumentError('HTTP réservé au réseau local de développement.');
    }
    return uri.replace(path: uri.path.replaceFirst(RegExp(r'/+$'), ''));
  }
}
