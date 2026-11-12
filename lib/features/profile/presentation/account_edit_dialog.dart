import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/models/academic_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/academic_widgets.dart';
import '../../../core/widgets/international_phone_field.dart';

class AccountEditDialog extends StatefulWidget {
  final ApiClient apiClient;
  final Json me;
  final bool password;
  const AccountEditDialog(
      {super.key,
      required this.apiClient,
      required this.me,
      required this.password});
  @override
  State<AccountEditDialog> createState() => _AccountEditDialogState();
}

class _AccountEditDialogState extends State<AccountEditDialog> {
  final form = GlobalKey<FormState>();
  late final first =
      TextEditingController(text: text(widget.me['firstName'], ''));
  late final last =
      TextEditingController(text: text(widget.me['lastName'], ''));
  final old = TextEditingController(),
      fresh = TextEditingController(),
      confirmation = TextEditingController();
  late final phone = PhoneController(initialValue: initialPhone());
  bool busy = false;
  Object? error;
  PhoneNumber initialPhone() {
    final value = widget.me['phone'];
    if (value is String && value.isNotEmpty) {
      try {
        return PhoneNumber.parse(value);
      } catch (_) {/* Keep original unless the user requests a change. */}
    }
    return const PhoneNumber(isoCode: IsoCode.BJ, nsn: '');
  }

  bool changePhone = false;
  @override
  void dispose() {
    for (final c in [first, last, old, fresh, confirmation]) {
      c.dispose();
    }
    phone.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || form.currentState?.validate() != true) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (widget.password) {
        await widget.apiClient.changePassword(old.text, fresh.text);
      } else {
        await widget.apiClient.updateMe({
          'firstName': first.text.trim(),
          'lastName': last.text.trim(),
          'phone':
              changePhone ? normalizedPhone(phone.value) : widget.me['phone']
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !busy,
      child: AlertDialog(
        title: Text(widget.password
            ? 'Changer le mot de passe'
            : 'Modifier mes coordonnées'),
        content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
                child: Form(
                    key: form,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (widget.password) ...[
                        TextFormField(
                            controller: old,
                            enabled: !busy,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Mot de passe actuel'),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Saisissez votre mot de passe actuel.'
                                : null),
                        TextFormField(
                            controller: fresh,
                            enabled: !busy,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Nouveau mot de passe'),
                            validator: (v) => v == null || v.length < 12
                                ? 'Au moins 12 caractères.'
                                : utf8.encode(v).length > 72
                                    ? '72 octets UTF-8 au maximum.'
                                    : null),
                        TextFormField(
                            controller: confirmation,
                            enabled: !busy,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Confirmer le nouveau mot de passe'),
                            validator: (v) => v != fresh.text
                                ? 'Les mots de passe ne correspondent pas.'
                                : null),
                        const Text(
                            'Après la modification, reconnectez-vous avec votre nouveau mot de passe.'),
                      ] else ...[
                        TextFormField(
                            controller: first,
                            enabled: !busy,
                            decoration:
                                const InputDecoration(labelText: 'Prénom'),
                            validator: requiredName),
                        TextFormField(
                            controller: last,
                            enabled: !busy,
                            decoration: const InputDecoration(labelText: 'Nom'),
                            validator: requiredName),
                        Text(
                            'Téléphone enregistré : ${text(widget.me['phone'], 'Non renseigné')}'),
                        CheckboxListTile(
                            value: changePhone,
                            onChanged: busy
                                ? null
                                : (v) =>
                                    setState(() => changePhone = v ?? false),
                            title:
                                const Text('Modifier mon numéro de téléphone')),
                        if (changePhone) ...[
                          InternationalPhoneField(
                              controller: phone, enabled: !busy),
                          const Text(
                              'Laisser ce champ vide retirera le numéro enregistré.'),
                        ],
                      ],
                      if (busy) const LinearProgressIndicator(),
                      if (error != null) ErrorNotice(error!),
                    ])))),
        actions: [
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: busy ? null : save, child: const Text('Enregistrer'))
        ],
      ));
  String? requiredName(String? value) => value == null || value.trim().isEmpty
      ? 'Ce champ est obligatoire.'
      : null;
}
