import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

/// Page de recommandations
class RecommendationsPage extends StatefulWidget {
  final ApiClient apiClient;
  const RecommendationsPage({super.key, required this.apiClient});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  final _formKey = GlobalKey<FormState>();
  String? _bacType;
  double? _bacAverage;
  String? _preferredCountry;
  bool _loading = false;
  List<dynamic> _results = [];

  final List<String> _bacTypes = [
    'Sciences Experimentales',
    'Mathematiques',
    'Technique',
    'Litteraire',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recommandations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Trouvez la meilleure orientation pour votre profil', style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
            const SizedBox(height: 24),

            // Formulaire
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Votre profil', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),

                    // Type de bac
                    DropdownButtonFormField<String>(
                      value: _bacType,
                      decoration: const InputDecoration(labelText: 'Type de baccalaureat'),
                      items: _bacTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _bacType = v),
                      validator: (v) => v == null ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Moyenne
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Moyenne generale (/20)', hintText: 'ex: 14.5'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _bacAverage = double.tryParse(v),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Champ requis';
                        final n = double.tryParse(v);
                        if (n == null || n < 0 || n > 20) return 'Valeur invalide (0-20)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Pays préféré
                    DropdownButtonFormField<String>(
                      value: _preferredCountry,
                      decoration: const InputDecoration(labelText: 'Pays prefere (optionnel)'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tous les pays')),
                        DropdownMenuItem(value: 'FRA', child: Text('France')),
                        DropdownMenuItem(value: 'CAN', child: Text('Canada')),
                        DropdownMenuItem(value: 'MAR', child: Text('Maroc')),
                        DropdownMenuItem(value: 'SEN', child: Text('Senegal')),
                        DropdownMenuItem(value: 'BEN', child: Text('Benin')),
                        DropdownMenuItem(value: 'USA', child: Text('Etats-Unis')),
                        DropdownMenuItem(value: 'GBR', child: Text('Royaume-Uni')),
                      ],
                      onChanged: (v) => setState(() => _preferredCountry = v),
                    ),
                    const SizedBox(height: 24),

                    // Bouton
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _generate,
                        icon: _loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(_loading ? 'Analyse en cours...' : 'Generer les recommandations'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Résultats
            if (_results.isNotEmpty) ...[
              Text('${_results.length} recommandations', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ..._results.map((r) => _buildResultCard(r)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final response = await widget.apiClient.generateRecommendations({
        'bacType': _bacType,
        'bacAverage': _bacAverage,
        if (_preferredCountry != null) 'preferredCountries': [_preferredCountry],
      });
      setState(() {
        _results = response.data['recommendations'] ?? [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la generation'), backgroundColor: AppTheme.danger),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildResultCard(dynamic rec) {
    final score = (rec['score'] ?? 0).toDouble();
    final scoreColor = score >= 80 ? AppTheme.success : score >= 60 ? AppTheme.primary : score >= 40 ? AppTheme.warning : AppTheme.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec['programName'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(rec['universityName'] ?? '-', style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${score.round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: scoreColor)),
              ),
            ],
          ),
          if (rec['explanationSummary'] != null) ...[
            const SizedBox(height: 10),
            Text(rec['explanationSummary'], style: const TextStyle(fontSize: 12, color: AppTheme.gray600)),
          ],
        ],
      ),
    );
  }
}
