import 'package:flutter/material.dart';
import '../../../core/models/academic_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/data/orientation_repository.dart';
import '../../../core/widgets/academic_widgets.dart';
import '../../../core/files/report_files.dart';

class ExportButtons extends StatefulWidget {
  final ApiClient apiClient;
  final String id;
  final bool simulation;
  const ExportButtons(
      {super.key,
      required this.apiClient,
      required this.id,
      this.simulation = false});
  @override
  State<ExportButtons> createState() => _ExportButtonsState();
}

class _ExportButtonsState extends State<ExportButtons> {
  bool busy = false;
  Object? error;
  Future<void> export(String format) async {
    final epoch = widget.apiClient.sessionEpoch;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final bytes = await OrientationRepository(widget.apiClient)
          .export(widget.id, format);
      if (!mounted || epoch != widget.apiClient.sessionEpoch) return;
      final name =
          'orientia_${widget.simulation ? 'simulation_' : ''}${widget.id}.${format == 'excel' ? 'xlsx' : format}';
      await shareReport(
          bytes,
          name,
          format == 'pdf'
              ? 'application/pdf'
              : format == 'csv'
                  ? 'text/csv'
                  : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          stillAuthorized: () =>
              mounted && epoch == widget.apiClient.sessionEpoch);
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Wrap(spacing: 8, children: [
          for (final f in ['pdf', 'csv', 'excel'])
            OutlinedButton.icon(
                onPressed: busy ? null : () => export(f),
                icon: const Icon(Icons.ios_share),
                label: Text(f == 'excel' ? 'Excel' : f.toUpperCase()))
        ]),
        if (busy) const LinearProgressIndicator(),
        if (error != null) ErrorNotice(error!),
      ]);
}

class DecisionPage extends StatelessWidget {
  final ApiClient apiClient;
  final Future<Decision> Function() load;
  final String title;
  const DecisionPage(
      {super.key,
      required this.apiClient,
      required this.load,
      required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AsyncContent<Decision>(
          load: load,
          builder: (d, reload) =>
              ListView(padding: const EdgeInsets.all(16), children: [
                Notice(
                    d.kind == 'SIMULATION'
                        ? 'Simulation hypothétique — vos résultats officiels restent inchangés.'
                        : 'Aide à la décision. Aucun résultat ne garantit une admission ou une attribution de bourse.',
                    warning: d.kind == 'SIMULATION'),
                Text('Calcul : ${text(d.computedAt?.toLocal())}'),
                if (d.profileChanged)
                  const Notice('Le profil a changé depuis ce calcul.',
                      warning: true),
                if (!d.sourceCurrent)
                  const Notice(
                      'Sources historiques ou non déterminées. Un nouveau calcul peut être nécessaire.',
                      warning: true),
                DecisionContent(d.result, apiClient: apiClient),
                ExportButtons(
                    apiClient: apiClient,
                    id: d.id,
                    simulation: d.kind == 'SIMULATION'),
              ])));
}

class DecisionContent extends StatelessWidget {
  final Json data;
  final ApiClient apiClient;
  const DecisionContent(this.data, {super.key, required this.apiClient});
  @override
  Widget build(BuildContext context) {
    final before = objects(data['before']), after = objects(data['after']);
    final previous = {for (final row in before) row['programId']: row};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (data['warning'] != null) Notice(text(data['warning']), warning: true),
      for (final warning in data['warnings'] as List? ?? [])
        Notice(text(warning), warning: true),
      if (data['selectionLimit'] != null)
        Text(
            'Sélection : jusqu’à ${data['selectionLimit']} bourses par évaluation.'),
      if (after.isNotEmpty) ...[
        const Text('Situation initiale → hypothèse',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        for (final row in after) ...[
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text(row['name'] ?? row['programId'])),
                        Text(
                            'Avant : ${Eligibility.parse(previous[row['programId']]?['eligibilityStatus']).label} • score ${text(previous[row['programId']]?['score'])} • rang ${text(previous[row['programId']]?['compatibilityRank'])}'),
                        Text(
                            'Après : ${Eligibility.parse(row['eligibilityStatus']).label} • score ${text(row['score'])} • rang ${text(row['compatibilityRank'])}'),
                      ]))),
          ResultCard(row),
        ],
        for (final difference in objects(data['differences']))
          ListTile(
              title: Text(text(difference['programId'])),
              subtitle: Text(
                  'Delta de compatibilité : ${text(difference['scoreDelta'])}${difference['becameEligible'] == true ? ' • nouvellement éligible' : ''}${difference['becameNotEligible'] == true ? ' • éligibilité perdue' : ''}')),
        for (final row in before
            .where((b) => !after.any((a) => a['programId'] == b['programId'])))
          Notice(
              'Programme absent du scénario : ${text(row['name'] ?? row['programId'])}',
              warning: true),
      ],
      for (final row in [
        ...objects(data['programs']),
        ...objects(data['scholarships'])
      ])
        ResultCard(row),
    ]);
  }
}
