import 'dart:convert';
import 'dart:io';
import 'package:orientia/core/constants/api_endpoints.dart';
import 'package:orientia/core/constants/google_oauth.dart';

// Read-only helper: prints a command for a detected phone, never installs an app.
Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help')) {
    stdout.writeln(
        'dart run tool/android_phone_command.dart [--api-url URL_HTTPS] [--device ID] [--google-web-client-id ID_PUBLIC]');
    stdout.writeln(
        'Détecte le téléphone physique et affiche la commande Flutter.');
    return;
  }
  String? requested;
  String? googleClient = Platform.environment['GOOGLE_WEB_CLIENT_ID'];
  if (googleClient == null || googleClient.trim().isEmpty) {
    googleClient = productionGoogleWebClientId;
  }
  String? renderApi = Platform.environment['ORIENTIA_API_URL'];
  if (renderApi == null || renderApi.trim().isEmpty) {
    renderApi = productionApiBaseUrl;
  }
  for (var i = 0; i < arguments.length; i += 2) {
    if (i + 1 >= arguments.length ||
        !['--device', '--api-url', '--google-web-client-id']
            .contains(arguments[i])) {
      stderr.writeln(
          'Options : --api-url URL_HTTPS, --device ID, --google-web-client-id ID_PUBLIC');
      exitCode = 2;
      return;
    }
    if (arguments[i] == '--device') {
      requested = arguments[i + 1];
    } else if (arguments[i] == '--google-web-client-id') {
      googleClient = arguments[i + 1];
    } else {
      renderApi = arguments[i + 1];
    }
  }
  googleClient = googleClient?.trim();
  if (googleClient != null &&
      googleClient.isNotEmpty &&
      !RegExp(r'^[A-Za-z0-9-]+\.apps\.googleusercontent\.com$')
          .hasMatch(googleClient)) {
    stderr.writeln(
        'Identifiant Google public invalide. Utilisez le client de type Application Web.');
    exitCode = 2;
    return;
  }
  final uri = renderApi == null ? null : Uri.tryParse(renderApi);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      !['', '/'].contains(uri.path) ||
      !RegExp(r'^https://[A-Za-z0-9.-]+(?::[0-9]+)?/?$').hasMatch(renderApi!)) {
    stderr.writeln(
        'Indiquez --api-url avec une URL HTTPS racine valide, sans /api/v1.');
    exitCode = 2;
    return;
  }
  try {
    final result = await Process.run('flutter', ['devices', '--machine'],
        runInShell: Platform.isWindows);
    if (result.exitCode != 0) {
      stderr.writeln(
          'La détection Flutter a échoué. Vérifiez Flutter et Android SDK.');
      exitCode = result.exitCode;
      return;
    }
    final devices = (jsonDecode(result.stdout as String) as List)
        .cast<Map<String, dynamic>>()
        .where((device) =>
            device['targetPlatform'].toString().startsWith('android-') &&
            device['emulator'] == false &&
            device['isSupported'] == true)
        .where((device) => requested == null || device['id'] == requested)
        .toList();
    if (devices.length != 1) {
      stderr.writeln(devices.isEmpty
          ? 'Aucun téléphone Android autorisé détecté. Connectez un câble USB de données, activez le débogage USB et autorisez la clé RSA sur le téléphone.'
          : 'Plusieurs téléphones détectés. Relancez avec --device ID après flutter devices.');
      exitCode = 2;
      return;
    }
    final id = devices.single['id'] as String;
    if (!RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(id)) {
      stderr.writeln('Identifiant inattendu : consultez flutter devices.');
      exitCode = 2;
      return;
    }
    stdout.writeln('Téléphone : ${devices.single['name']}');
    stdout.writeln('Identifiant Android conservé : com.orientia.orientia');
    stdout.writeln('Backend HTTPS : $renderApi');
    if (googleClient == null || googleClient.isEmpty) {
      stdout.writeln(
          'Google : identifiant Web non fourni ; la connexion par e-mail reste disponible.');
    }
    stdout.writeln('Commande à lancer dans le terminal VS Code :');
    stdout.writeln('flutter run -d "$id" --dart-define=APP_ENV=production '
        '--dart-define=API_BASE_URL=$renderApi'
        '${googleClient == null || googleClient.isEmpty ? '' : ' --dart-define=GOOGLE_WEB_CLIENT_ID=$googleClient'}');
  } on Object {
    stderr.writeln(
        'Impossible de lire les appareils. Exécutez flutter devices et adb devices -l.');
    exitCode = 2;
  }
}
