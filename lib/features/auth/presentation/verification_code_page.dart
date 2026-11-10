import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_client.dart';
import 'auth_widgets.dart';

class VerificationCodePage extends StatefulWidget {
  final ApiClient apiClient;
  final String challengeId, email;
  final VoidCallback onVerified, onBack;
  const VerificationCodePage(
      {super.key,
      required this.apiClient,
      required this.challengeId,
      required this.email,
      required this.onVerified,
      required this.onBack});
  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final code = TextEditingController();
  final form = GlobalKey<FormState>();
  late DateTime resendAt = DateTime.now().add(const Duration(seconds: 60));
  Timer? timer;
  bool busy = false, verified = false;
  Object? error;
  String? notice;
  int get remaining =>
      resendAt.difference(DateTime.now()).inSeconds.clamp(0, 60);
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !verified) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    code.dispose();
    super.dispose();
  }

  Future<void> verify() async {
    if (busy || verified || form.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
      notice = null;
    });
    try {
      await widget.apiClient.verifyEmailCode(widget.challengeId, code.text);
      if (mounted) {
        setState(() {
          verified = true;
          code.clear();
          timer?.cancel();
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resend() async {
    if (busy || verified || remaining > 0) return;
    setState(() {
      busy = true;
      error = null;
      notice = null;
    });
    try {
      await widget.apiClient.resendVerificationCode(widget.challengeId);
      if (mounted) {
        setState(() {
          resendAt = DateTime.now().add(const Duration(seconds: 60));
          code.clear();
          notice =
              'Demande prise en compte. Consultez votre messagerie et vos spams. Trois envois maximum par période de dix minutes.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthShell(
          title: verified ? 'Adresse vérifiée !' : 'Vérifiez votre e-mail',
          subtitle: verified
              ? 'Votre compte est prêt. Connectez-vous pour continuer.'
              : 'Saisissez le code reçu à\n${widget.email}',
          onBack: busy ? null : widget.onBack,
          children: [
            TweenAnimationBuilder<double>(
                key: ValueKey(verified),
                tween: Tween(begin: .8, end: 1),
                duration: Duration(
                    milliseconds:
                        MediaQuery.disableAnimationsOf(context) ? 0 : 600),
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Icon(
                    verified
                        ? Icons.verified_rounded
                        : Icons.mark_email_unread_outlined,
                    size: 64,
                    color: verified ? const Color(0xff008934) : authPurple)),
            const SizedBox(height: 24),
            if (verified) ...[
              Semantics(
                  liveRegion: true,
                  child: const Text(
                      'Votre adresse est confirmée. Aucune connexion automatique n’a été effectuée.',
                      textAlign: TextAlign.center)),
              const SizedBox(height: 24),
              AuthActionButton(
                  label: 'Aller à la connexion', onPressed: widget.onVerified),
            ] else ...[
              Form(
                  key: form,
                  child: AuthField(
                      child: TextFormField(
                    key: const ValueKey('verification-code'),
                    controller: code,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6)
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 10,
                        fontWeight: FontWeight.w700,
                        color: authInk),
                    decoration: const InputDecoration(
                        labelText: 'Code à six chiffres', hintText: '000000'),
                    validator: (value) =>
                        RegExp(r'^\d{6}$').hasMatch(value ?? '')
                            ? null
                            : 'Saisissez les six chiffres reçus.',
                    onFieldSubmitted: (_) => verify(),
                  ))),
              const SizedBox(height: 16),
              const Text(
                  'Le code expire après dix minutes et ne peut être utilisé qu’une fois. Restez dans Orientia pour terminer la vérification.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.5, color: authInk)),
              if (error != null) AuthError(error!),
              if (notice != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Semantics(
                        liveRegion: true,
                        child: Text(notice!, textAlign: TextAlign.center))),
              const SizedBox(height: 24),
              AuthActionButton(
                  label: 'Vérifier mon compte',
                  pendingLabel: 'Vérification en cours…',
                  busy: busy,
                  onPressed: verify),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: busy || remaining > 0 ? null : resend,
                  child: Text(remaining > 0
                      ? 'Renvoyer un code dans ${remaining}s'
                      : 'Renvoyer un code')),
              TextButton(
                  onPressed: busy ? null : widget.onBack,
                  child: const Text('Corriger mon adresse e-mail')),
            ]
          ]);
}
