import '../../../core/widgets/business_scaffold.dart';
import 'package:flutter/material.dart';
import '../../../core/models/academic_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/widgets/academic_widgets.dart';
import '../../auth/data/google_identity.dart';

class AccountDeletionPage extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onLogout;
  final GoogleIdentityProvider? google;
  const AccountDeletionPage(
      {super.key,
      required this.apiClient,
      required this.onLogout,
      this.google});
  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  final confirmation = TextEditingController(),
      password = TextEditingController();
  bool busy = false;
  Object? error;
  DateTime? due;
  @override
  void dispose() {
    confirmation.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> request({bool google = false}) async {
    if (busy) return;
    if (confirmation.text.trim() != 'SUPPRIMER') {
      setState(() => error = const ApiFailure(
          'Saisissez SUPPRIMER pour confirmer votre demande.'));
      return;
    }
    if (!google && password.text.isEmpty) {
      setState(() =>
          error = const ApiFailure('Saisissez votre mot de passe actuel.'));
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      String? token;
      if (google) {
        token = await (widget.google ?? AndroidGoogleIdentity()).authenticate();
        if (token == null) return;
      }
      final data = object((await widget.apiClient
              .call('/auth/me/deletion-request', method: 'POST', data: {
        'confirmation': 'SUPPRIMER',
        if (google)
          'googleIdToken': token
        else
          'currentPassword': password.text,
      }))
          .data);
      final date = DateTime.tryParse(data['purgeAfter']?.toString() ?? '');
      if (date == null) {
        throw const ApiFailure(
            'Le serveur n’a pas confirmé la date de suppression. Contactez le support avant de recommencer.');
      }
      if (mounted) {
        setState(() {
          due = date.toLocal();
          password.clear();
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> finish() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await widget.apiClient.logout();
    } catch (_) {}
    if (mounted) {
      Navigator.pop(context);
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !busy && due == null,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && due != null && !busy) finish();
        },
        child: BusinessScaffold(
          appBar: AppBar(title: const Text('Supprimer mon compte')),
          body: ListView(padding: const EdgeInsets.all(24), children: [
            if (due != null) ...[
              const Icon(Icons.check_circle_outline, size: 48),
              Text('Demande enregistrée',
                  style: Theme.of(context).textTheme.headlineSmall),
              Text(
                  'Votre accès est désactivé. L’effacement est prévu à partir du ${due!.day.toString().padLeft(2, '0')}/${due!.month.toString().padLeft(2, '0')}/${due!.year}.'),
              const Notice(
                  'Votre adresse e-mail sera réutilisable après la fin de l’effacement. Vos données ne seront pas récupérées par le nouveau compte.'),
              FilledButton(
                  onPressed: busy ? null : finish,
                  child: const Text('Revenir à la connexion')),
            ] else ...[
              Text('Avant de partir',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Notice(
                  'Cette demande désactive immédiatement votre compte et vos sessions. Après 30 jours, votre dossier, vos relevés, vos conversations et vos résultats seront effacés. L’effacement est définitif.'),
              const Text(
                  'Votre adresse e-mail reste réservée jusqu’à la fin de cet effacement. Cette procédure est différente d’une suspension administrative. Pour une question ou une demande de correction : lestudioviral@gmail.com.'),
              const SizedBox(height: 20),
              TextField(
                  controller: confirmation,
                  enabled: !busy,
                  decoration:
                      const InputDecoration(labelText: 'Saisissez SUPPRIMER')),
              const SizedBox(height: 16),
              TextField(
                  controller: password,
                  enabled: !busy,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Mot de passe actuel')),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: busy ? null : request,
                  child: const Text('Confirmer la suppression différée')),
              TextButton.icon(
                  onPressed: busy ? null : () => request(google: true),
                  icon: Image.asset('assets/images/google-g.png', width: 20),
                  label: const Text('Confirmer avec mon compte Google')),
              if (error != null) ErrorNotice(error!),
            ],
            if (busy) const LinearProgressIndicator(),
          ]),
        ),
      );
}
