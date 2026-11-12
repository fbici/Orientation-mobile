import '../../../core/widgets/business_scaffold.dart';
import 'package:flutter/material.dart';
import '../../../core/data/orientation_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/academic_models.dart';
import '../../../core/widgets/academic_widgets.dart';
import '../../decisions/presentation/decision_page.dart';

class SimulationPage extends StatefulWidget {
  final ApiClient apiClient;
  const SimulationPage({super.key, required this.apiClient});
  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  late final repo = OrientationRepository(widget.apiClient);
  final average = TextEditingController(),
      mark = TextEditingController(),
      field = TextEditingController(),
      language = TextEditingController(),
      series = TextEditingController();
  List<Json> countries = [], subjects = [];
  String? country, subject;
  AcademicProfileView? profile;
  Object? error;
  bool busy = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    for (final c in [average, mark, field, language, series]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final p = await repo.profile();
      final refs = await Future.wait([
        repo.references('locations/countries'),
        repo.references('subjects')
      ]);
      if (mounted) {
        setState(() {
          profile = p;
          countries = refs[0];
          subjects = refs[1]
              .where((s) => s['gradeScaleId'] == p.data['gradeScaleId'])
              .toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  double? value(TextEditingController c) {
    if (c.text.trim().isEmpty) return null;
    final n = double.tryParse(c.text.trim().replaceAll(',', '.'));
    if (n == null || !n.isFinite) throw const FormatException('Note invalide');
    return n;
  }

  Future<void> simulate() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final avg = value(average), grade = value(mark);
      if (grade != null && subject == null) {
        throw const FormatException('Matière requise');
      }
      final changes = <String, dynamic>{
        if (avg != null) 'modifiedGeneralAverage': avg,
        if (grade != null) 'modifiedGrades': {subject!: grade},
        if (country != null) 'modifiedCountries': [country],
        if (field.text.trim().isNotEmpty)
          'modifiedFields': separated(field.text),
        if (language.text.trim().isNotEmpty)
          'modifiedLanguage': language.text.trim(),
        if (series.text.trim().isNotEmpty)
          'modifiedBacSeries': series.text.trim()
      };
      if (changes.isEmpty) {
        throw const FormatException('Indiquez une hypothèse');
      }
      if (!mounted) return;
      await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => DecisionPage(
                  apiClient: widget.apiClient,
                  load: () => repo.simulate(changes),
                  title: 'Résultat de simulation')));
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => BusinessScaffold(
      appBar: AppBar(title: const Text('Simuler une hypothèse')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Notice(
            'Simulation hypothétique — vos résultats officiels restent inchangés.',
            warning: true),
        if (busy) const LinearProgressIndicator(),
        if (error != null) ErrorNotice(error!, onRetry: load),
        if (profile != null) ...[
          Text(
              'Moyenne de référence : ${text(profile!.data['generalAverage'], 'Issue du relevé sélectionné ou inconnue')}'),
          TextField(
              controller: average,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Autre moyenne, dans le barème confirmé')),
          referenceSelect(
              label: 'Matière à simuler',
              items: subjects,
              value: subject,
              onChanged: (v) => setState(() => subject = v),
              nameField: 'code'),
          TextField(
              controller: mark,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Note hypothétique — facultative')),
          referenceSelect(
              label: 'Autre destination',
              items: countries,
              value: country,
              onChanged: (v) => setState(() => country = v)),
          TextField(
              controller: field,
              decoration: const InputDecoration(
                  labelText: 'Autres domaines, séparés par des virgules')),
          TextField(
              controller: language,
              decoration:
                  const InputDecoration(labelText: 'Autre langue déclarée')),
          TextField(
              controller: series,
              decoration: const InputDecoration(
                  labelText: 'Autre série exacte — hypothèse explicite')),
          FilledButton(
              onPressed: busy || !profile!.confirmed ? null : simulate,
              child: const Text('Comparer à mon profil actuel')),
          if (!profile!.confirmed)
            const Notice(
                'Confirmez votre profil et son année d’admission avant de simuler.',
                warning: true),
        ],
      ]));
}
