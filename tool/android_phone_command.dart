import 'dart:convert';
import 'dart:io';

// Read-only helper: prints a command for a detected phone, never installs an app.
Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help')) {
    stdout.writeln(
        'dart run tool/android_phone_command.dart --api-url URL_HTTPS [--device ID]');
    stdout.writeln(
        'Détecte le téléphone physique et affiche la commande Flutter.');
    return;
  }
  String? requested;
  String? renderApi;
  for (var i = 0; i < arguments.length; i += 2) {
    if (i + 1 >= arguments.length ||
        !['--device', '--api-url'].contains(arguments[i])) {
      stderr.writeln('Options attendues : --api-url URL_HTTPS [--device ID]');
      exitCode = 2;
      return;
    }
    if (arguments[i] == '--device') {
      requested = arguments[i + 1];
    } else {
      renderApi = arguments[i + 1];
    }
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
        'Indiquez --api-url avec la véritable URL HTTPS racine du nouveau backend Render. L’ancien service a été supprimé.');
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
    stdout.writeln(
        'Le backend F1–F3.2 doit être déployé après validation Render.');
    stdout.writeln('Commande à lancer dans le terminal VS Code :');
    stdout.writeln('flutter run -d "$id" --dart-define=APP_ENV=development '
        '--dart-define=API_BASE_URL=$renderApi');
  } on Object {
    stderr.writeln(
        'Impossible de lire les appareils. Exécutez flutter devices et adb devices -l.');
    exitCode = 2;
  }
}
