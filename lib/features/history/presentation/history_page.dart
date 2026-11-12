import '../../../core/widgets/business_scaffold.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/data/orientation_repository.dart';
import '../../../core/models/academic_models.dart';
import '../../../core/widgets/academic_widgets.dart';
import '../../decisions/presentation/decision_page.dart';
import '../../recommendations/presentation/recommendations_page.dart';

class HistoryPage extends StatefulWidget {
  final ApiClient apiClient;
  const HistoryPage({super.key, required this.apiClient});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final repo = OrientationRepository(widget.apiClient);
  String kind = 'SIMULATION';
  int page = 0, generation = 0;
  bool loading = true, hasNext = false;
  Object? error;
  List<Decision> decisions = [];
  List<Json> runs = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool more = false}) async {
    if (more && loading) return;
    final nextPage = more ? page + 1 : 0;
    final request = ++generation;
    setState(() {
      loading = true;
      error = null;
      if (!more) {
        decisions = [];
        runs = [];
        page = 0;
        hasNext = false;
      }
    });
    try {
      if (kind == 'RECOMMENDATIONS') {
        final result = await repo.recommendationRuns(page: nextPage);
        if (mounted && request == generation) {
          setState(() {
            runs = [...runs, ...result.content];
            page = nextPage;
            hasNext = result.hasNext;
          });
        }
      } else {
        final result = await repo.history(kind, page: nextPage);
        if (mounted && request == generation) {
          setState(() {
            decisions = [...decisions, ...result.content];
            page = nextPage;
            hasNext = result.hasNext;
          });
        }
      }
    } catch (e) {
      if (mounted && request == generation) setState(() => error = e);
    } finally {
      if (mounted && request == generation) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => BusinessScaffold(
      appBar: AppBar(title: const Text('Mon historique')),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
                initialValue: kind,
                decoration:
                    const InputDecoration(labelText: 'Type de décision'),
                items: const [
                  DropdownMenuItem(
                      value: 'RECOMMENDATIONS', child: Text('Recommandations')),
                  DropdownMenuItem(
                      value: 'SIMULATION', child: Text('Simulations')),
                  DropdownMenuItem(
                      value: 'COMPARISON', child: Text('Comparaisons')),
                  DropdownMenuItem(
                      value: 'SCHOLARSHIP',
                      child: Text('Évaluations de bourses'))
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      kind = v;
                      page = 0;
                    });
                    load();
                  }
                })),
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          ErrorNotice(error!,
              onRetry: () =>
                  load(more: decisions.isNotEmpty || runs.isNotEmpty)),
        Expanded(
            child: ListView(padding: const EdgeInsets.all(12), children: [
          for (final d in decisions)
            Card(
                child: ListTile(
                    title: Text(d.kind == 'SIMULATION'
                        ? 'Simulation hypothétique'
                        : d.kind == 'COMPARISON'
                            ? 'Comparaison'
                            : 'Bourses'),
                    subtitle: Text(
                        '${text(d.computedAt?.toLocal())}${d.profileChanged ? ' • Profil modifié' : ''}${!d.sourceCurrent ? ' • Sources historiques ou inconnues' : ''}'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => DecisionPage(
                                apiClient: widget.apiClient,
                                load: () => repo.decision(d.id),
                                title: 'Décision enregistrée'))))),
          for (final run in runs)
            Card(
                child: ListTile(
                    title: Text('Calcul du ${text(run['computedAt'])}'),
                    subtitle: Text(
                        '${text(run['totalPrograms'])} programmes${run['stale'] == true ? ' • Profil modifié' : ''}'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => RecommendationsPage(
                                apiClient: widget.apiClient,
                                runId: run['runId'] as String))))),
          if (!loading && error == null && decisions.isEmpty && runs.isEmpty)
            const ListTile(
                title: Text('Aucun historique pour cette sélection.')),
        ])),
        if (hasNext)
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton.icon(
                      onPressed: loading ? null : () => load(more: true),
                      icon: const Icon(Icons.history_rounded),
                      label:
                          const Text('Afficher les résultats plus anciens')))),
      ]));
}
