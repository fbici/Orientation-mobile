import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../models/academic_models.dart';
import 'session_store.dart';

enum SessionStatus { restoring, signedOut, authenticated, unavailable }

class ApiClient extends ChangeNotifier {
  final Dio _dio, _auth;
  final SessionStore store;
  Json? _session;
  int _epoch = 0;
  bool _closed = false;
  bool logoutUnconfirmed = false;
  void _announce() {
    if (!_closed) notifyListeners();
  }

  Future<bool>? _refreshing;
  Future<void> _writes = Future.value();
  CancelToken _cancel = CancelToken();
  SessionStatus status = SessionStatus.restoring;
  ApiClient({Dio? dio, Dio? authDio, SessionStore? storage, String? baseUrl})
      : _dio = dio ?? Dio(),
        _auth = authDio ?? Dio(),
        store = storage ?? const SecureSessionStore() {
    final url = AppConstants.validateBaseUrl(baseUrl ?? AppConstants.apiBaseUrl)
        .toString();
    for (final transport in [_dio, _auth]) {
      transport.options = BaseOptions(
          baseUrl: url,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 90),
          headers: {'Accept': 'application/json'});
    }
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (options.extra['epoch'] != _epoch) {
        handler.reject(_obsolete(options));
        return;
      }
      if (_session != null) {
        options.headers['Authorization'] = 'Bearer ${_session!['accessToken']}';
      }
      handler.next(options);
    }, onResponse: (response, handler) {
      if (response.requestOptions.extra['epoch'] != _epoch) {
        handler.reject(_obsolete(response.requestOptions));
        return;
      }
      handler.next(response);
    }, onError: (error, handler) async {
      final request = error.requestOptions,
          epoch = requestEpoch(error.requestOptions);
      if (epoch != _epoch) {
        handler.reject(_obsolete(request));
        return;
      }
      if (error.response?.statusCode != 401 ||
          request.extra['retried'] == true ||
          _session == null) {
        if (error.response?.statusCode == 401 &&
            request.extra['retried'] == true) {
          await _invalidate(epoch);
        }
        handler.next(error);
        return;
      }
      try {
        final old = request.headers['Authorization'];
        final ready = old != 'Bearer ${_session!['accessToken']}' ||
            await _refresh(epoch);
        if (!ready || epoch != _epoch) {
          handler.next(error);
          return;
        }
        request.extra['retried'] = true;
        if (request.data is FormData) {
          request.data = (request.data as FormData).clone();
        }
        final response = await _dio.fetch<dynamic>(request);
        handler.resolve(response);
      } on DioException catch (e) {
        handler.next(e);
      } catch (_) {
        handler.next(error);
      }
    }));
  }
  int requestEpoch(RequestOptions options) =>
      options.extra['epoch'] as int? ?? -1;
  int get sessionEpoch => _epoch;
  Json? get user => _session?['user'] is Map ? object(_session!['user']) : null;
  DioException _obsolete(RequestOptions r) => DioException(
      requestOptions: r,
      type: DioExceptionType.cancel,
      message: 'Session changée');
  Future<void> _serial(Future<void> Function() operation) {
    final next = _writes.then((_) => operation());
    _writes = next.catchError((Object _) {});
    return next;
  }

  void _resetMemory({bool cancelRequests = true}) {
    _epoch++;
    if (cancelRequests) _cancel.cancel();
    _cancel = CancelToken();
    _session = null;
    _refreshing = null;
    status = SessionStatus.signedOut;
    _announce();
  }

  Future<void> _invalidate(int epoch) async {
    if (epoch != _epoch) return;
    final previousRequests = _cancel;
    _resetMemory(cancelRequests: false);
    try {
      await _serial(store.clear);
    } finally {
      previousRequests.cancel();
    }
  }

  bool _persistSession = true;

  Future<void> _accept(Json data, int epoch) async {
    if (data['accessToken'] is! String ||
        data['refreshToken'] is! String ||
        data['user'] is! Map) {
      throw const FormatException('Session invalide');
    }
    await _serial(() async {
      if (epoch == _epoch) {
        if (_persistSession) {
          await store.write(jsonEncode(data));
        } else {
          await store.clear();
        }
      }
    });
    if (epoch != _epoch) throw StateError('Session changée');
    _session = data;
    status = SessionStatus.authenticated;
    _announce();
  }

  Future<void> restore() async {
    final epoch = _epoch;
    status = SessionStatus.restoring;
    _announce();
    try {
      final saved = await store.read();
      if (epoch != _epoch) return;
      if (saved == null) {
        await _invalidate(epoch);
        return;
      }
      final data = object(jsonDecode(saved));
      if (data['accessToken'] is! String || data['refreshToken'] is! String) {
        throw const FormatException('Session');
      }
      _session = data;
      final me = await getMe();
      if (epoch != _epoch && status != SessionStatus.authenticated) return;
      _session?['user'] = object(me.data);
      status = SessionStatus.authenticated;
      _announce();
    } on DioException catch (e) {
      if (epoch != _epoch) return;
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await _invalidate(epoch);
      } else {
        status = SessionStatus.unavailable;
        _announce();
      }
    } catch (_) {
      await _invalidate(epoch);
    }
  }

  Future<Response<dynamic>> login(String email, String password,
      {bool rememberMe = true}) async {
    _resetMemory();
    logoutUnconfirmed = false;
    _persistSession = rememberMe;
    final epoch = _epoch;
    await _serial(store.clear);
    final response = await _auth.post<dynamic>('/auth/login',
        data: {'email': email, 'password': password});
    await _accept(object(response.data), epoch);
    return response;
  }

  Future<bool> _refresh(int epoch) {
    return _refreshing ??= _performRefresh(epoch).whenComplete(() {
      if (epoch == _epoch) _refreshing = null;
    });
  }

  Future<bool> _performRefresh(int epoch) async {
    final refresh = _session?['refreshToken'];
    if (refresh == null) return false;
    try {
      final response = await _auth
          .post<dynamic>('/auth/refresh', data: {'refreshToken': refresh});
      if (epoch != _epoch) return false;
      final next = object(response.data);
      if (object(next['user'])['id'] != user?['id']) {
        await _invalidate(epoch);
        return false;
      }
      await _accept(next, epoch);
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await _invalidate(epoch);
      }
      rethrow;
    } catch (_) {
      await _invalidate(epoch);
      return false;
    }
  }

  Future<void> logout() async {
    final previous = _session;
    _resetMemory();
    final epoch = _epoch;
    await _serial(store.clear);
    if (previous == null) return;
    try {
      var pair = previous;
      Future<void> revoke() async {
        await _auth.post<dynamic>('/auth/logout',
            data: {'refreshToken': pair['refreshToken']},
            options: Options(
                headers: {'Authorization': 'Bearer ${pair['accessToken']}'}));
      }

      try {
        await revoke();
      } on DioException catch (e) {
        if (e.response?.statusCode != 401) rethrow;
        final rotated = await _auth.post<dynamic>('/auth/refresh',
            data: {'refreshToken': pair['refreshToken']});
        pair = object(rotated.data);
        await revoke();
      }
    } catch (_) {
      if (epoch == _epoch) {
        logoutUnconfirmed = true;
        _announce();
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> call(String path,
      {String method = 'GET',
      Object? data,
      Json? query,
      ResponseType? responseType,
      ProgressCallback? onSendProgress}) {
    return _dio.request<dynamic>(path,
        data: data,
        queryParameters: query,
        options: Options(
            method: method,
            responseType: responseType,
            extra: {'epoch': _epoch}),
        cancelToken: _cancel,
        onSendProgress: onSendProgress);
  }

  Future<Response<dynamic>> register(Json data) =>
      _auth.post('/auth/register', data: data);
  Future<Response<dynamic>> forgotPassword(String email) =>
      _auth.post('/auth/forgot-password', data: {'email': email});
  Future<Response<dynamic>> resetPassword(String token, String password) =>
      _auth.post('/auth/reset-password',
          data: {'token': token, 'newPassword': password});
  Future<Response<dynamic>> verifyEmail(String token) =>
      _auth.get('/auth/verify', queryParameters: {'token': token});
  Future<Response<dynamic>> getMe() => call('/auth/me');
  Future<Response<dynamic>> updateMe(Json data) =>
      call('/auth/me', method: 'PUT', data: data);
  Future<Response<dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    final epoch = _epoch;
    final response = await call('/auth/me/password',
        method: 'PUT',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword});
    await _invalidate(epoch);
    return response;
  }

  Future<Response<dynamic>> getCountries() => call('/locations/countries');
  Future<Response<dynamic>> getCities(String id) =>
      call('/locations/countries/$id/cities');
  Future<Response<dynamic>> getAllCities() => call('/locations/cities');
  Future<Response<dynamic>> getCandidateProfile() =>
      call('/candidates/me/academic-profile');
  Future<Response<dynamic>> updateCandidateProfile(Json data) =>
      call('/candidates/me/academic-profile', method: 'PUT', data: data);
  Future<Response<dynamic>> getUniversities(
          {int page = 0, int size = 20, String? search}) =>
      catalog('universities',
          page: page,
          size: size,
          filters: {if (search != null) 'search': search});
  Future<Response<dynamic>> getUniversity(String id) =>
      call('/universities/$id');
  Future<Response<dynamic>> getPrograms(
          {int page = 0, int size = 20, String? search}) =>
      catalog('programs',
          page: page,
          size: size,
          filters: {if (search != null) 'search': search});
  Future<Response<dynamic>> getProgram(String id) => call('/programs/$id');
  Future<Response<dynamic>> catalog(String resource,
          {int page = 0, int size = 20, Json filters = const {}}) =>
      call('/$resource', query: {...filters, 'page': page, 'size': size});
  Future<Response<dynamic>> getTranscripts({int page = 0, int size = 20}) =>
      catalog('transcripts', page: page, size: size);
  Future<Response<dynamic>> uploadTranscript(FormData data,
          {ProgressCallback? onProgress}) =>
      call('/transcripts',
          method: 'POST', data: data, onSendProgress: onProgress);
  Future<Response<dynamic>> getDocuments({int page = 0, int size = 20}) =>
      getTranscripts(page: page, size: size);
  Future<Response<dynamic>> getDocument(String id) => call('/transcripts/$id');
  Future<Response<dynamic>> uploadDocument(FormData data) =>
      uploadTranscript(data);
  Future<Response<dynamic>> generateRecommendations(Json data) =>
      call('/recommendations/generate', method: 'POST', data: data);
  Future<Response<dynamic>> getRecommendations({int page = 0, int size = 20}) =>
      catalog('recommendations', page: page, size: size);
  Future<Response<dynamic>> getRecommendationScores(String id) =>
      call('/recommendations/$id/scores');
  Future<Response<dynamic>> getRecommendationExplanation(String id) =>
      call('/recommendations/$id/explanation');
  Future<Response<dynamic>> simulateRecommendation(Json data) =>
      call('/recommendations/simulate', method: 'POST', data: data);
  Future<Response<dynamic>> getScholarships({int page = 0, int size = 20}) =>
      catalog('scholarships', page: page, size: size);
  Future<Response<dynamic>> getScholarship(String id) =>
      call('/scholarships/$id');
  Future<Response<dynamic>> getGuides({int page = 0, int size = 20}) =>
      catalog('guides', page: page, size: size);
  Future<Response<dynamic>> getGuide(String id) => call('/guides/$id');
  Future<Response<dynamic>> createChatSession() =>
      call('/ai/chat/sessions', method: 'POST');
  Future<Response<dynamic>> sendChatMessage(String id, String message,
          {Json parameters = const {}}) =>
      call('/ai/chat/sessions/$id/messages',
          method: 'POST', data: {...parameters, 'message': message});
  Future<Response<dynamic>> getChatSession(String id) =>
      call('/ai/chat/sessions/$id');
  Future<Response<dynamic>> comparePrograms(List<String> ids) =>
      call('/ai/compare/programs', method: 'POST', data: {'programIds': ids});
  Future<Response<dynamic>> knowledgeSearch(String query) =>
      call('/knowledge/search', query: {'query': query, 'limit': 20});
  Future<Response<dynamic>> exportPdf(String id) =>
      call('/ai/export/pdf/$id', responseType: ResponseType.bytes);
  Future<Response<dynamic>> exportExcel(String id) =>
      call('/ai/export/excel/$id', responseType: ResponseType.bytes);
  @override
  void dispose() {
    _closed = true;
    _epoch++;
    _cancel.cancel();
    _dio.close(force: true);
    _auth.close(force: true);
    super.dispose();
  }
}
