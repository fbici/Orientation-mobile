import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Client HTTP pour toutes les appels API
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
      headers: {'Content-Type': 'application/json'},
    ));

    // Intercepteur pour ajouter le token JWT
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Tenter de rafraîchir le token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Réessayer la requête originale
            final token = await _storage.read(key: AppConstants.tokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          }
        }
        handler.next(error);
      },
    ));
  }

  // === AUTH ===
  Future<Response> login(String email, String password) async {
    return _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register(Map<String, dynamic> data) async {
    return _dio.post('/auth/register', data: data);
  }

  Future<Response> getMe() async {
    return _dio.get('/auth/me');
  }

  Future<Response> verifyEmail(String token) async {
    return _dio.get('/auth/verify', queryParameters: {'token': token});
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;
      final response = await _dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      await _storage.write(key: AppConstants.tokenKey, value: response.data['accessToken']);
      await _storage.write(key: AppConstants.refreshTokenKey, value: response.data['refreshToken']);
      return true;
    } catch (e) {
      return false;
    }
  }

  // === UNIVERSITIES ===
  Future<Response> getUniversities({int page = 0, int size = 20}) async {
    return _dio.get('/universities', queryParameters: {'page': page, 'size': size});
  }

  Future<Response> getUniversity(String id) async {
    return _dio.get('/universities/$id');
  }

  // === LOCATIONS ===
  Future<Response> getCountries() async {
    return _dio.get('/locations/countries');
  }

  Future<Response> getCities(String countryId) async {
    return _dio.get('/locations/countries/$countryId/cities');
  }

  // === RECOMMENDATIONS ===
  Future<Response> generateRecommendations(Map<String, dynamic> data) async {
    return _dio.post('/recommendations/generate', data: data);
  }

  Future<Response> getRecommendations({int page = 0, int size = 20}) async {
    return _dio.get('/recommendations', queryParameters: {'page': page, 'size': size});
  }

  // === SMART QUERY ===
  Future<Response> smartQuery(String query) async {
    return _dio.post('/intelligence/smart-query', data: {'query': query});
  }

  // === SCHOLARSHIPS ===
  Future<Response> getScholarships({int page = 0, int size = 20}) async {
    return _dio.get('/scholarships', queryParameters: {'page': page, 'size': size});
  }

  // === TRANSCRIPTS ===
  Future<Response> uploadTranscript(FormData formData) async {
    return _dio.post('/transcripts', data: formData);
  }

  // === GUIDES ===
  Future<Response> getGuides({int page = 0, int size = 20}) async {
    return _dio.get('/guides', queryParameters: {'page': page, 'size': size});
  }

  // === BENIN ORIENTATION ===
  Future<Response> getBeninFilieres({String? serie, String? university}) async {
    final params = <String, dynamic>{};
    if (serie != null) params['serie'] = serie;
    if (university != null) params['university'] = university;
    return _dio.get('/benin/orientation/filieres', queryParameters: params);
  }

  Future<Response> simulateBeninOrientation(Map<String, dynamic> data) async {
    return _dio.post('/benin/orientation/simulate', data: data);
  }

  Future<Response> getBeninUniversites() async {
    return _dio.get('/benin/orientation/universites');
  }

  Future<Response> getBeninSeries() async {
    return _dio.get('/benin/orientation/series');
  }
}
