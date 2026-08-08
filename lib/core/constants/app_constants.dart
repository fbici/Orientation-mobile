/// Constantes de l'application Orientia
class AppConstants {
  // API — Production (Render)
  static const String apiBaseUrl = 'https://orientation-backend-4lcp.onrender.com';
  
  // Pour developpement local (emulateur Android) :
  // static const String apiBaseUrl = 'http://10.0.2.2:8080';

  // Storage keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String onboardingDone = 'onboarding_done';

  // App
  static const String appName = 'Orientia';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int defaultPageSize = 20;

  // Timeouts
  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 60000;
}
