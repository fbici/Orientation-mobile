import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class RecommendationsPage extends StatefulWidget {
  final ApiClient apiClient;
  const RecommendationsPage({super.key, required this.apiClient});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  List<dynamic> _recommendations = [];
  bool _loading = true;
  bool _generating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await widget.apiClient.getRecommendations(page: 0, size: 50);
      if (mounted) {
        setState(() {
          _recommendations = response.data['content'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les recommandations.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _generateRecommendation() async {
    setState(() => _generating = true);
    try {
      await widget.apiClient.generateRecommendations({
        'algorithm': 'HYBRID',
        'maxResults': 10,
      });
      await _loadRecommendations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recommandations generees !'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la generation.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadRecommendations,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text('Recommandations IA', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Obtenez des recommandations personnalisees.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // Carte IA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.accent, AppTheme.accent.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
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
                            child: Text('Intelligence Artificielle', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 16),
                          Text('Analyse personnalisee', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            'L\'IA analyse votre profil et les criteres d\'admission pour trouver les meilleurs programmes.',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.5),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _generating ? null : _generateRecommendation,
                              icon: _generating
                                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent))
                                  : Icon(Icons.auto_awesome_rounded, size: 18),
                              label: Text(_generating ? 'Analyse en cours...' : 'Lancer l\'analyse'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.accent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Resultats
                    Text(
                      _recommendations.isEmpty ? 'Aucune recommandation' : '${_recommendations.length} recommandations',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    if (_recommendations.isEmpty)
                      _buildEmptyState()
                    else
                      ...(_recommendations.map((rec) => _buildRecommendationCard(rec)).toList()),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRecommendationCard(dynamic rec) {
    final programName = rec['programName'] ?? rec['program']?['name'] ?? 'Programme';
    final universityName = rec['universityName'] ?? rec['university']?['name'] ?? 'Universite';
    final score = rec['score'] ?? rec['matchScore'] ?? 0;
    final scorePercent = (score is num) ? (score * 100).round() : 0;
    final colors = [AppTheme.primary, AppTheme.success, AppTheme.accent, AppTheme.warning];
    final color = colors[programName.hashCode.abs() % colors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.school_rounded, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(programName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.gray900), maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(universityName, style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scorePercent >= 70 ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$scorePercent%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: scorePercent >= 70 ? AppTheme.success : AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Barre de progression
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: scorePercent / 100,
                    backgroundColor: AppTheme.gray200,
                    valueColor: AlwaysStoppedAnimation(scorePercent >= 70 ? AppTheme.success : AppTheme.warning),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppTheme.gray100, borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.auto_awesome_outlined, color: AppTheme.gray400, size: 28),
          ),
          const SizedBox(height: 16),
          Text('Aucune recommandation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.gray700)),
          const SizedBox(height: 8),
          Text(
            'Lancez votre premiere analyse pour obtenir des recommandations personnalisees.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.gray500, height: 1.5),
          ),
        ],
      ),
    );
  }
}
