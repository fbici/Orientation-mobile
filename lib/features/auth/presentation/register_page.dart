import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import 'auth_widgets.dart';
import 'verification_code_page.dart';
import '../../../core/widgets/international_phone_field.dart';

class RegisterPage extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onRegisterSuccess, onBackToLogin;
  const RegisterPage(
      {super.key,
      required this.apiClient,
      required this.onRegisterSuccess,
      required this.onBackToLogin});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final form = GlobalKey<FormState>();
  final phone = PhoneController(
      initialValue: const PhoneNumber(isoCode: IsoCode.BJ, nsn: ''));
  final fields = {
    for (final k in [
      'firstName',
      'lastName',
      'email',
      'password',
      'confirmation'
    ])
      k: TextEditingController()
  };
  bool busy = false, showPassword = false, showConfirmation = false;
  Object? error;
  String? challengeId;
  @override
  void dispose() {
    phone.dispose();
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> register() async {
    if (busy || form.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await widget.apiClient.registerMobile({
        for (final k in ['firstName', 'lastName', 'email'])
          k: fields[k]!.text.trim(),
        'phone': normalizedPhone(phone.value),
        'password': fields['password']!.text
      });
      if (mounted) {
        setState(() {
          challengeId = response.data['challengeId'] as String;
          fields['password']!.clear();
          fields['confirmation']!.clear();
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  int get passwordScore {
    final value = fields['password']!.text;
    if (value.isEmpty) return 0;
    return [
      value.length >= 12,
      RegExp('[A-Z]').hasMatch(value),
      RegExp('[a-z]').hasMatch(value),
      RegExp('[0-9]').hasMatch(value),
      RegExp(r'[^A-Za-z0-9]').hasMatch(value)
    ].where((v) => v).length;
  }

  Widget field(String name, String label, IconData icon) {
    final secret = name == 'password' || name == 'confirmation';
    return AuthField(
        child: TextFormField(
      key: ValueKey('register-$name'),
      controller: fields[name],
      enabled: !busy,
      obscureText:
          secret && !(name == 'password' ? showPassword : showConfirmation),
      autofillHints: switch (name) {
        'firstName' => [AutofillHints.givenName],
        'lastName' => [AutofillHints.familyName],
        'email' => [AutofillHints.email],
        'phone' => [AutofillHints.telephoneNumber],
        'password' || 'confirmation' => [AutofillHints.newPassword],
        _ => null
      },
      keyboardType: name == 'email'
          ? TextInputType.emailAddress
          : name == 'phone'
              ? TextInputType.phone
              : TextInputType.text,
      textInputAction:
          name == 'confirmation' ? TextInputAction.done : TextInputAction.next,
      onChanged: name == 'password' ? (_) => setState(() {}) : null,
      decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon, size: 22),
          suffixIcon: secret
              ? IconButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                            if (name == 'password') {
                              showPassword = !showPassword;
                            } else {
                              showConfirmation = !showConfirmation;
                            }
                          }),
                  tooltip:
                      (name == 'password' ? showPassword : showConfirmation)
                          ? 'Masquer le mot de passe'
                          : 'Afficher le mot de passe',
                  icon: Icon(
                      (name == 'password' ? showPassword : showConfirmation)
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 22))
              : null),
      validator: (value) {
        if (name == 'email') return emailValidator(value);
        if (name == 'phone') return null;
        if (value == null || value.trim().isEmpty) return 'Champ requis.';
        if (name == 'password' &&
            (value.length < 12 || utf8.encode(value).length > 72)) {
          return '12 caractères minimum, 72 octets maximum.';
        }
        if (name == 'confirmation' && value != fields['password']!.text) {
          return 'Les mots de passe diffèrent.';
        }
        return null;
      },
    ));
  }

  @override
  Widget build(BuildContext context) => challengeId != null
      ? VerificationCodePage(
          apiClient: widget.apiClient,
          challengeId: challengeId!,
          email: fields['email']!.text.trim(),
          onVerified: widget.onRegisterSuccess,
          onBack: () => setState(() => challengeId = null))
      : AuthShell(
          title: 'Créer un compte',
          subtitle:
              'Rejoignez Orientia et construisez\nvotre avenir universitaire',
          onBack: busy ? null : widget.onBackToLogin,
          children: [
              Form(
                  key: form,
                  child: AutofillGroup(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        LayoutBuilder(builder: (context, bounds) {
                          final last = field(
                              'lastName', 'Nom', Icons.person_outline_rounded);
                          final first = field('firstName', 'Prénom',
                              Icons.person_outline_rounded);
                          if (bounds.maxWidth < 300 ||
                              MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                            return Column(children: [
                              last,
                              const SizedBox(height: 10),
                              first
                            ]);
                          }
                          return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: last),
                                const SizedBox(width: 10),
                                Expanded(child: first)
                              ]);
                        }),
                        const SizedBox(height: 10),
                        field('email', 'Adresse e-mail',
                            Icons.mail_outline_rounded),
                        const SizedBox(height: 10),
                        AuthField(
                            child: InternationalPhoneField(
                                controller: phone, enabled: !busy)),
                        const SizedBox(height: 10),
                        field('password', 'Mot de passe',
                            Icons.lock_outline_rounded),
                        const SizedBox(height: 10),
                        field('confirmation', 'Confirmer le mot de passe',
                            Icons.lock_outline_rounded),
                      ]))),
              const SizedBox(height: 18),
              Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                        width: 170,
                        child: Row(
                            children: List.generate(
                                5,
                                (i) => Expanded(
                                    child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        height: 6,
                                        margin: const EdgeInsets.only(right: 4),
                                        decoration: BoxDecoration(
                                            color: passwordScore > i
                                                ? const Color(0xffba26fa)
                                                : const Color(0xffded8f4),
                                            borderRadius:
                                                BorderRadius.circular(4))))))),
                    Text(
                        passwordScore == 5
                            ? 'Mot de passe fort ✓'
                            : fields['password']!.text.isEmpty
                                ? '12 caractères minimum'
                                : 'Mot de passe à renforcer',
                        style: TextStyle(
                            fontSize: 11,
                            color: passwordScore == 5
                                ? const Color(0xff008934)
                                : const Color(0xff686080))),
                  ]),
              if (error != null) AuthError(error!),
              const SizedBox(height: 30),
              AuthActionButton(
                  label: 'Créer mon compte',
                  pendingLabel: 'Création en cours…',
                  leading: Icons.person_add_alt_1_outlined,
                  busy: busy,
                  onPressed: register),
              const SizedBox(height: 28),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.verified_user_outlined, color: authPurple, size: 24),
                SizedBox(width: 12),
                Flexible(
                    child: Text(
                        'Vos informations sont sécurisées\net restent confidentielles.',
                        style: TextStyle(fontSize: 12, color: authInk))),
              ]),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: busy ? null : widget.onBackToLogin,
                  child: const Text('Déjà inscrit ? Se connecter',
                      style: TextStyle(color: authPurple, fontSize: 12))),
            ]);
}
