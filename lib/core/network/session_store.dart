import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

abstract interface class SessionStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  final FlutterSecureStorage storage;
  const SecureSessionStore(
      [this.storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true))]);
  @override
  Future<String?> read() => storage.read(key: AppConstants.sessionKey);
  @override
  Future<void> write(String value) =>
      storage.write(key: AppConstants.sessionKey, value: value);
  @override
  Future<void> clear() async {
    for (final key in [
      AppConstants.sessionKey,
      AppConstants.tokenKey,
      AppConstants.refreshTokenKey,
      AppConstants.userKey,
      AppConstants.onboardingDone
    ]) {
      await storage.delete(key: key);
    }
  }
}
