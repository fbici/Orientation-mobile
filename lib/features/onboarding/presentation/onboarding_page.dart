import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;
  const OnboardingPage({super.key, required this.apiClient, required this.onComplete, this.onSkip});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _loading = false;

  // Donnees personnelles
  List<dynamic> _countries = [];
  List<dynamic> _cities = [];
  String? _selectedCountryId;
  String? _selectedCityId;

  // Situation academique
  String? _selectedSerie;
  String? _selectedNiveau;
  final _etablissementController = TextEditingController();
  final _anneeController = TextEditingController(text: '2025');

  // Preferences
  List<String> _selectedDomaines = [];
  List<String> _selectedPays = [];
  String? _selectedNiveauEtudes;
  String? _selectedBudget;
  bool _prefereBourse = false;
  bool _preferePublic = true;

  final List<String> _domaines = [
    'Informatique', 'Medecine', 'Droit', 'Economie', 'Genie civil',
    'Lettres', 'Sciences', 'Agronomie', 'Commerce', 'Architecture',
    'Psychologie', 'Education', 'Journalisme', 'Tourisme',
  ];

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _etablissementController.dispose();
    _anneeController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    try {
      final response = await widget.apiClient.getCountries();
      if (mounted) setState(() => _countries = response.data ?? []);
    } catch (e) {}
  }

  Future<void> _loadCities(String countryId) async {
    try {
      final response = await widget.apiClient.getCities(countryId);
      if (mounted) setState(() { _cities = response.data ?? []; _selectedCityId = null; });
    } catch (e) {}
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    try {
      await widget.apiClient.updateCandidateProfile({
        if (_selectedCountryId != null) 'countryId': _selectedCountryId,
        if (_selectedCityId != null) 'cityId': _selectedCityId,
        if (_selectedSerie != null) 'bacType': _selectedSerie,
        if (_selectedNiveau != null) 'niveau': _selectedNiveau,
        if (_etablissementController.text.isNotEmpty) 'highSchool': _etablissementController.text,
        if (_selectedDomaines.isNotEmpty) 'preferredDomains': _selectedDomaines,
        if (_selectedPays.isNotEmpty) 'preferredCountries': _selectedPays,
        if (_selectedNiveauEtudes != null) 'preferredLevel': _selectedNiveauEtudes,
        if (_selectedBudget != null) 'budget': _selectedBudget,
        'preferBourse': _prefereBourse,
        'preferPublic': _preferePublic,
      });
      widget.onComplete();
    } catch (e) {
      // Meme si l'API n'existe pas encore, on continue
      widget.onComplete();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: List.generate(4, (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: i <= _currentPage ? AppTheme.primary : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
              ),
              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildPersonalInfoPage(),
                    _buildAcademicPage(),
                    _buildPreferencesPage(),
                    _buildSummaryPage(),
                  ],
                ),
              ),
              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Skip button
                    if (_currentPage < 3 && widget.onSkip != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: widget.onSkip,
                          child: Text(
                            'Passer pour l\'instant',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pageController.previousPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text('Retour'),
                            ),
                          ),
                        if (_currentPage > 0) const SizedBox(width: 12),
                        Expanded(
                          flex: _currentPage > 0 ? 2 : 1,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _nextPage,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _loading
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(_currentPage == 3 ? 'Terminer' : 'Continuer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                      const SizedBox(width: 8),
                                      Icon(_currentPage == 3 ? Icons.check_rounded : Icons.arrow_forward_rounded, size: 20),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person_rounded, color: AppTheme.primary, size: 40),
          const SizedBox(height: 16),
          Text('Informations personnelles', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Dites-nous en plus sur vous.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15)),
          const SizedBox(height: 32),
          Text('Pays de residence *', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._countries.map((c) => _buildSelectionTile(
            c['name'] ?? '',
            Icons.public_rounded,
            _selectedCountryId == c['id'],
            () { setState(() => _selectedCountryId = c['id']); _loadCities(c['id']); },
          )),
          if (_selectedCountryId != null && _cities.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Ville', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._cities.take(10).map((c) => _buildSelectionTile(
              c['name'] ?? '',
              Icons.location_city_rounded,
              _selectedCityId == c['id'],
              () => setState(() => _selectedCityId = c['id']),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAcademicPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.school_rounded, color: AppTheme.primary, size: 40),
          const SizedBox(height: 16),
          Text('Situation academique', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Parlez-nous de votre parcours scolaire.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15)),
          const SizedBox(height: 32),
          Text('Niveau actuel *', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...['Bac', 'Bac+1', 'Bac+2', 'Bac+3', 'Bac+4', 'Bac+5', 'Autre'].map((n) => _buildSelectionTile(
            n, Icons.grade_rounded, _selectedNiveau == n,
            () => setState(() => _selectedNiveau = n),
          )),
          const SizedBox(height: 20),
          Text('Serie / Filiere', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...['C', 'D', 'A', 'B', 'D', 'G2', 'TMD', 'Autre'].toSet().map((s) => _buildSelectionTile(
            'Serie $s', Icons.class_rounded, _selectedSerie == s,
            () => setState(() => _selectedSerie = s),
          )),
          const SizedBox(height: 20),
          Text('Etablissement', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _etablissementController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nom de votre etablissement',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: Icon(Icons.business_rounded, color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
          ),
          const SizedBox(height: 16),
          Text('Annee academique', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _anneeController,
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '2025',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: Icon(Icons.calendar_today_rounded, color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tune_rounded, color: AppTheme.primary, size: 40),
          const SizedBox(height: 16),
          Text('Vos preferences', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Pour des recommandations personnalisees.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15)),
          const SizedBox(height: 32),
          Text('Domaines d\'etudes interessants *', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _domaines.map((d) {
              final isSelected = _selectedDomaines.contains(d);
              return GestureDetector(
                onTap: () => setState(() {
                  isSelected ? _selectedDomaines.remove(d) : _selectedDomaines.add(d);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.15)),
                  ),
                  child: Text(d, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Niveau d\'etudes souhaite', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...['Licence', 'Master', 'Doctorat', 'Formation professionnelle'].map((n) => _buildSelectionTile(
            n, Icons.school_rounded, _selectedNiveauEtudes == n,
            () => setState(() => _selectedNiveauEtudes = n),
          )),
          const SizedBox(height: 20),
          Text('Budget approximatif', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...['Gratuit (bourse)', 'Moins de 100 000 FCFA', '100 000 - 500 000 FCFA', 'Plus de 500 000 FCFA', 'Pas de contrainte'].map((b) => _buildSelectionTile(
            b, Icons.payments_rounded, _selectedBudget == b,
            () => setState(() => _selectedBudget = b),
          )),
          const SizedBox(height: 20),
          // Toggle bourse
          _buildToggleTile('Je privilegie les bourses', Icons.workspace_premium_rounded, _prefereBourse, (v) => setState(() => _prefereBourse = v)),
          const SizedBox(height: 8),
          _buildToggleTile('Universites publiques uniquement', Icons.account_balance_rounded, _preferePublic, (v) => setState(() => _preferePublic = v)),
        ],
      ),
    );
  }

  Widget _buildSummaryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 40),
          const SizedBox(height: 16),
          Text('Resume de votre profil', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Verifiez vos informations avant de continuer.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15)),
          const SizedBox(height: 32),
          _buildSummaryCard('Pays', _countries.firstWhere((c) => c['id'] == _selectedCountryId, orElse: () => {'name': 'Non renseigne'})['name'] ?? 'Non renseigne'),
          _buildSummaryCard('Niveau', _selectedNiveau ?? 'Non renseigne'),
          _buildSummaryCard('Serie', _selectedSerie != null ? 'Serie $_selectedSerie' : 'Non renseigne'),
          _buildSummaryCard('Etablissement', _etablissementController.text.isNotEmpty ? _etablissementController.text : 'Non renseigne'),
          _buildSummaryCard('Domaines', _selectedDomaines.isNotEmpty ? _selectedDomaines.join(', ') : 'Non renseigne'),
          _buildSummaryCard('Niveau souhaite', _selectedNiveauEtudes ?? 'Non renseigne'),
          _buildSummaryCard('Budget', _selectedBudget ?? 'Non renseigne'),
          _buildSummaryCard('Bourse', _prefereBourse ? 'Oui' : 'Non'),
        ],
      ),
    );
  }

  Widget _buildSelectionTile(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.15) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.4), size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400))),
              if (isSelected) Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile(String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: Colors.white, fontSize: 14))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Text('$label :', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}
