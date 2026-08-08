import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Client HTTP pour toutes les appels API Orientia
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
          final refreshed = await _refreshToken();
          if (refreshed) {
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

  // ═══════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════
  Future<Response> login(String email, String password) async {
    return _dio.post('/auth/login', data: {'email': email, 'password': password});
  }

  Future<Response> register(Map<String, dynamic> data) async {
    return _dio.post('/auth/register', data: data);
  }

  Future<Response> getMe() async {
    return _dio.get('/auth/me');
  }

  Future<Response> updateMe(Map<String, dynamic> data) async {
    return _dio.put('/auth/me', data: data);
  }

  Future<Response> changePassword(String oldPassword, String newPassword) async {
    return _dio.put('/auth/me/password', data: {'oldPassword': oldPassword, 'newPassword': newPassword});
  }

  Future<Response> forgotPassword(String email) async {
    return _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<Response> resetPassword(String token, String password) async {
    return _dio.post('/auth/reset-password', data: {'token': token, 'password': password});
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
      final response = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      await _storage.write(key: AppConstants.tokenKey, value: response.data['accessToken']);
      await _storage.write(key: AppConstants.refreshTokenKey, value: response.data['refreshToken']);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════
  // LOCATIONS
  // ═══════════════════════════════════════
  Future<Response> getCountries() async {
    return _dio.get('/locations/countries');
  }

  Future<Response> getCities(String countryId) async {
    return _dio.get('/locations/countries/$countryId/cities');
  }

  Future<Response> getAllCities() async {
    return _dio.get('/locations/cities');
  }

  // ═══════════════════════════════════════
  // UNIVERSITIES
  // ═══════════════════════════════════════
  Future<Response> getUniversities({int page = 0, int size = 20, String? search}) async {
    final params = {'page': page, 'size': size};
    if (search != null) params['search'] = search;
    return _dio.get('/universities', queryParameters: params);
  }

  Future<Response> getUniversity(String id) async {
    return _dio.get('/universities/$id');
  }

  // ═══════════════════════════════════════
  // PROGRAMS
  // ═══════════════════════════════════════
  Future<Response> getPrograms({int page = 0, int size = 20, String? search}) async {
    final params = {'page': page, 'size': size};
    if (search != null) params['search'] = search;
    return _dio.get('/programs', queryParameters: params);
  }

  Future<Response> getProgram(String id) async {
    return _dio.get('/programs/$id');
  }

  // ═══════════════════════════════════════
  // CANDIDATES / PROFILE
  // ═══════════════════════════════════════
  Future<Response> getCandidateProfile() async {
    return _dio.get('/candidates/me');
  }

  Future<Response> updateCandidateProfile(Map<String, dynamic> data) async {
    return _dio.put('/candidates/me', data: data);
  }

  // ═══════════════════════════════════════
  // DOCUMENTS / TRANSCRIPTS
  // ═══════════════════════════════════════
  Future<Response> uploadDocument(FormData formData) async {
    return _dio.post('/documents', data: formData);
  }

  Future<Response> getDocuments({int page = 0, int size = 20}) async {
    return _dio.get('/documents', queryParameters: {'page': page, 'size': size});
  }

  Future<Response> getDocument(String id) async {
    return _dio.get('/documents/$id');
  }

  Future<Response> getDocumentExtractions(String id) async {
    return _dio.get('/documents/$id/extractions');
  }

  Future<Response> uploadTranscript(FormData formData) async {
    return _dio.post('/transcripts', data: formData);
  }

  Future<Response> getTranscripts({int page = 0, int size = 20}) async {
    return _dio.get('/transcripts', queryParameters: {'page': page, 'size': size});
  }

  // ═══════════════════════════════════════
  // RECOMMENDATIONS
  // ═══════════════════════════════════════
  Future<Response> generateRecommendations(Map<String, dynamic> data) async {
    return _dio.post('/recommendations/generate', data: data);
  }

  Future<Response> getRecommendations({int page = 0, int size = 20}) async {
    return _dio.get('/recommendations', queryParameters: {'page': page, 'size': size});
  }

  Future<Response> getRecommendationScores(String id) async {
    return _dio.get('/recommendations/$id/scores');
  }

  Future<Response> getRecommendationExplanation(String id) async {
    return _dio.get('/recommendations/$id/explanation');
  }

  Future<Response> simulateRecommendation(Map<String, dynamic> data) async {
    return _dio.post('/recommendations/simulate', data: data);
  }

  Future<Response> getRecommendationDashboard() async {
    return _dio.get('/recommendations/dashboard');
  }

  // ═══════════════════════════════════════
  // SCHOLARSHIPS
  // ═══════════════════════════════════════
  Future<Response> getScholarships({int page = 0, int size = 20}) async {
    return _dio.get('/scholarships', queryParameters: {'page': page, 'size': size});
  }

  Future<Response> getScholarship(String id) async {
    return _dio.get('/scholarships/$id');
  }

  // ═══════════════════════════════════════
  // GUIDES
  // ═══════════════════════════════════════
  Future<Response> getGuides({int page = 0, int size = 20}) async {
    return _dio.get('/guides', queryParameters: {'page': page, 'size': size});
  }

  Future<Response> getGuide(String id) async {
    return _dio.get('/guides/$id');
  }

  // ═══════════════════════════════════════
  // INTELLIGENCE / SMART QUERY
  // ═══════════════════════════════════════
  Future<Response> smartQuery(String query) async {
    return _dio.post('/intelligence/smart-query', data: {'query': query});
  }

  Future<Response> processDocument(FormData formData) async {
    return _dio.post('/intelligence/process', data: formData);
  }

  Future<Response> submitFeedback(Map<String, dynamic> data) async {
    return _dio.post('/intelligence/feedback', data: data);
  }

  // ═══════════════════════════════════════
  // KNOWLEDGE ENGINE
  // ═══════════════════════════════════════
  Future<Response> knowledgeQuery(String query) async {
    return _dio.post('/knowledge/query', data: {'query': query});
  }

  Future<Response> knowledgeSearch(String query) async {
    return _dio.get('/knowledge/search', queryParameters: {'q': query});
  }

  Future<Response> knowledgeSimilar(String nodeId) async {
    return _dio.get('/knowledge/similar', queryParameters: {'nodeId': nodeId});
  }

  // ═══════════════════════════════════════
  // CHAT IA
  // ═══════════════════════════════════════
  Future<Response> createChatSession() async {
    return _dio.post('/ai/chat/sessions');
  }

  Future<Response> sendChatMessage(String sessionId, String message) async {
    return _dio.post('/ai/chat/sessions/$sessionId/messages', data: {'content': message});
  }

  Future<Response> getChatSession(String sessionId) async {
    return _dio.get('/ai/chat/sessions/$sessionId');
  }

  // ═══════════════════════════════════════
  // COMPARISON
  // ═══════════════════════════════════════
  Future<Response> comparePrograms(List<String> programIds) async {
    return _dio.post('/ai/compare/programs', data: {'programIds': programIds});
  }

  Future<Response> compareUniversities(List<String> universityIds) async {
    return _dio.post('/ai/compare/universities', data: {'universityIds': universityIds});
  }

  // ═══════════════════════════════════════
  // BENIN ORIENTATION
  // ═══════════════════════════════════════
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

  // ═══════════════════════════════════════
  // EXPORTS
  // ═══════════════════════════════════════
  Future<Response> exportPdf(String id) async {
    return _dio.get('/ai/export/pdf/$id');
  }

  Future<Response> exportExcel(String id) async {
    return _dio.get('/ai/export/excel/$id');
  }

  // ═══════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════
  Future<Response> getNotifications({int page = 0, int size = 50}) async {
    return _dio.get('/notifications', queryParameters: {'page': page, 'size': size});
  }

  Future<Response> markNotificationRead(String id) async {
    return _dio.put('/notifications/$id/read');
  }

  Future<Response> markAllNotificationsRead() async {
    return _dio.put('/notifications/read-all');
  }
}
