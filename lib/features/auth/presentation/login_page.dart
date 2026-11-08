import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import 'auth_widgets.dart';
import '../../../core/widgets/academic_widgets.dart';
import 'recovery_page.dart';

class LoginPage extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onLoginSuccess;
  final VoidCallback? onRegister;
  const LoginPage(
      {super.key,
      required this.apiClient,
      required this.onLoginSuccess,
      this.onRegister});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>(),
      email = TextEditingController(),
      password = TextEditingController();
  bool busy = false, show = false;
  Object? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (form.currentState?.validate() != true) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.apiClient.login(email.text.trim(), password.text);
      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      AuthShell(title: 'Bienvenue sur Orientia', children: [
        if (widget.apiClient.logoutUnconfirmed)
          const Notice(
              'Session locale effac?e. La r?vocation c?t? serveur n?a pas pu ?tre confirm?e.',
              warning: true),
        Form(
            key: form,
            child: AutofillGroup(
                child: Column(children: [
              TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: emailValidator),
              const SizedBox(height: 16),
              TextFormField(
                  controller: password,
                  obscureText: !show,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      suffixIcon: IconButton(
                          onPressed: () => setState(() => show = !show),
                          icon: Icon(
                              show ? Icons.visibility_off : Icons.visibility),
                          tooltip: 'Afficher ou masquer le mot de passe')),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Mot de passe requis.' : null,
                  onFieldSubmitted: (_) {
                    if (!busy) login();
                  }),
            ]))),
        if (error != null) AuthError(error!),
        if (busy) const LinearProgressIndicator(),
        const SizedBox(height: 20),
        FilledButton(
            onPressed: busy ? null : login, child: const Text('Se connecter')),
        TextButton(
            onPressed: busy ? null : widget.onRegister,
            child: const Text('Créer un compte')),
        TextButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => RecoveryPage(apiClient: widget.apiClient))),
            child: const Text('Mot de passe oublié ou email à vérifier')),
      ]);
}
