import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class SimulationPage extends StatefulWidget {
  final ApiClient apiClient;
  const SimulationPage({super.key, required this.apiClient});

  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  String? _selectedSerie;
  final _mathsController = TextEditingController();
  final _physiqueController = TextEditingController();
  final _svtController = TextEditingController();
  final _francaisController = TextEditingController();
  final _moyenneController = TextEditingController();
  
  bool _loading = false;
  Map<String, dynamic>? _result;
  List<dynamic> _series = [];

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  @override
  void dispose() {
    _mathsController.dispose();
    _physiqueController.dispose();
    _svtController.dispose();
    _francaisController.dispose();
    _moyenneController.dispose();
    super.dispose();
  }

  Future<void> _loadSeries() async {
    try {
      final response = await widget.apiClient.getBeninSeries();
      if (mounted) setState(() => _series = response.data ?? []);
    } catch (e) {}
  }

  Future<void> _simulate() async {
    if (_selectedSerie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selectionnez votre serie'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    setState(() { _loading = true; _result = null; });

    try {
      final response = await widget.apiClient.simulateBeninOrientation({
        'serie': _selectedSerie,
        'maths': double.tryParse(_mathsController.text) ?? 0,
        'physique': double.tryParse(_physiqueController.text) ?? 0,
        'svt': double.tryParse(_svtController.text) ?? 0,
        'francais': double.tryParse(_francaisController.text) ?? 0,
        'moyenne': double.tryParse(_moyenneController.text) ?? 0,
      });
      if (mounted) setState(() { _result = response.data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la simulation'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simulation d\'orientation'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.calculate_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Text('Simulateur Benin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'Entrez vos notes du bac pour decouvrir les filieres accessibles.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Serie selection
            Text('Votre serie', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _series.map((s) => _buildSerieChip(s)).toList(),
            ),
            const SizedBox(height: 24),

            // Notes
            Text('Vos notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildNoteField(_mathsController, 'Maths', Icons.functions_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildNoteField(_physiqueController, 'Physique', Icons.science_rounded)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildNoteField(_svtController, 'SVT', Icons.biotech_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildNoteField(_francaisController, 'Francais', Icons.menu_book_rounded)),
            ]),
            const SizedBox(height: 12),
            _buildNoteField(_moyenneController, 'Moyenne generale (optionnel)', Icons.grade_rounded),
            const SizedBox(height: 24),

            // Bouton simuler
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _simulate,
                icon: _loading
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.auto_awesome_rounded, size: 20),
                label: Text(_loading ? 'Analyse en cours...' : 'Simuler mon orientation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Resultats
            if (_result != null) ...[
              _buildResultsHeader(),
              const SizedBox(height: 16),
              if ((_result!['eligible'] as List).isNotEmpty) ...[
                _buildSectionTitle('Filiers accessibles', AppTheme.success, Icons.check_circle_rounded),
                ...((_result!['eligible'] as List).map((f) => _buildFiliereCard(f, AppTheme.success)).toList()),
                const SizedBox(height: 16),
              ],
              if ((_result!['risky'] as List).isNotEmpty) ...[
                _buildSectionTitle('Filiers risquees (FEP)', AppTheme.warning, Icons.warning_rounded),
                ...((_result!['risky'] as List).map((f) => _buildFiliereCard(f, AppTheme.warning)).toList()),
                const SizedBox(height: 16),
              ],
              if ((_result!['eligible'] as List).isEmpty && (_result!['risky'] as List).isEmpty)
                _buildNoResult(),
              const SizedBox(height: 16),
              _buildConseilCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSerieChip(dynamic serie) {
    final code = serie['code'] ?? '';
    final isSelected = _selectedSerie == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedSerie = code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.gray200),
        ),
        child: Column(
          children: [
            Text(code, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : AppTheme.gray900)),
            Text(serie['nom'] ?? '', style: TextStyle(fontSize: 10, color: isSelected ? Colors.white.withOpacity(0.8) : AppTheme.gray500)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        hintText: '0.00',
      ),
    );
  }

  Widget _buildResultsHeader() {
    final nbEligible = _result!['nbEligible'] ?? 0;
    final nbRisky = _result!['nbRisky'] ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: nbEligible > 0 ? AppTheme.successSurface : AppTheme.warningSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: nbEligible > 0 ? AppTheme.success.withOpacity(0.3) : AppTheme.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            nbEligible > 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: nbEligible > 0 ? AppTheme.success : AppTheme.warning,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$nbEligible filieres accessibles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray900),
                ),
                if (nbRisky > 0)
                  Text('$nbRisky filieres en FEP possible', style: TextStyle(fontSize: 13, color: AppTheme.gray600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color, IconData icon) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  Widget _buildFiliereCard(dynamic filiere, Color color) {
    final name = filiere['name'] ?? '';
    final faculty = filiere['faculty'] ?? '';
    final university = filiere['university'] ?? '';
    final financement = filiere['financement'] ?? '';
    final moyenne = filiere['moyennePonderee'] ?? 0;
    final bourse = filiere['bourse'] ?? 0;
    final fpp = filiere['fpp'] ?? 0;
    final fep = filiere['fep'] ?? 0;

    Color finColor = financement == 'BOURSE' ? AppTheme.success : financement == 'FPP' ? AppTheme.info : AppTheme.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
                      Text('$faculty - $university', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: finColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(financement, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: finColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMiniStat('Votre moyenne', '$moyenne', AppTheme.primary),
                const SizedBox(width: 12),
                _buildMiniStat('Bourse', '$bourse%', AppTheme.success),
                const SizedBox(width: 12),
                _buildMiniStat('FPP', '$fpp%', AppTheme.info),
                const SizedBox(width: 12),
                _buildMiniStat('FEP', '$fep%', AppTheme.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: AppTheme.gray500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildNoResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppTheme.gray400),
          const SizedBox(height: 12),
          Text('Aucune filiere trouvee', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.gray700)),
          const SizedBox(height: 8),
          Text('Essayez avec d\'autres notes ou une autre serie.', style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
        ],
      ),
    );
  }

  Widget _buildConseilCard() {
    final conseil = _result!['conseil'] ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.info.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, color: AppTheme.info, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(conseil, style: TextStyle(fontSize: 14, color: AppTheme.gray800, height: 1.5))),
        ],
      ),
    );
  }
}
