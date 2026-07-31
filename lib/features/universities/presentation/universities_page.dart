import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

/// Page des universités
class UniversitiesPage extends StatefulWidget {
  final ApiClient apiClient;
  const UniversitiesPage({super.key, required this.apiClient});

  @override
  State<UniversitiesPage> createState() => _UniversitiesPageState();
}

class _UniversitiesPageState extends State<UniversitiesPage> {
  List<dynamic> _universities = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  Future<void> _loadUniversities() async {
    setState(() => _loading = true);
    try {
      final response = await widget.apiClient.getUniversities(size: 100);
      setState(() {
        _universities = response.data['content'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? _universities
        : _universities.where((u) => (u['name'] ?? '').toLowerCase().contains(_search.toLowerCase())).toList();

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Universites', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${_universities.length} etablissements', style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
                const SizedBox(height: 16),
                // Search
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une universite...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gray200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gray200)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('Aucune universite trouvee', style: TextStyle(color: AppTheme.gray400)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _buildUniversityCard(filtered[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniversityCard(dynamic uni) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: Navigate to detail
          },
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(uni['name'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
                      const SizedBox(height: 2),
                      Text(
                        '${uni['country']?['name'] ?? ''} ${uni['city']?['name'] != null ? '· ${uni['city']['name']}' : ''}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.gray500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: uni['status'] == 'ACTIVE' ? AppTheme.success.withOpacity(0.1) : AppTheme.gray100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    uni['status'] == 'ACTIVE' ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: uni['status'] == 'ACTIVE' ? AppTheme.success : AppTheme.gray500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
