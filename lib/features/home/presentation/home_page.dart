import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/data/orientation_repository.dart';
import '../../../core/models/academic_models.dart';
import '../../../core/widgets/academic_widgets.dart';
import '../../../core/theme/app_theme.dart';
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
            0 => DashboardPage(apiClient: widget.apiClient),
            1 => UniversitiesPage(apiClient: widget.apiClient),
            2 => RecommendationsPage(apiClient: widget.apiClient),
            3 => ChatPage(apiClient: widget.apiClient),
            _ => ProfilePage(
                apiClient: widget.apiClient, onLogout: widget.onLogout),
          });
  @override
  Widget build(BuildContext context) {
    page(current);
    return Scaffold(
        body: IndexedStack(index: current, children: [
          for (int i = 0; i < 5; i++) pages[i] ?? const SizedBox.shrink()
        ]),
        bottomNavigationBar: NavigationBar(
            selectedIndex: current,
            onDestinationSelected: (v) => setState(() => current = v),
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

class DashboardPage extends StatelessWidget {
  final ApiClient apiClient;
  const DashboardPage({super.key, required this.apiClient});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Orientia')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bienvenue ${text(apiClient.user?['firstName'], '')}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const Text(
                  'Comprendre vos possibilités, préparer votre parcours.',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ])),
        const SizedBox(height: 16),
        AsyncContent<AcademicProfileView>(
            load: OrientationRepository(apiClient).profile,
            builder: (p, reload) => Notice(p.confirmed
                ? 'Votre profil est confirmé personnellement. Vous pouvez demander un calcul.'
                : 'Commencez par votre profil, puis ajoutez votre relevé. La confirmation personnelle n’est pas une certification.')),
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
            Icons.school_outlined,
            ProgramsPage(apiClient: apiClient)
          ),
          (
            'Simuler une hypothèse',
            'Sans modifier votre profil confirmé',
            Icons.tune,
            SimulationPage(apiClient: apiClient)
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
                  leading: Icon(action.$3, color: AppTheme.primary),
                  title: Text(action.$1),
                  subtitle: Text(action.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute<void>(builder: (_) => action.$4)))),
      ]));
}
