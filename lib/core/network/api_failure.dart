import 'package:dio/dio.dart';

class ApiFailure implements Exception {
  final String message;
  final int? status;
  const ApiFailure(this.message, [this.status]);
  factory ApiFailure.from(Object error) {
    if (error is ApiFailure) return error;
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      final reason = data is Map ? data['message'] : null;
      final code = data is Map ? (data['code'] ?? reason) : null;
      if (status == 503 &&
          reason == 'Email delivery unavailable; no delivery is confirmed') {
        return const ApiFailure(
            'Le service de vérification par e-mail est momentanément indisponible. Votre demande et l’envoi du message n’ont pas pu être confirmés. Réessayez plus tard.',
            503);
      }
      final registration = error.requestOptions.path == '/auth/register';
      if (registration && status != null && status >= 200 && status < 300) {
        return ApiFailure(
            'Le serveur n’a pas confirmé votre demande d’inscription. Consultez vos e-mails avant de réessayer.',
            status);
      }
      final uncertainWrite =
          !['GET', 'HEAD'].contains(error.requestOptions.method.toUpperCase());
      if (status == null &&
          [
            DioExceptionType.connectionTimeout,
            DioExceptionType.sendTimeout,
            DioExceptionType.receiveTimeout,
          ].contains(error.type)) {
        return ApiFailure(uncertainWrite
            ? 'Le délai d’attente a été dépassé. La réception de votre demande n’a pas pu être confirmée. Vérifiez le résultat avant de réessayer.'
            : 'Le délai d’attente a été dépassé. Vérifiez votre connexion puis réessayez.');
      }
      if (code == 'GOOGLE_ACCOUNT_EXISTS') {
        return const ApiFailure(
            'Un compte Orientia existe déjà avec cette adresse. Connectez-vous avec votre mot de passe ; les comptes ne sont pas liés automatiquement.');
      }
      if (code == 'GOOGLE_SIGNIN_UNAVAILABLE') {
        return const ApiFailure(
            'La connexion Google doit encore être activée sur le serveur. Utilisez votre adresse e-mail pour le moment.');
      }
      if (code == 'INVALID_PHONE') {
        return const ApiFailure(
            'Numéro de téléphone invalide. Vérifiez le pays et le numéro saisi.');
      }
      if (reason is String &&
          reason.startsWith('Numéro de téléphone invalide.')) {
        return ApiFailure(reason, status);
      }
      if (code == 'GOOGLE_SIGNIN_RETRY') {
        return const ApiFailure(
            'Une connexion simultanée a été détectée. Réessayez Google.');
      }
      if ((status == 401 || status == 403) &&
          reason is String &&
          reason.contains('EMAIL_NOT_VERIFIED')) {
        return ApiFailure(
            'Veuillez vérifier votre email avant de vous connecter. Consultez aussi les spams.',
            status);
      }
      final message = switch (status) {
        401 => 'Session expirée ou identifiants refusés. Reconnectez-vous.',
        403 =>
          'Accès refusé. Vérifiez aussi que le compte est actif et son email vérifié.',
        409 => 'Le dossier a changé. Rechargez-le avant de sauvegarder.',
        413 => 'Document trop volumineux. Choisissez un fichier plus petit.',
        422 => reason is String
            ? reason
            : 'Données insuffisantes ou scénario non applicable.',
        429 => 'Trop de tentatives. Réessayez plus tard.',
        503 =>
          'Service momentanément indisponible. Aucun envoi ou traitement n’est confirmé.',
        _ => error.type == DioExceptionType.cancel
            ? 'Requête annulée.'
            : status == null
                ? 'Connexion impossible. Vérifiez le réseau puis réessayez.'
                : 'Le serveur n’a pas pu traiter la demande.'
      };
      return ApiFailure(message, status);
    }
    if (error is FormatException || error is ArgumentError) {
      return const ApiFailure(
          'Réponse ou saisie invalide. Vérifiez les informations.');
    }
    return const ApiFailure(
        'Action impossible. Réessayez sans modifier les données confirmées.');
  }
  @override
  String toString() => message;
}
