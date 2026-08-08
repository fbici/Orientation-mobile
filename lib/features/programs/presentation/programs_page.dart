import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ProgramsPage extends StatefulWidget {
  final ApiClient apiClient;
  const ProgramsPage({super.key, required this.apiClient});

  @override
  State<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends State<ProgramsPage> {
  List<dynamic> _programs = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrograms() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await widget.apiClient.getPrograms(page: 0, size: 100);
      if (mounted) setState(() { _programs = response.data['content'] ?? []; _filtered = _programs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Impossible de charger les programmes.'; _loading = false; });
    }
  }

  void _filterPrograms(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _programs;
      } else {
        _filtered = _programs.where((p) {
          final name = (p['name'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Programmes'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterPrograms,
              decoration: InputDecoration(
                hintText: 'Rechercher un programme...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _error != null
                    ? Center(child: Text(_error!))
                    : _filtered.isEmpty
                        ? Center(child: Text('Aucun programme trouve'))
                        : RefreshIndicator(
                            onRefresh: _loadPrograms,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) => _buildProgramCard(_filtered[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(dynamic program) {
    final name = program['name'] ?? 'Programme';
    final degree = program['degreeLevel'] ?? '';
    final duration = program['durationYears'] ?? 0;
    final colors = [AppTheme.primary, AppTheme.success, AppTheme.accent, AppTheme.warning, AppTheme.info];
    final color = colors[name.hashCode.abs() % colors.length];

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.menu_book_rounded, color: color, size: 22),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
                      SizedBox(height: 4),
                      Row(children: [
                        if (degree.isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(degree, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                          ),
                          SizedBox(width: 8),
                        ],
                        if (duration > 0)
                          Text('$duration ans', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
                      ]),
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
}
