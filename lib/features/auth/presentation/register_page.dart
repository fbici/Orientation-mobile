import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import 'auth_widgets.dart';

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
  final fields = {
    for (final k in [
      'firstName',
      'lastName',
      'email',
      'phone',
      'password',
      'confirmation'
    ])
      k: TextEditingController()
  };
  bool busy = false, consent = false, accepted = false;
  Object? error;
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> register() async {
    if (form.currentState?.validate() != true || !consent) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.apiClient.register({
        for (final k in ['firstName', 'lastName', 'email', 'phone'])
          k: fields[k]!.text.trim(),
        'password': fields['password']!.text
      });
      if (mounted) setState(() => accepted = true);
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      AuthShell(title: 'Créer mon compte candidat', children: [
        if (accepted) ...[
          const Text(
              'Demande reçue. Si votre compte est éligible, consultez votre email pour la vérification. Aucune connexion n’est effectuée automatiquement.'),
          FilledButton(
              onPressed: widget.onRegisterSuccess,
              child: const Text('Aller à la connexion')),
        ] else ...[
          Form(
              key: form,
              child: Column(children: [
                for (final (name, label) in [
                  ('firstName', 'Prénom'),
                  ('lastName', 'Nom'),
                  ('email', 'Email'),
                  ('phone', 'Téléphone — facultatif'),
                  ('password', 'Mot de passe — 12 caractères minimum'),
                  ('confirmation', 'Confirmer le mot de passe')
                ])
                  Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextFormField(
                          controller: fields[name],
                          obscureText:
                              ['password', 'confirmation'].contains(name),
                          keyboardType: name == 'email'
                              ? TextInputType.emailAddress
                              : name == 'phone'
                                  ? TextInputType.phone
                                  : TextInputType.text,
                          decoration: InputDecoration(labelText: label),
                          validator: (v) {
                            if (name == 'email') return emailValidator(v);
                            if (name == 'phone') return null;
                            if (v == null || v.trim().isEmpty) {
                              return 'Champ requis.';
                            }
                            if (name == 'password' &&
                                (v.length < 12 || utf8.encode(v).length > 72)) {
                              return '12 caractères minimum, 72 octets maximum.';
                            }
                            if (name == 'confirmation' &&
                                v != fields['password']!.text) {
                              return 'Les mots de passe diffèrent.';
                            }
                            return null;
                          })),
              ])),
          CheckboxListTile(
              value: consent,
              onChanged: (v) => setState(() => consent = v ?? false),
              title: const Text('Je souhaite créer mon compte candidat.')),
          const Text(
              'Votre pays et vos informations scolaires seront renseignés dans le profil après connexion.'),
          if (error != null) AuthError(error!),
          if (busy) const LinearProgressIndicator(),
          FilledButton(
              onPressed: busy || !consent ? null : register,
              child: const Text('Demander mon inscription')),
          TextButton(
              onPressed: busy ? null : widget.onBackToLogin,
              child: const Text('Déjà inscrit ? Se connecter')),
        ],
      ]);
}
