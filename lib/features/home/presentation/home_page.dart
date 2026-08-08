import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../recommendations/presentation/recommendations_page.dart';
import '../../universities/presentation/universities_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../simulation/presentation/simulation_page.dart';
import '../../documents/presentation/documents_page.dart';
import '../../programs/presentation/programs_page.dart';
import '../../scholarships/presentation/scholarships_page.dart';
import '../../chat/presentation/chat_page.dart';

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
      ChatPage(apiClient: widget.apiClient),
      ProfilePage(apiClient: widget.apiClient, onLogout: widget.onLogout),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: Offset(0, -5))],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Accueil'),
                _buildNavItem(1, Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'IA'),
                _buildNavItem(2, Icons.school_rounded, Icons.school_outlined, 'Ecoles'),
                _buildNavItem(3, Icons.chat_rounded, Icons.chat_outlined, 'Chat'),
                _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
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
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : inactiveIcon, color: isActive ? AppTheme.primary : AppTheme.gray400, size: 22),
            SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500, color: isActive ? AppTheme.primary : AppTheme.gray400)),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final ApiClient apiClient;
  const DashboardPage({super.key, required this.apiClient});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  String _userName = 'Utilisateur';
  int _universityCount = 0;
  int _countryCount = 0;
  int _recommendationCount = 0;
  int _scholarshipCount = 0;
  int _documentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userResponse = await widget.apiClient.getMe();
      if (mounted) setState(() {
        _userName = '${userResponse.data['firstName'] ?? ''} ${userResponse.data['lastName'] ?? ''}'.trim();
        if (_userName.isEmpty) _userName = 'Utilisateur';
      });
    } catch (e) {}

    try {
      final uniResponse = await widget.apiClient.getUniversities(page: 0, size: 1);
      if (mounted) setState(() => _universityCount = uniResponse.data['totalElements'] ?? 0);
    } catch (e) {}

    try {
      final countriesResponse = await widget.apiClient.getCountries();
      if (mounted) setState(() => _countryCount = (countriesResponse.data as List?)?.length ?? 0);
    } catch (e) {}

    try {
      final recResponse = await widget.apiClient.getRecommendations(page: 0, size: 1);
      if (mounted) setState(() => _recommendationCount = recResponse.data['totalElements'] ?? 0);
    } catch (e) {}

    try {
      final schResponse = await widget.apiClient.getScholarships(page: 0, size: 1);
      if (mounted) setState(() => _scholarshipCount = schResponse.data['totalElements'] ?? 0);
    } catch (e) {}

    try {
      final docResponse = await widget.apiClient.getDocuments(page: 0, size: 1);
      if (mounted) setState(() => _documentCount = docResponse.data['totalElements'] ?? 0);
    } catch (e) {}

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/images/orientia.png', fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.school_rounded, color: Colors.white, size: 22)),
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bonjour, $_userName', style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                        Text('Trouvez votre voie', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 28),

              // Hero card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text('IA Active', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    SizedBox(height: 16),
                    Text('Decouvrez les meilleures\nuniversites pour vous', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.3)),
                    SizedBox(height: 12),
                    Text('Notre IA analyse votre profil et vous recommande les programmes les plus adaptes.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.5)),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SimulationPage(apiClient: widget.apiClient))),
                            icon: Icon(Icons.calculate_rounded, size: 18),
                            label: Text('Simuler', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primary,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentsPage(apiClient: widget.apiClient))),
                            icon: Icon(Icons.upload_file_rounded, size: 18),
                            label: Text('Bulletin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28),

              // Stats
              Text('Statistiques', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildStatCard(Icons.school_rounded, _loading ? '...' : '$_universityCount', 'Universites', AppTheme.primary)),
                  SizedBox(width: 10),
                  Expanded(child: _buildStatCard(Icons.auto_awesome_rounded, _loading ? '...' : '$_recommendationCount', 'Recommand.', AppTheme.success)),
                  SizedBox(width: 10),
                  Expanded(child: _buildStatCard(Icons.workspace_premium_rounded, _loading ? '...' : '$_scholarshipCount', 'Bourses', AppTheme.warning)),
                  SizedBox(width: 10),
                  Expanded(child: _buildStatCard(Icons.description_rounded, _loading ? '...' : '$_documentCount', 'Documents', AppTheme.info)),
                ],
              ),
              SizedBox(height: 28),

              // Actions
              Text('Explorer', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 14),
              _buildActionCard(context, Icons.school_rounded, 'Universites', 'Explorez les etablissements', AppTheme.primary, AppTheme.primarySurface, () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversitiesPage(apiClient: widget.apiClient)))),
              SizedBox(height: 10),
              _buildActionCard(context, Icons.menu_book_rounded, 'Programmes', 'Decouvrez les filieres', AppTheme.accent, AppTheme.accentSurface, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramsPage(apiClient: widget.apiClient)))),
              SizedBox(height: 10),
              _buildActionCard(context, Icons.workspace_premium_rounded, 'Bourses', 'Trouvez les bourses', AppTheme.warning, AppTheme.warningSurface, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScholarshipsPage(apiClient: widget.apiClient)))),
              SizedBox(height: 10),
              _buildActionCard(context, Icons.upload_file_rounded, 'Mes documents', 'Importez vos bulletins', AppTheme.success, AppTheme.successSurface, () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentsPage(apiClient: widget.apiClient)))),
              SizedBox(height: 10),
              _buildActionCard(context, Icons.description_rounded, 'Guides', 'Consultez les guides', AppTheme.info, AppTheme.infoSurface, () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Guides disponibles dans la section Ecoles'), backgroundColor: AppTheme.info));
              }),
              SizedBox(height: 10),
              _buildActionCard(context, Icons.chat_rounded, 'Assistant IA', 'Posez vos questions', AppTheme.primary, AppTheme.primarySurface, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(apiClient: widget.apiClient)));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.gray200)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.gray900)),
          SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppTheme.gray500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, String subtitle, Color iconColor, Color bgColor, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.gray200)),
          child: Row(
            children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 20)),
              SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
              ])),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.gray300),
            ],
          ),
        ),
      ),
    );
  }
}
