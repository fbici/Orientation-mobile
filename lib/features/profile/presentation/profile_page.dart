import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/academic_models.dart';
import '../../../core/widgets/academic_widgets.dart';
import '../../documents/presentation/documents_page.dart';
import '../../history/presentation/history_page.dart';
import 'academic_profile_page.dart';

class ProfilePage extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onLogout;
  const ProfilePage(
      {super.key, required this.apiClient, required this.onLogout});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int revision = 0;
  Object? error;
  Future<void> account(Json me, bool password) async {
    final first =
            TextEditingController(text: me['firstName']?.toString() ?? ''),
        last = TextEditingController(text: me['lastName']?.toString() ?? ''),
        phone = TextEditingController();
    final old = TextEditingController(), fresh = TextEditingController();
    bool confirmed = false;
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) => StatefulBuilder(
            builder: (c, update) => AlertDialog(
                    title: Text(password
                        ? 'Changer le mot de passe'
                        : 'Modifier mes coordonnées'),
                    content: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      if (password) ...[
                        TextField(
                            controller: old,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Mot de passe actuel')),
                        TextField(
                            controller: fresh,
                            obscureText: true,
                            maxLength: 72,
                            decoration: const InputDecoration(
                                labelText:
                                    'Nouveau mot de passe — 12 caractères minimum'))
                      ] else ...[
                        TextField(
                            controller: first,
                            decoration:
                                const InputDecoration(labelText: 'Prénom')),
                        TextField(
                            controller: last,
                            decoration:
                                const InputDecoration(labelText: 'Nom')),
                        TextField(
                            controller: phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                                labelText: 'Numéro à enregistrer')),
                        const Text(
                            'Le numéro actuel n’est pas retourné par le serveur. Un champ vide supprimera le numéro précédent.')
                      ],
                      CheckboxListTile(
                          value: confirmed,
                          onChanged: (v) =>
                              update(() => confirmed = v ?? false),
                          title: const Text(
                              'Je confirme le remplacement de ces informations.')),
                    ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Annuler')),
                      FilledButton(
                          onPressed:
                              confirmed ? () => Navigator.pop(c, true) : null,
                          child: const Text('Enregistrer'))
                    ])));
    if (yes == true) {
      try {
        if (password) {
          if (fresh.text.length < 12) {
            throw const FormatException('Mot de passe trop court');
          }
          await widget.apiClient.changePassword(old.text, fresh.text);
          try {
            await widget.apiClient.logout();
          } catch (_) {}
        } else {
          if (first.text.trim().isEmpty || last.text.trim().isEmpty) {
            throw const FormatException('Nom requis');
          }
          await widget.apiClient.updateMe({
            'firstName': first.text.trim(),
            'lastName': last.text.trim(),
            'phone': phone.text.trim().isEmpty ? null : phone.text.trim()
          });
          if (mounted) setState(() => revision++);
        }
      } catch (e) {
        if (mounted) setState(() => error = e);
      }
    }
    for (final controller in [first, last, phone, old, fresh]) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: AsyncContent<Json>(
          key: ValueKey(revision),
          load: () async => object((await widget.apiClient.getMe()).data),
          builder: (me, reload) =>
              ListView(padding: const EdgeInsets.all(20), children: [
                CircleAvatar(
                    radius: 32,
                    child: Text(text(me['firstName'], '?').substring(0, 1))),
                const SizedBox(height: 12),
                Text('${text(me['firstName'], '')} ${text(me['lastName'], '')}',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center),
                Text(text(me['email']), textAlign: TextAlign.center),
                if (error != null) ErrorNotice(error!),
                ListTile(
                    leading: const Icon(Icons.school),
                    title: const Text('Mon profil académique'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => AcademicProfilePage(
                                apiClient: widget.apiClient)))),
                ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Mes relevés'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) =>
                                DocumentsPage(apiClient: widget.apiClient)))),
                ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Historique et exports'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) =>
                                HistoryPage(apiClient: widget.apiClient)))),
                ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Modifier mes coordonnées'),
                    onTap: () => account(me, false)),
                ListTile(
                    leading: const Icon(Icons.password),
                    title: const Text('Changer mon mot de passe'),
                    onTap: () => account(me, true)),
                FilledButton.icon(
                    onPressed: () async {
                      try {
                        await widget.apiClient.logout();
                      } catch (_) {}
                      widget.onLogout();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter')),
              ])));
}
