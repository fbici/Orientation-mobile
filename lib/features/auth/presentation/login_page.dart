import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import 'auth_widgets.dart';
import '../../../core/widgets/academic_widgets.dart';
import 'recovery_page.dart';
import '../data/google_identity.dart';

class LoginPage extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onLoginSuccess;
  final VoidCallback? onRegister;
  final VoidCallback? onIntroduction;
  final GoogleIdentityProvider? googleIdentity;
  const LoginPage(
      {super.key,
      required this.apiClient,
      required this.onLoginSuccess,
      this.onRegister,
      this.onIntroduction,
      this.googleIdentity});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>(),
      email = TextEditingController(),
      password = TextEditingController();
  bool busy = false, show = false, remember = true, usingGoogle = false;
  Object? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (busy || form.currentState?.validate() != true) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.apiClient
          .login(email.text.trim(), password.text, rememberMe: remember);
      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> googleLogin() async {
    if (busy) return;
    setState(() {
      busy = true;
      usingGoogle = true;
      error = null;
    });
    try {
      final token = await (widget.googleIdentity ?? AndroidGoogleIdentity())
          .authenticate();
      if (token == null) return;
      await widget.apiClient.loginWithGoogle(token, rememberMe: remember);
      if (mounted) widget.onLoginSuccess();
    } catch (failure) {
      if (mounted) setState(() => error = failure);
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          usingGoogle = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AuthShell(
          title: 'Connexion',
          subtitle: 'Accédez à votre espace Orientia',
          children: [
            if (widget.apiClient.logoutUnconfirmed)
              const Notice(
                  'Session locale effacée. La révocation côté serveur n’a pas pu être confirmée.',
                  warning: true),
            Form(
                key: form,
                child: AutofillGroup(
                    child: Column(children: [
                  AuthField(
                      child: TextFormField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                              hintText: 'Votre adresse e-mail',
                              prefixIcon: Icon(Icons.mail_outline_rounded)),
                          validator: emailValidator)),
                  const SizedBox(height: 16),
                  AuthField(
                      child: TextFormField(
                          controller: password,
                          obscureText: !show,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                              hintText: 'Votre mot de passe',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                  onPressed: () => setState(() => show = !show),
                                  icon: Icon(show
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  tooltip:
                                      'Afficher ou masquer le mot de passe')),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Mot de passe requis.'
                              : null,
                          onFieldSubmitted: (_) {
                            if (!busy) login();
                          })),
                ]))),
            if (error != null) AuthError(error!),
            const SizedBox(height: 10),
            Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Checkbox(
                        value: remember,
                        activeColor: authPurple,
                        onChanged: busy
                            ? null
                            : (value) =>
                                setState(() => remember = value ?? true)),
                    const Flexible(
                        child: Text('Se souvenir de moi',
                            style: TextStyle(fontSize: 12, color: authInk))),
                  ]),
                  TextButton(
                      onPressed: busy
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => RecoveryPage(
                                      apiClient: widget.apiClient))),
                      child: const Text('Mot de passe oublié ?',
                          style: TextStyle(
                              fontSize: 12,
                              color: authPurple,
                              decoration: TextDecoration.underline))),
                ]),
            const SizedBox(height: 26),
            AuthActionButton(
                label: 'Se connecter',
                pendingLabel: 'Connexion en cours…',
                busy: busy && !usingGoogle,
                onPressed: busy ? null : login),
            const SizedBox(height: 30),
            const Row(children: [
              Expanded(child: Divider(color: Color(0xffc8bfde))),
              Flexible(
                  flex: 4,
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('Ou continuer avec',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: authInk)))),
              Expanded(child: Divider(color: Color(0xffc8bfde)))
            ]),
            const SizedBox(height: 18),
            GoogleAuthButton(
                onPressed: busy ? null : googleLogin,
                busy: busy && usingGoogle),
            const SizedBox(height: 26),
            Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Pas encore de compte ?',
                      style: TextStyle(color: authInk, fontSize: 13)),
                  TextButton(
                      onPressed: busy ? null : widget.onRegister,
                      child: const Text('Créer un compte',
                          style: TextStyle(
                              color: authPurple, fontWeight: FontWeight.w700))),
                ]),
            if (widget.onIntroduction != null)
              Align(
                  alignment: Alignment.center,
                  child: TextButton(
                      onPressed: busy ? null : widget.onIntroduction,
                      child: const Text('Découvrir Orientia',
                          style: TextStyle(fontSize: 12, color: authInk)))),
          ]);
}
