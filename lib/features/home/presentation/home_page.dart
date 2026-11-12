import '../../../core/widgets/business_scaffold.dart';
import '../../navigation/presentation/workspace_pages.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/data/orientation_repository.dart';
import '../../../core/models/academic_models.dart';
import '../../../core/widgets/academic_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_widgets.dart';
import '../../recommendations/presentation/recommendations_page.dart';
import '../../universities/presentation/universities_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../profile/presentation/academic_profile_page.dart';
import '../../simulation/presentation/simulation_page.dart';
import '../../documents/presentation/documents_page.dart';
import '../../programs/presentation/programs_page.dart';
import '../../scholarships/presentation/scholarships_page.dart';
import '../../chat/presentation/chat_page.dart';
import '../../history/presentation/history_page.dart';

class HomePage extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onLogout;
  const HomePage({super.key, required this.apiClient, required this.onLogout});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int current = 0;
  final pages = <int, Widget>{};
  Widget page(int index) => pages.putIfAbsent(
      index,
      () => switch (index) {
            0 => DashboardPage(
                apiClient: widget.apiClient,
                onProfile: () => setState(() => current = 4)),
            1 => WorkspacePage(apiClient: widget.apiClient, explore: true),
            2 => WorkspacePage(apiClient: widget.apiClient),
            3 => ChatPage(apiClient: widget.apiClient),
            _ => ProfilePage(
                apiClient: widget.apiClient, onLogout: widget.onLogout),
          });
  @override
  Widget build(BuildContext context) {
    page(current);
    return BusinessScaffold(
        body: IndexedStack(index: current, children: [
          for (int i = 0; i < 5; i++) pages[i] ?? const SizedBox.shrink()
        ]),
        bottomNavigationBar: NavigationBar(
            selectedIndex: current,
            onDestinationSelected: (v) => setState(() {
                  if (v == 0 && current != 0) pages.remove(0);
                  current = v;
                }),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Accueil'),
              NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Explorer'),
              NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: 'Parcours'),
              NavigationDestination(
                  icon: Icon(Icons.chat_outlined),
                  selectedIcon: Icon(Icons.chat),
                  label: 'Assistant'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profil'),
            ]));
  }
}

class DashboardPage extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback? onProfile;
  const DashboardPage({super.key, required this.apiClient, this.onProfile});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int revision = 0;
  ApiClient get apiClient => widget.apiClient;
  @override
  Widget build(BuildContext context) => BusinessScaffold(
      appBar: AppBar(title: const BrandLogo(height: 42), actions: [
        if (widget.onProfile != null)
          IconButton(
              onPressed: widget.onProfile,
              icon: const Icon(Icons.person_outline),
              tooltip: 'Mon profil')
      ]),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('Votre avenir, à votre rythme',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gray600))),
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            'Bienvenue ${text(apiClient.user?['firstName'], '')}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        const Text(
                            'Comprendre vos possibilités, préparer votre parcours.',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.5)),
                      ])),
                  if (MediaQuery.sizeOf(context).width > 370 &&
                      MediaQuery.textScalerOf(context).scale(1) < 1.4)
                    Image.asset('assets/images/welcome_orientation.png',
                        height: 135,
                        width: 110,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true),
                ])),
            const SizedBox(height: 16),
            AsyncContent<AcademicProfileView>(
                key: ValueKey(revision),
                load: OrientationRepository(apiClient).profile,
                builder: (p, reload) => Card(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(
                                    p.confirmed
                                        ? Icons.verified_outlined
                                        : Icons.route_rounded,
                                    color: AppTheme.primary),
                                const SizedBox(width: 10),
                                const Expanded(
                                    child: Text('Votre prochaine étape',
                                        style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700)))
                              ]),
                              const SizedBox(height: 12),
                              Text(
                                  p.confirmed
                                      ? 'Explorez vos recommandations'
                                      : 'Complétez votre profil académique',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.gray900)),
                              const SizedBox(height: 6),
                              Text(p.confirmed
                                  ? 'Votre profil est confirmé. Lancez un calcul pour comprendre vos possibilités.'
                                  : 'Ajoutez vos informations et votre relevé pour préparer un choix éclairé.'),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                            builder: (_) => p.confirmed
                                                ? RecommendationsPage(
                                                    apiClient: apiClient)
                                                : AcademicProfilePage(
                                                    apiClient: apiClient)));
                                    if (mounted) reload();
                                  },
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: Text(p.confirmed
                                      ? 'Voir mes possibilités'
                                      : 'Compléter mon profil')),
                            ])))),
            const SizedBox(height: 24),
            const Text('Préparez votre parcours',
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.gray900)),
            const SizedBox(height: 6),
            const Text('Vos outils d’orientation, réunis au même endroit.'),
            const SizedBox(height: 16),
            for (final action in <(String, String, IconData, Widget)>[
              (
                'Mon profil académique',
                'Pays, années, notes et préférences',
                Icons.edit_document,
                AcademicProfilePage(apiClient: apiClient)
              ),
              (
                'Mes relevés',
                'Envoyer, analyser, corriger et confirmer',
                Icons.upload_file,
                DocumentsPage(apiClient: apiClient)
              ),
              (
                'Mes recommandations',
                'Éligibilité et explications sourcées',
                Icons.auto_awesome,
                RecommendationsPage(apiClient: apiClient)
              ),
              (
                'Explorer les formations',
                'Sélectionner et comparer deux à six formations',
                Icons.menu_book_rounded,
                ProgramsPage(apiClient: apiClient)
              ),
              (
                'Simuler une hypothèse',
                'Sans modifier votre profil confirmé',
                Icons.tune,
                SimulationPage(apiClient: apiClient)
              ),
              (
                'Universités',
                'Campus, facultés et formations',
                Icons.account_balance_outlined,
                UniversitiesPage(apiClient: apiClient)
              ),
              (
                'Assistant Orientia',
                'Questions et conversations',
                Icons.chat_outlined,
                ChatPage(apiClient: apiClient)
              ),
              (
                'Bourses',
                'Disponibilité et éligibilité séparées',
                Icons.savings_outlined,
                ScholarshipsPage(apiClient: apiClient)
              ),
              (
                'Historique et exports',
                'Décisions enregistrées, PDF, CSV et Excel',
                Icons.history,
                HistoryPage(apiClient: apiClient)
              ),
            ])
              Card(
                  child: ListTile(
                      leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                              color: AppTheme.primarySurface,
                              borderRadius: BorderRadius.circular(15)),
                          child: Icon(action.$3, color: AppTheme.primary)),
                      title: Text(action.$1),
                      subtitle: Text(action.$2),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(context,
                            MaterialPageRoute<void>(builder: (_) => action.$4));
                        if (mounted) setState(() => revision++);
                      })),
          ]));
}
