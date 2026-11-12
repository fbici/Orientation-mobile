import '../../../core/widgets/business_scaffold.dart';
import 'account_edit_dialog.dart';
import 'account_deletion_page.dart';
import '../../navigation/presentation/workspace_pages.dart';
import '../../chat/presentation/chat_page.dart';
import '../../recommendations/presentation/recommendations_page.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
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
    if (!password && !me.containsKey('phone')) {
      setState(() => error = const ApiFailure(
          'Le serveur doit être mis à jour avant de modifier les coordonnées sans risquer de perdre votre téléphone.'));
      return;
    }
    final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AccountEditDialog(
            apiClient: widget.apiClient, me: me, password: password));
    if (saved != true || !mounted) return;
    if (password) {
      try {
        await widget.apiClient.logout();
      } catch (_) {}
      if (mounted) widget.onLogout();
    } else {
      setState(() {
        revision++;
        error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coordonnées enregistrées.')));
    }
  }

  @override
  Widget build(BuildContext context) => BusinessScaffold(
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
                    leading: const Icon(Icons.menu_book_rounded),
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
                    leading: const Icon(Icons.auto_awesome_outlined),
                    title: const Text('Mes recommandations'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => RecommendationsPage(
                                apiClient: widget.apiClient)))),
                ListTile(
                    leading: const Icon(Icons.chat_outlined),
                    title: const Text('Mes conversations'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) =>
                                ChatPage(apiClient: widget.apiClient)))),
                ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Paramètres'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (settingsContext) => SettingsPage(
                                  editAccount: () {
                                    Navigator.pop(settingsContext);
                                    account(me, false);
                                  },
                                  changePassword: () {
                                    Navigator.pop(settingsContext);
                                    account(me, true);
                                  },
                                  logout: () async {
                                    try {
                                      await widget.apiClient.logout();
                                    } catch (_) {}
                                    if (settingsContext.mounted) {
                                      Navigator.pop(settingsContext);
                                    }
                                    widget.onLogout();
                                  },
                                )))),
                ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Modifier mes coordonnées'),
                    onTap: () => account(me, false)),
                ListTile(
                    leading: const Icon(Icons.password),
                    title: const Text('Changer mon mot de passe'),
                    onTap: () => account(me, true)),
                ListTile(
                    leading: const Icon(Icons.person_remove_outlined),
                    title: const Text('Supprimer mon compte'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => AccountDeletionPage(
                                apiClient: widget.apiClient,
                                onLogout: widget.onLogout)))),
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
