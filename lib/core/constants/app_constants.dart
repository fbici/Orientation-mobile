/// Constantes de l'application Orientation
class AppConstants {
  // API
  static const String apiBaseUrl = 'http://10.0.2.2:8080/api/v1'; // Android emulator
  static const String apiBaseUrlWeb = 'http://localhost:8080/api/v1';
  
  // Storage keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  
  // App
  static const String appName = 'Orientation';
  static const String appVersion = '1.0.0';
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Timeouts
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 30000;
}
