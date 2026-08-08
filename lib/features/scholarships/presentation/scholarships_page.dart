import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ScholarshipsPage extends StatefulWidget {
  final ApiClient apiClient;
  const ScholarshipsPage({super.key, required this.apiClient});

  @override
  State<ScholarshipsPage> createState() => _ScholarshipsPageState();
}

class _ScholarshipsPageState extends State<ScholarshipsPage> {
  List<dynamic> _scholarships = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScholarships();
  }

  Future<void> _loadScholarships() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await widget.apiClient.getScholarships();
      if (mounted) setState(() { _scholarships = response.data['content'] ?? []; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Impossible de charger les bourses.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bourses'), backgroundColor: Colors.white, elevation: 0),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadScholarships,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.warning, AppTheme.warning.withOpacity(0.8)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 32),
                          SizedBox(height: 12),
                          Text('Bourses disponibles', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          Text('Decouvrez les bourses auxquelles vous pouvez pretendre.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Text('${_scholarships.length} bourses', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 12),
                    if (_scholarships.isEmpty)
                      _buildEmptyState()
                    else
                      ..._scholarships.map((s) => _buildScholarshipCard(s)).toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildScholarshipCard(dynamic scholarship) {
    final name = scholarship['name'] ?? 'Bourse';
    final org = scholarship['organization'] ?? scholarship['provider'] ?? '';
    final amount = scholarship['amount'] ?? scholarship['financement'] ?? '';
    final country = scholarship['country'] ?? scholarship['countryName'] ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.gray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.workspace_premium_rounded, color: AppTheme.warning, size: 22),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
                      if (org.isNotEmpty) Text(org, style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (country.isNotEmpty) _buildChip(country, AppTheme.primary),
                if (amount.isNotEmpty) _buildChip(amount, AppTheme.success),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.gray200)),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_outlined, size: 48, color: AppTheme.gray400),
          SizedBox(height: 12),
          Text('Aucune bourse disponible', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.gray700)),
          SizedBox(height: 8),
          Text('Les bourses apparaitront ici quand elles seront ajoutees par les administrateurs.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppTheme.gray500, height: 1.5)),
        ],
      ),
    );
  }
}
