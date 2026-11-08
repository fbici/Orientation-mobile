import '../../../core/network/api_client.dart';
import '../../../core/models/academic_models.dart';

class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);
  Future<AuthResult> login(String email, String password) async {
    final response = await _api.login(email, password);
    final data = object(response.data);
    return AuthResult(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        user: object(data['user']));
  }

  Future<RegisterResult> register(Json data) async =>
      RegisterResult.fromJson(object((await _api.register(data)).data));
  Future<bool> isLoggedIn() async {
    await _api.restore();
    return _api.status == SessionStatus.authenticated;
  }

  Future<Json> getProfile() async => object((await _api.getMe()).data);
  Future<void> logout() => _api.logout();
}

class AuthResult {
  final String accessToken, refreshToken;
  final Json user;
  AuthResult(
      {required this.accessToken,
      required this.refreshToken,
      required this.user});
}

class RegisterResult {
  final String? userId, email, message;
  RegisterResult({this.userId, this.email, this.message});
  factory RegisterResult.fromJson(Json j) => RegisterResult(
      userId: j['userId'] as String?,
      email: j['email'] as String?,
      message: j['message'] as String?);
}
