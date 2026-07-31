import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../recommendations/presentation/recommendations_page.dart';
import '../../universities/presentation/universities_page.dart';
import '../../profile/presentation/profile_page.dart';

/// Page d'accueil avec navigation
class HomePage extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onLogout;

  const HomePage({super.key, required this.apiClient, required this.onLogout});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(apiClient: widget.apiClient),
      RecommendationsPage(apiClient: widget.apiClient),
      UniversitiesPage(apiClient: widget.apiClient),
      ProfilePage(apiClient: widget.apiClient, onLogout: widget.onLogout),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primarySurface,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primary),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.recommend_outlined),
            selectedIcon: Icon(Icons.recommend, color: AppTheme.primary),
            label: 'Recommandations',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school, color: AppTheme.primary),
            label: 'Universités',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primary),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Dashboard avec KPIs et actions rapides
class DashboardPage extends StatelessWidget {
  final ApiClient apiClient;
  const DashboardPage({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Orientation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.gray900)),
                    Text('Tableau de bord', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // KPI Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildKpiCard(Icons.school, 'Universités', '153', AppTheme.primary),
                _buildKpiCard(Icons.workspace_premium, 'Programmes', '500+', AppTheme.success),
                _buildKpiCard(Icons.flag, 'Pays', '42', AppTheme.warning),
                _buildKpiCard(Icons.recommend, 'Recommandations', '18K+', AppTheme.info),
              ],
            ),
            const SizedBox(height: 24),

            // Actions rapides
            const Text('Actions rapides', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
            const SizedBox(height: 12),
            _buildActionButton(context, Icons.recommend, 'Obtenir une recommandation', 'Basée sur votre profil académique', () {
              // Navigate to recommendations
            }),
            _buildActionButton(context, Icons.search, 'Recherche intelligente', 'Posez une question en langage naturel', () {
              // Navigate to smart query
            }),
            _buildActionButton(context, Icons.upload_file, 'Uploader un relevé', 'Importez votre bulletin scolaire', () {
              // Navigate to upload
            }),
            _buildActionButton(context, Icons.school, 'Explorer les universités', 'Parcourez les établissements', () {
              // Navigate to universities
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.gray900)),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.gray500, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.gray400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
