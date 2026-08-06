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
  String? _selectedCountry;

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

  void _filterBySearch(String query) {
    setState(() {
      if (query.isEmpty && _selectedCountry == null) {
        _filtered = _universities;
      } else {
        _filtered = _universities.where((u) {
          final name = (u['name'] ?? '').toString().toLowerCase();
          final matchesSearch = query.isEmpty || name.contains(query.toLowerCase());
          final matchesCountry = _selectedCountry == null || (u['countryId'] ?? '') == _selectedCountry;
          return matchesSearch && matchesCountry;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Universites', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  '${_filtered.length} etablissements trouves',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.gray200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterBySearch,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une universite...',
                      hintStyle: TextStyle(color: AppTheme.gray400, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: AppTheme.gray400, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filtres pays
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildChip('Toutes', _selectedCountry == null, () {
                        setState(() => _selectedCountry = null);
                        _filterBySearch(_searchController.text);
                      }),
                      ..._countries.take(10).map((c) => _buildChip(
                        c['name'] ?? '',
                        _selectedCountry == c['id'],
                        () {
                          setState(() => _selectedCountry = c['id']);
                          _filterBySearch(_searchController.text);
                        },
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Liste
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.gray400),
                            const SizedBox(height: 12),
                            Text(_error!, style: TextStyle(color: AppTheme.gray500)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _loadData,
                              icon: Icon(Icons.refresh_rounded, size: 18),
                              label: Text('Reessayer'),
                            ),
                          ],
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: AppTheme.gray400),
                                const SizedBox(height: 12),
                                Text('Aucune universite trouvee', style: TextStyle(color: AppTheme.gray500)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final uni = _filtered[index];
                                return _buildUniversityCard(uni);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? AppTheme.primary : AppTheme.gray200),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppTheme.gray600),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              builder: (ctx) => _buildDetailSheet(uni),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      acronym.isNotEmpty ? acronym.substring(0, acronym.length.clamp(0, 3)) : name.substring(0, name.length.clamp(0, 2)),
                      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.gray900), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.gray300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSheet(dynamic uni) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.gray300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(uni['name'] ?? 'Sans nom', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.gray900)),
              const SizedBox(height: 8),
              if (uni['acronym'] != null)
                Text(uni['acronym'], style: TextStyle(fontSize: 14, color: AppTheme.gray500)),
              const SizedBox(height: 20),
              if (uni['website'] != null) _buildDetailRow(Icons.language_rounded, 'Site web', uni['website']),
              if (uni['email'] != null) _buildDetailRow(Icons.mail_outline_rounded, 'Email', uni['email']),
              if (uni['phone'] != null) _buildDetailRow(Icons.phone_outlined, 'Telephone', uni['phone']),
              if (uni['address'] != null) _buildDetailRow(Icons.location_on_outlined, 'Adresse', uni['address']),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(Icons.check_rounded, size: 18),
                  label: Text('Fermer'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.gray400),
          const SizedBox(width: 12),
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
