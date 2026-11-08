import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import 'auth_widgets.dart';

class RecoveryPage extends StatefulWidget {
  final ApiClient apiClient;
  const RecoveryPage({super.key, required this.apiClient});
  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final email = TextEditingController(),
      token = TextEditingController(),
      password = TextEditingController();
  String mode = 'forgot';
  bool busy = false;
  Object? error;
  String? message;
  @override
  void dispose() {
    email.dispose();
    token.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
      message = null;
    });
    try {
      final pasted = token.text.trim();
      final receivedToken =
          Uri.tryParse(pasted)?.queryParameters['token'] ?? pasted;
      switch (mode) {
        case 'forgot':
          if (emailValidator(email.text) != null) {
            throw const FormatException('Email');
          }
          await widget.apiClient.forgotPassword(email.text.trim());
          break;
        case 'reset':
          if (password.text.length < 12 || token.text.trim().isEmpty) {
            throw const FormatException('Token et mot de passe requis');
          }
          await widget.apiClient.resetPassword(receivedToken, password.text);
          break;
        case 'verify':
          if (token.text.trim().isEmpty) {
            throw const FormatException('Token requis');
          }
          await widget.apiClient.verifyEmail(receivedToken);
          break;
      }
      if (mounted) {
        setState(() => message = mode == 'forgot'
            ? 'Demande prise en compte. Si le compte est éligible et la messagerie disponible, consultez votre email.'
            : mode == 'verify'
                ? 'Email vérifié. Vous pouvez vous connecter.'
                : 'Mot de passe modifié. Reconnectez-vous.');
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Récupération et vérification')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        DropdownButtonFormField<String>(
            initialValue: mode,
            items: const [
              DropdownMenuItem(
                  value: 'forgot', child: Text('Recevoir un lien')),
              DropdownMenuItem(
                  value: 'reset',
                  child: Text('Utiliser un lien de réinitialisation')),
              DropdownMenuItem(
                  value: 'verify', child: Text('Vérifier mon email'))
            ],
            onChanged: busy
                ? null
                : (v) => setState(() {
                      mode = v!;
                      error = null;
                      message = null;
                    })),
        if (mode == 'forgot')
          TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email')),
        if (mode != 'forgot')
          TextField(
              controller: token,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Jeton du lien reçu — ne pas partager')),
        if (mode == 'reset')
          TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe — 12 caractères minimum')),
        if (error != null) AuthError(error!),
        if (message != null) Text(message!),
        if (busy) const LinearProgressIndicator(),
        FilledButton(
            onPressed: busy ? null : submit, child: const Text('Valider')),
      ]));
}
