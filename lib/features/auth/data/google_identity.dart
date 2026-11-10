import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/network/api_failure.dart';

// Public server audience. The Android package/SHA OAuth client remains registered
// in Google Cloud; its ID must not be substituted for this server audience.
const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

abstract interface class GoogleIdentityProvider {
  Future<String?> authenticate();
}

class AndroidGoogleIdentity implements GoogleIdentityProvider {
  static Future<void>? _initialization;
  @override
  Future<String?> authenticate() async {
    if (googleWebClientId.isEmpty) {
      throw const ApiFailure(
          'La connexion Google n’est pas encore configurée pour cette version. Vous pouvez utiliser votre adresse e-mail.');
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const ApiFailure(
          'Cette connexion Google est disponible dans l’application Android.');
    }
    try {
      await (_initialization ??=
          GoogleSignIn.instance.initialize(serverClientId: googleWebClientId));
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw const ApiFailure(
            'Google n’a pas fourni de jeton de connexion. Réessayez.');
      }
      return token;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw const ApiFailure(
          'Connexion Google impossible. Vérifiez le réseau et la configuration de cette version.');
    }
  }
}
