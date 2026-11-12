import '../../../core/widgets/business_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/academic_widgets.dart';
import '../../auth/presentation/auth_widgets.dart';
import '../../universities/presentation/universities_page.dart';
import '../../programs/presentation/programs_page.dart';
import '../../scholarships/presentation/scholarships_page.dart';
import '../../profile/presentation/academic_profile_page.dart';
import '../../documents/presentation/documents_page.dart';
import '../../recommendations/presentation/recommendations_page.dart';
import '../../simulation/presentation/simulation_page.dart';
import '../../history/presentation/history_page.dart';
import '../../chat/presentation/chat_page.dart';

class WorkspacePage extends StatelessWidget {
  final ApiClient apiClient;
  final bool explore;
  const WorkspacePage(
      {super.key, required this.apiClient, this.explore = false});
  @override
  Widget build(BuildContext context) {
    final actions = explore
        ? <(String, String, IconData, Widget)>[
            (
              'Universités',
              'Universités, campus, écoles et facultés',
              Icons.account_balance_outlined,
              UniversitiesPage(apiClient: apiClient)
            ),
            (
              'Formations et comparaison',
              'Rechercher et comparer de 2 à 6 formations',
              Icons.menu_book_outlined,
              ProgramsPage(apiClient: apiClient)
            ),
            (
              'Bourses',
              'Consulter les conditions et évaluer votre éligibilité',
              Icons.savings_outlined,
              ScholarshipsPage(apiClient: apiClient)
            ),
          ]
        : <(String, String, IconData, Widget)>[
            (
              'Mon dossier académique',
              'Pays, années, notes, préférences et budget',
              Icons.edit_document,
              AcademicProfilePage(apiClient: apiClient)
            ),
            (
              'Mes relevés',
              'Importer, analyser et vérifier les résultats extraits',
              Icons.upload_file_outlined,
              DocumentsPage(apiClient: apiClient)
            ),
            (
              'Mes recommandations',
              'Comprendre les critères et les possibilités',
              Icons.auto_awesome_outlined,
              RecommendationsPage(apiClient: apiClient)
            ),
            (
              'Mes simulations',
              'Tester une hypothèse sans modifier votre dossier',
              Icons.tune,
              SimulationPage(apiClient: apiClient)
            ),
            (
              'Historique et exports',
              'Recommandations, simulations, comparaisons et bourses',
              Icons.history,
              HistoryPage(apiClient: apiClient)
            ),
            (
              'Assistant Orientia',
              'Poser une question et consulter vos conversations',
              Icons.chat_outlined,
              ChatPage(apiClient: apiClient)
            ),
          ];
    return BusinessScaffold(
      appBar: AppBar(title: Text(explore ? 'Explorer' : 'Mon parcours')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(
            explore
                ? 'Découvrez vos possibilités'
                : 'Construisez votre parcours',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Notice(explore
            ? 'Consultez les sources et les conditions de chaque opportunité.'
            : 'Complétez votre dossier, vérifiez vos notes, puis explorez vos recommandations. Votre confirmation reste une déclaration personnelle.'),
        const SizedBox(height: 16),
        for (final action in actions)
          Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute<void>(builder: (_) => action.$4)),
                  child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFF0E8FC),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Icon(action.$3,
                                      color: const Color(0xFF7138CE),
                                      size: 28)),
                              const Spacer(),
                              const Icon(Icons.arrow_outward_rounded,
                                  color: Color(0xFF9C7AC7))
                            ]),
                            const SizedBox(height: 20),
                            Text(action.$1,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF24153D))),
                            const SizedBox(height: 8),
                            Text(action.$2,
                                style: const TextStyle(
                                    height: 1.5, color: Color(0xFF756B83))),
                          ])))),
      ]),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final VoidCallback editAccount, changePassword, logout;
  const SettingsPage(
      {super.key,
      required this.editAccount,
      required this.changePassword,
      required this.logout});
  @override
  Widget build(BuildContext context) => BusinessScaffold(
        appBar: AppBar(title: const Text('Paramètres')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Compte et sécurité',
              style: Theme.of(context).textTheme.titleLarge),
          ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Informations personnelles'),
              onTap: editAccount),
          ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Modifier le mot de passe'),
              onTap: changePassword),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Aide et contact'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const SupportPage()))),
          ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('À propos d’Orientia'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const AboutOrientiaPage()))),
          ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Données et informations légales'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const DataInformationPage()))),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Se déconnecter'),
              onTap: logout),
        ]),
      );
}

class AboutOrientiaPage extends StatelessWidget {
  const AboutOrientiaPage({super.key});
  @override
  Widget build(BuildContext context) => BusinessScaffold(
      appBar: AppBar(title: const Text('À propos d’Orientia')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Center(child: BrandLogo(height: 110)),
        const SizedBox(height: 24),
        Text('Orientia', style: Theme.of(context).textTheme.headlineMedium),
        const Text('Version ${AppConstants.appVersion}'),
        const SizedBox(height: 12),
        const Text('Créé par Le Studio Viral',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SelectableText('lestudioviral@gmail.com'),
        ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('Confidentialité et conditions'),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const DataInformationPage()))),
        const SizedBox(height: 16),
        const Text(
            'Orientia vous accompagne dans vos choix de formations, d’universités et de bourses, avec le Bénin comme priorité et une ouverture sur le monde.'),
        const Notice(
            'Les recommandations sont une aide à la décision. Elles ne garantissent ni admission universitaire ni attribution d’une bourse.'),
        ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Contacter Orientia'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute<void>(builder: (_) => const SupportPage()))),
        TextButton(
            onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Orientia',
                applicationVersion: AppConstants.appVersion),
            child: const Text('Licences des composants')),
      ]));
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});
  static const email = 'lestudioviral@gmail.com';
  @override
  Widget build(BuildContext context) => BusinessScaffold(
      appBar: AppBar(title: const Text('Aide et contact')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const ExpansionTile(title: Text('Préparer mon dossier'), children: [
          Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                  'Dans Parcours, renseignez votre pays, les années et le barème. Ajoutez vos notes ou importez un relevé, vérifiez les données extraites puis confirmez votre dossier.'))
        ]),
        const ExpansionTile(title: Text('Comprendre mes résultats'), children: [
          Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                  'Un score indique une compatibilité avec les informations disponibles. Consultez les critères, les sources et les données manquantes. Une simulation ne modifie pas le dossier confirmé.'))
        ]),
        const ExpansionTile(title: Text('Une opération échoue'), children: [
          Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                  'Vérifiez votre connexion. Après un délai d’attente, consultez les documents ou l’historique avant de recommencer une opération. Vous pouvez signaler l’écran concerné et le message reçu au support.'))
        ]),
        const SizedBox(height: 20),
        const SelectableText(email),
        const Text(
            'Pour une question, un problème technique ou une demande concernant vos données. Ne transmettez jamais votre mot de passe ni votre code de vérification.'),
        FilledButton.icon(
            icon: const Icon(Icons.mail_outline),
            label: const Text('Préparer un e-mail'),
            onPressed: () async {
              try {
                final opened = await launchUrl(Uri(
                    scheme: 'mailto',
                    path: email,
                    query: 'subject=Assistance%20Orientia'));
                if (!opened) throw StateError('No mail application');
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Aucune messagerie disponible. Copiez l’adresse ci-dessous.')));
                }
              }
            }),
        TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copier l’adresse'),
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: email));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Adresse copiée.')));
              }
            }),
      ]));
}

class DataInformationPage extends StatelessWidget {
  const DataInformationPage({super.key});
  @override
  Widget build(BuildContext context) => BusinessScaffold(
      appBar: AppBar(title: const Text('Données et informations légales')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Votre confiance compte',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const Text(
            'Comprenez comment Orientia utilise vos informations et accompagne vos choix.'),
        const SizedBox(height: 20),
        for (final document in legalDocuments)
          Card(
              child: ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: Text(document.$1),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => LegalDocumentPage(
                              title: document.$1, sections: document.$2))))),
        ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Une question sur vos données ?'),
            subtitle: const Text(SupportPage.email),
            onTap: () => Navigator.push(context,
                MaterialPageRoute<void>(builder: (_) => const SupportPage()))),
      ]));
}

const legalDocuments = <(String, List<(String, String)>)>[
  (
    'Politique de confidentialité',
    [
      (
        'Les informations utilisées',
        'Orientia traite les informations de votre compte (nom, prénom, e-mail et téléphone renseigné), votre dossier académique, vos notes, préférences et budget, les relevés que vous importez, vos conversations et vos résultats enregistrés. Des informations techniques de session et de sécurité servent à protéger les accès.'
      ),
      (
        'Pourquoi nous les utilisons',
        'Ces informations permettent de gérer votre compte, analyser vos relevés à votre demande, proposer des recommandations et simulations, conserver votre historique et assurer le support. Un résultat automatique reste une aide à la décision : vous pouvez vérifier et corriger votre dossier.'
      ),
      (
        'Les services intervenants',
        'Le backend et la base de données sont hébergés sur Render. Brevo assure les e-mails transactionnels. Si vous choisissez la connexion Google, Google intervient dans votre authentification. Les accès administratifs sont limités aux habilitations du service. Les informations nécessaires transitent vers ces prestataires ; leurs conditions et leurs lieux de traitement doivent être pris en compte.'
      ),
      (
        'Conservation et suppression',
        'Votre dossier est conservé pour le fonctionnement de votre compte. La demande de suppression dans Profil désactive immédiatement votre accès et prévoit l’effacement après un délai minimal de 30 jours. Votre e-mail ne devient réutilisable qu’une fois cet effacement terminé. Une suspension administrative est distincte. Ce processus ne supprime pas les copies que vous avez exportées ni les e-mails déjà reçus.'
      ),
      (
        'Vos demandes',
        'Pour demander l’accès, la rectification ou la suppression de vos données, écrivez à lestudioviral@gmail.com. Une vérification proportionnée de votre identité peut être nécessaire ; ne transmettez jamais de mot de passe ou de code de connexion. En cas de difficulté, vous pouvez contacter l’Autorité de Protection des Données Personnelles du Bénin : apdp.bj.'
      ),
      (
        'Informations à compléter',
        'L’adresse professionnelle de l’éditeur, les durées de conservation des journaux et sauvegardes, ainsi que les modalités des transferts internationaux restent à préciser par l’éditeur. Cette page décrit le fonctionnement actuel et ne constitue pas une attestation de conformité.'
      ),
    ]
  ),
  (
    'Conditions d’utilisation',
    [
      (
        'Le service Orientia',
        'Créé par Le Studio Viral, Orientia aide à explorer les formations, universités et bourses, avec une priorité au Bénin et une ouverture internationale. Les établissements restent seuls responsables de leurs décisions d’admission et d’attribution.'
      ),
      (
        'Votre compte et votre dossier',
        'Renseignez des informations exactes et utilisez uniquement des documents que vous êtes autorisé à transmettre. Protégez votre accès et signalez tout usage non autorisé au support. Vérifiez les notes extraites avant de confirmer votre dossier.'
      ),
      (
        'Comprendre les résultats',
        'Un score de compatibilité ne représente pas une probabilité d’admission. Les simulations sont hypothétiques et ne modifient pas votre dossier confirmé. Consultez les sources, les dates et les conditions officielles auprès des établissements avant toute candidature.'
      ),
      (
        'Usage responsable',
        'N’utilisez pas le service pour usurper une identité, transmettre des documents frauduleux, accéder aux données d’autrui ou perturber son fonctionnement. Les contenus et marques de tiers restent la propriété de leurs titulaires.'
      ),
      (
        'Disponibilité et contact',
        'Des interruptions ou données manquantes peuvent survenir. Après une erreur réseau, vérifiez votre historique avant de répéter un envoi. Pour une question ou un litige lié au service, contactez lestudioviral@gmail.com. Ces conditions ne limitent pas les droits impératifs applicables.'
      ),
    ]
  ),
  (
    'Informations sur l’éditeur',
    [
      (
        'Création',
        'Orientia est créé par Le Studio Viral, marque de SALAOU Souleyman, éditeur du service. Contact officiel : lestudioviral@gmail.com.'
      ),
      (
        'Hébergement et services',
        'Render héberge le backend et sa base PostgreSQL. Brevo assure les e-mails transactionnels. Google peut être utilisé pour la connexion au choix de l’utilisateur.'
      ),
      (
        'Identité juridique',
        'Éditeur : SALAOU Souleyman, propriétaire de la marque Le Studio Viral. L’éditeur indique ne pas disposer de numéro d’immatriculation. Son adresse professionnelle reste à communiquer pour compléter ces informations.'
      ),
    ]
  ),
];

class LegalDocumentPage extends StatelessWidget {
  final String title;
  final List<(String, String)> sections;
  const LegalDocumentPage(
      {super.key, required this.title, required this.sections});
  @override
  Widget build(BuildContext context) => BusinessScaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        const Text('Orientia · Le Studio Viral',
            style: TextStyle(
                color: Color(0xFF7138CE), fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Mise à jour : 12 novembre 2026'),
        for (final section in sections) ...[
          const SizedBox(height: 28),
          Text(section.$1,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SelectableText(section.$2, style: const TextStyle(height: 1.65)),
        ],
        const SizedBox(height: 28),
      ]));
}
