import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import 'auth_widgets.dart';

enum _RecoveryMode { forgot, reset, verify }

class RecoveryPage extends StatefulWidget {
  final ApiClient apiClient;
  const RecoveryPage({super.key, required this.apiClient});
  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      token = TextEditingController(),
      password = TextEditingController(),
      confirmation = TextEditingController();
  _RecoveryMode mode = _RecoveryMode.forgot;
  bool busy = false, showPassword = false, showConfirmation = false;
  Object? error;
  String? message;

  @override
  void dispose() {
    email.dispose();
    token.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  void changeMode(_RecoveryMode value) {
    if (busy) return;
    form.currentState?.reset();
    setState(() {
      mode = value;
      error = null;
      message = null;
      token.clear();
      password.clear();
      confirmation.clear();
      showPassword = false;
      showConfirmation = false;
    });
  }

  // The backend issues 32 random bytes encoded as unpadded base64url. Email
  // links carry this same 43-character token in their query string; no OTP
  // endpoint exists. Read the token locally without opening the pasted URL.
  String? receivedToken(String value) {
    final pasted = value.trim();
    if (RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(pasted)) return pasted;
    try {
      final uri = Uri.tryParse(pasted);
      if (uri == null ||
          !['https', 'http'].contains(uri.scheme) ||
          uri.host.isEmpty) {
        return null;
      }
      final values = uri.queryParametersAll['token'];
      if (values?.length != 1) return null;
      final extracted = values!.single;
      return RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(extracted)
          ? extracted
          : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> submit() async {
    if (busy || form.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
      message = null;
    });
    try {
      switch (mode) {
        case _RecoveryMode.forgot:
          await widget.apiClient.forgotPassword(email.text.trim());
          break;
        case _RecoveryMode.reset:
          await widget.apiClient
              .resetPassword(receivedToken(token.text)!, password.text);
          break;
        case _RecoveryMode.verify:
          await widget.apiClient.verifyEmail(receivedToken(token.text)!);
          break;
      }
      if (mounted) {
        setState(() {
          message = switch (mode) {
            _RecoveryMode.forgot =>
              'Demande prise en compte. Si votre compte est éligible, vous recevrez les instructions par e-mail. Consultez aussi vos spams.',
            _RecoveryMode.verify =>
              'Votre adresse e-mail est vérifiée. Vous pouvez vous connecter.',
            _RecoveryMode.reset =>
              'Votre mot de passe a été modifié. Connectez-vous avec le nouveau mot de passe.',
          };
          token.clear();
          password.clear();
          confirmation.clear();
        });
      }
    } catch (failure) {
      if (mounted) {
        var displayed = failure;
        if (failure is DioException) {
          final body = failure.response?.data;
          if (body is Map &&
              (body['code'] == 'INVALID_ACCOUNT_TOKEN' ||
                  body['message'] == 'Invalid or expired account token')) {
            displayed = const ApiFailure(
                'Ce lien est invalide, expiré ou déjà utilisé. Demandez un nouveau lien.');
          }
        }
        setState(() => error = displayed);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget passwordField({required bool confirm}) => AuthField(
          child: TextFormField(
        key: ValueKey(confirm ? 'recovery-confirmation' : 'recovery-password'),
        controller: confirm ? confirmation : password,
        enabled: !busy,
        obscureText: !(confirm ? showConfirmation : showPassword),
        enableSuggestions: false,
        autocorrect: false,
        autofillHints: const [AutofillHints.newPassword],
        textInputAction: confirm ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: confirm ? (_) => submit() : null,
        decoration: InputDecoration(
            hintText:
                confirm ? 'Confirmer le mot de passe' : 'Nouveau mot de passe',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                          if (confirm) {
                            showConfirmation = !showConfirmation;
                          } else {
                            showPassword = !showPassword;
                          }
                        }),
                tooltip: (confirm ? showConfirmation : showPassword)
                    ? 'Masquer le mot de passe'
                    : 'Afficher le mot de passe',
                icon: Icon((confirm ? showConfirmation : showPassword)
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined))),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Champ requis.';
          if (confirm) {
            return value == password.text
                ? null
                : 'Les mots de passe diffèrent.';
          }
          return value.length >= 12 && utf8.encode(value).length <= 72
              ? null
              : '12 caractères minimum, 72 octets maximum.';
        },
      ));

  @override
  Widget build(BuildContext context) => AuthShell(
          title: switch (mode) {
            _RecoveryMode.forgot => 'Mot de passe oublié ?',
            _RecoveryMode.reset => 'Nouveau mot de passe',
            _RecoveryMode.verify => 'Vérifier mon e-mail',
          },
          subtitle: switch (mode) {
            _RecoveryMode.forgot =>
              'Retrouvez votre accès à Orientia en toute sécurité.',
            _RecoveryMode.reset =>
              'Choisissez un mot de passe pour votre prochain accès.',
            _RecoveryMode.verify =>
              'Confirmez votre adresse pour accéder à votre compte.',
          },
          onBack: busy ? null : () => Navigator.of(context).maybePop(),
          children: [
            Center(
                child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: authPurple.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(22)),
                    child: Icon(
                        mode == _RecoveryMode.forgot
                            ? Icons.lock_reset_rounded
                            : mode == _RecoveryMode.verify
                                ? Icons.mark_email_read_outlined
                                : Icons.password_rounded,
                        color: authPurple,
                        size: 36))),
            const SizedBox(height: 24),
            if (message != null) ...[
              Semantics(
                  liveRegion: true,
                  child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .8),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: const Color(0xffd4c4ff))),
                      child: Text(message!,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(height: 1.5, color: authInk)))),
              const SizedBox(height: 24),
              AuthActionButton(
                  label: mode == _RecoveryMode.forgot
                      ? 'Utiliser mon lien'
                      : 'Aller à la connexion',
                  onPressed: mode == _RecoveryMode.forgot
                      ? () => changeMode(_RecoveryMode.reset)
                      : () => Navigator.of(context).maybePop()),
            ] else ...[
              Form(
                  key: form,
                  child: AutofillGroup(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        if (mode == _RecoveryMode.forgot)
                          AuthField(
                              child: TextFormField(
                                  key: const ValueKey('recovery-email'),
                                  controller: email,
                                  enabled: !busy,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  textInputAction: TextInputAction.done,
                                  autocorrect: false,
                                  onFieldSubmitted: (_) => submit(),
                                  validator: emailValidator,
                                  decoration: const InputDecoration(
                                      hintText: 'Votre adresse e-mail',
                                      prefixIcon:
                                          Icon(Icons.mail_outline_rounded))))
                        else ...[
                          AuthField(
                              child: TextFormField(
                                  key: const ValueKey('recovery-token'),
                                  controller: token,
                                  enabled: !busy,
                                  obscureText: true,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  textInputAction: mode == _RecoveryMode.reset
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                                  onFieldSubmitted: mode == _RecoveryMode.verify
                                      ? (_) => submit()
                                      : null,
                                  validator: (value) => receivedToken(
                                              value ?? '') ==
                                          null
                                      ? 'Collez le lien reçu ou son code sécurisé de 43 caractères.'
                                      : null,
                                  decoration: const InputDecoration(
                                      hintText: 'Lien ou code reçu par e-mail',
                                      prefixIcon: Icon(Icons.link_rounded)))),
                          const SizedBox(height: 12),
                          const Text(
                              'Collez le lien complet reçu par e-mail, ou son code sécurisé. Ne le partagez pas.',
                              style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: Color(0xff686080))),
                        ],
                        if (mode == _RecoveryMode.reset) ...[
                          const SizedBox(height: 20),
                          passwordField(confirm: false),
                          const SizedBox(height: 12),
                          passwordField(confirm: true),
                          const SizedBox(height: 10),
                          const Text(
                              'Au moins 12 caractères, dans la limite de 72 octets.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xff686080))),
                        ],
                      ]))),
              if (error != null) AuthError(error!),
              const SizedBox(height: 28),
              AuthActionButton(
                  label: switch (mode) {
                    _RecoveryMode.forgot => 'Envoyer le lien',
                    _RecoveryMode.reset => 'Enregistrer le mot de passe',
                    _RecoveryMode.verify => 'Vérifier mon e-mail',
                  },
                  pendingLabel: 'Traitement en cours…',
                  busy: busy,
                  onPressed: submit),
            ],
            const SizedBox(height: 24),
            if (mode != _RecoveryMode.reset)
              TextButton(
                  onPressed:
                      busy ? null : () => changeMode(_RecoveryMode.reset),
                  child: const Text('J’ai déjà un lien de réinitialisation',
                      textAlign: TextAlign.center)),
            if (mode != _RecoveryMode.forgot)
              TextButton(
                  onPressed:
                      busy ? null : () => changeMode(_RecoveryMode.forgot),
                  child: Text(
                      mode == _RecoveryMode.verify
                          ? 'Mot de passe oublié ?'
                          : 'Recevoir un nouveau lien',
                      textAlign: TextAlign.center)),
            if (mode != _RecoveryMode.verify)
              TextButton(
                  onPressed:
                      busy ? null : () => changeMode(_RecoveryMode.verify),
                  child: const Text('Vérifier mon adresse e-mail',
                      textAlign: TextAlign.center)),
            TextButton(
                onPressed: busy ? null : () => Navigator.of(context).maybePop(),
                child: const Text('Retour à la connexion',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: authPurple))),
          ]);
}
