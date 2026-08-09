import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class UniversitiesPage extends StatefulWidget {
  final ApiClient apiClient;
  const UniversitiesPage({super.key, required this.apiClient});

  @override
  State<UniversitiesPage> createState() => _UniversitiesPageState();
}

class _UniversitiesPageState extends State<UniversitiesPage> {
  final _searchController = TextEditingController();
  List<dynamic> _universities = [];
  List<dynamic> _filtered = [];
  List<dynamic> _countries = [];
  bool _loading = true;
  String? _error;
  String? _selectedCountryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final uniResponse = await widget.apiClient.getUniversities(page: 0, size: 100);
      final countriesResponse = await widget.apiClient.getCountries();
      if (mounted) {
        setState(() {
          _universities = uniResponse.data['content'] ?? [];
          _filtered = _universities;
          _countries = countriesResponse.data ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les universites.';
          _loading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _universities.where((u) {
        final name = (u['name'] ?? '').toString().toLowerCase();
        final matchesSearch = query.isEmpty || name.contains(query);
        final matchesCountry = _selectedCountryId == null || (u['countryId'] ?? '') == _selectedCountryId;
        return matchesSearch && matchesCountry;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header fixe
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Universites', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  '${_filtered.length} etablissements',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                // Filtres pays
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildChip('Toutes', _selectedCountryId == null, () {
                        setState(() => _selectedCountryId = null);
                        _applyFilters();
                      }),
                      ..._countries.take(8).map((c) => _buildChip(
                        c['name'] ?? '',
                        _selectedCountryId == c['id'],
                        () {
                          setState(() => _selectedCountryId = c['id']);
                          _applyFilters();
                        },
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Liste scrollable
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.gray400),
                              SizedBox(height: 12),
                              Text(_error!, style: TextStyle(color: AppTheme.gray500), textAlign: TextAlign.center),
                              SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _loadData,
                                icon: Icon(Icons.refresh_rounded, size: 18),
                                label: Text('Reessayer'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 48, color: AppTheme.gray400),
                                  SizedBox(height: 12),
                                  Text('Aucune universite trouvee', style: TextStyle(color: AppTheme.gray500)),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) => _buildUniversityCard(_filtered[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isActive ? AppTheme.primary : AppTheme.gray200),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppTheme.gray600),
          ),
        ),
      ),
    );
  }

  Widget _buildUniversityCard(dynamic uni) {
    final name = uni['name'] ?? 'Sans nom';
    final acronym = uni['acronym'] ?? '';
    final type = uni['type'] ?? 'Universite';
    final colors = [AppTheme.primary, AppTheme.success, AppTheme.accent, AppTheme.warning, AppTheme.info];
    final color = colors[name.hashCode.abs() % colors.length];

    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetail(uni),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Text(
                      acronym.isNotEmpty ? acronym.substring(0, acronym.length.clamp(0, 3)) : name.substring(0, name.length.clamp(0, 2)),
                      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900), maxLines: 2, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.gray300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(dynamic uni) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.gray300, borderRadius: BorderRadius.circular(2)))),
              SizedBox(height: 20),
              Text(uni['name'] ?? 'Sans nom', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              if (uni['acronym'] != null) ...[
                SizedBox(height: 4),
                Text(uni['acronym'], style: TextStyle(fontSize: 14, color: AppTheme.gray500)),
              ],
              SizedBox(height: 20),
              if (uni['website'] != null) _buildRow(Icons.language_rounded, 'Site web', uni['website']),
              if (uni['email'] != null) _buildRow(Icons.mail_outline_rounded, 'Email', uni['email']),
              if (uni['phone'] != null) _buildRow(Icons.phone_outlined, 'Telephone', uni['phone']),
              if (uni['address'] != null) _buildRow(Icons.location_on_outlined, 'Adresse', uni['address']),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Fermer'),
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.gray400),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
                Text(value, style: TextStyle(fontSize: 14, color: AppTheme.gray800, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
