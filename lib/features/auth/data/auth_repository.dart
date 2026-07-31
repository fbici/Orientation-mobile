import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';

/// Repository pour l'authentification
class AuthRepository {
  final ApiClient _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this._api);

  /// Connexion
  Future<AuthResult> login(String email, String password) async {
    final response = await _api.login(email, password);
    final data = response.data;
    
    await _storage.write(key: AppConstants.tokenKey, value: data['accessToken']);
    await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
    await _storage.write(key: AppConstants.userKey, value: data['user'].toString());
    
    return AuthResult(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
      user: Map<String, dynamic>.from(data['user']),
    );
  }

  /// Inscription
  Future<RegisterResult> register(Map<String, dynamic> data) async {
    final response = await _api.register(data);
    return RegisterResult.fromJson(response.data);
  }

  /// Vérifier si connecté
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null;
  }

  /// Obtenir le profil
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _api.getMe();
    return response.data;
  }

  /// Déconnexion
  Future<void> logout() async {
    await _api.logout();
  }
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;

  AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

class RegisterResult {
  final String? userId;
  final String? email;
  final String? message;

  RegisterResult({this.userId, this.email, this.message});

  factory RegisterResult.fromJson(Map<String, dynamic> json) {
    return RegisterResult(
      userId: json['userId'],
      email: json['email'],
      message: json['message'],
    );
  }
}
