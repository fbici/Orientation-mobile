import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../recommendations/presentation/recommendations_page.dart';
import '../../universities/presentation/universities_page.dart';
import '../../profile/presentation/profile_page.dart';

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
      DashboardPage(apiClient: widget.apiClient, onNavigate: _navigateToTab),
      RecommendationsPage(apiClient: widget.apiClient),
      UniversitiesPage(apiClient: widget.apiClient),
      ProfilePage(apiClient: widget.apiClient, onLogout: widget.onLogout),
    ];
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Accueil'),
                _buildNavItem(1, Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'IA'),
                _buildNavItem(2, Icons.school_rounded, Icons.school_outlined, 'Ecoles'),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppTheme.primary : AppTheme.gray400,
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dashboard dynamique avec donnees depuis l'API
class DashboardPage extends StatefulWidget {
  final ApiClient apiClient;
  final Function(int) onNavigate;
  const DashboardPage({super.key, required this.apiClient, required this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  String _userName = 'Utilisateur';
  int _universityCount = 0;
  int _countryCount = 0;
  int _recommendationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Charger le profil utilisateur
      final userResponse = await widget.apiClient.getMe();
      if (mounted) {
        setState(() {
          _userName = '${userResponse.data['firstName'] ?? ''} ${userResponse.data['lastName'] ?? ''}'.trim();
          if (_userName.isEmpty) _userName = 'Utilisateur';
        });
      }
    } catch (e) {
      // Utiliser les valeurs par defaut
    }

    try {
      // Charger les universites
      final uniResponse = await widget.apiClient.getUniversities(page: 0, size: 1);
      if (mounted) {
        setState(() {
          _universityCount = uniResponse.data['totalElements'] ?? 0;
        });
      }
    } catch (e) {}

    try {
      // Charger les pays
      final countriesResponse = await widget.apiClient.getCountries();
      if (mounted) {
        setState(() {
          _countryCount = (countriesResponse.data as List?)?.length ?? 0;
        });
      }
    } catch (e) {}

    try {
      // Charger les recommandations
      final recResponse = await widget.apiClient.getRecommendations(page: 0, size: 1);
      if (mounted) {
        setState(() {
          _recommendationCount = recResponse.data['totalElements'] ?? 0;
        });
      }
    } catch (e) {}

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec nom utilisateur
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/orientia.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour, $_userName',
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Trouvez votre voie',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Carte hero avec bouton fonctionnel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'IA Active',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Decouvrez les meilleures\nuniversites pour vous',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Notre IA analyse votre profil et vous recommande les programmes les plus adaptes.',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => widget.onNavigate(1), // Navigue vers l'onglet IA
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text('Obtenir une recommandation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Stats dynamiques
              Text('Statistiques', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildStatCard(Icons.school_rounded, _loading ? '...' : '$_universityCount', 'Universites', AppTheme.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(Icons.public_rounded, _loading ? '...' : '$_countryCount', 'Pays', AppTheme.warning)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(Icons.recommend_rounded, _loading ? '...' : '$_recommendationCount', 'Recommand.', AppTheme.success)),
                ],
              ),
              const SizedBox(height: 28),

              // Actions rapides fonctionnelles
              Text('Actions rapides', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              _buildActionCard(context, Icons.auto_awesome_rounded, 'Recommandation IA', 'Analyse personnalisee', AppTheme.accent, AppTheme.accentSurface, () => widget.onNavigate(1)),
              const SizedBox(height: 10),
              _buildActionCard(context, Icons.school_rounded, 'Explorer ecoles', 'Parcourez les universites', AppTheme.primary, AppTheme.primarySurface, () => widget.onNavigate(2)),
              const SizedBox(height: 10),
              _buildActionCard(context, Icons.upload_file_rounded, 'Uploader releve', 'Importez vos notes', AppTheme.success, AppTheme.successSurface, () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bientot disponible')));
              }),
              const SizedBox(height: 10),
              _buildActionCard(context, Icons.search_rounded, 'Recherche intelligente', 'Posez vos questions', AppTheme.info, AppTheme.infoSurface, () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bientot disponible')));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.gray900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.gray500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, String subtitle, Color iconColor, Color bgColor, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.gray300),
            ],
          ),
        ),
      ),
    );
  }
}
