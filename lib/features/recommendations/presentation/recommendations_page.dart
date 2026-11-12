import '../../../core/widgets/business_scaffold.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/data/orientation_repository.dart';
import '../../../core/models/academic_models.dart';
import '../../../core/widgets/academic_widgets.dart';
import '../../decisions/presentation/decision_page.dart';
import '../../profile/presentation/academic_profile_page.dart';

class RecommendationsPage extends StatefulWidget {
  final ApiClient apiClient;
  final String? runId;
  const RecommendationsPage({super.key, required this.apiClient, this.runId});
  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  late final repo = OrientationRepository(widget.apiClient);
  PageData<Recommendation>? result;
  final items = <Recommendation>[];
  int generation = 0;
  bool busy = true;
  Object? error;
  int page = 0;
  String? currentRun;
  @override
  void initState() {
    super.initState();
    currentRun = widget.runId;
    load();
  }

  Future<void> load({bool more = false}) async {
    if (more && busy) return;
    final request = ++generation;
    final nextPage = more ? page + 1 : 0;
    setState(() {
      busy = true;
      error = null;
      if (!more) {
        items.clear();
        result = null;
        page = 0;
      }
    });
    try {
      if (currentRun == null) {
        final runs = await repo.recommendationRuns();
        if (runs.content.isNotEmpty) {
          currentRun = runs.content.first['runId'] as String;
        }
      }
      final list =
          await repo.recommendations(page: nextPage, runId: currentRun);
      if (mounted && request == generation) {
        setState(() {
          result = list;
          page = nextPage;
          items.addAll(list.content);
        });
      }
    } catch (e) {
      if (mounted && request == generation) {
        setState(() {
          error = e;
        });
      }
    } finally {
      if (mounted && request == generation) setState(() => busy = false);
    }
  }

  Future<void> generate() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      currentRun = await repo.generate();
      page = 0;
      await load();
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => BusinessScaffold(
      appBar: AppBar(
          title: Text(widget.runId == null
              ? 'Mes recommandations'
              : 'Calcul historique')),
      body: Column(children: [
        if (widget.runId == null)
          Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(spacing: 8, children: [
                FilledButton.icon(
                    onPressed: busy ? null : generate,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Calculer depuis mon profil confirmé')),
                TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => AcademicProfilePage(
                                apiClient: widget.apiClient))),
                    child: const Text('Vérifier mon profil')),
              ])),
        if (busy) const LinearProgressIndicator(),
        if (error != null)
          ErrorNotice(error!, onRetry: () => load(more: items.isNotEmpty)),
        Expanded(
            child: RefreshIndicator(
                onRefresh: () => load(),
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    children: [
                      const Notice(
                          'Un score mesure la compatibilité avec les données connues, jamais une probabilité d’admission.'),
                      for (final r in items)
                        Card(
                            child: ListTile(
                                title: Text(r.name),
                                subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      EligibilityChip(r.eligibility),
                                      Text(
                                          'Compatibilité : ${r.score == null ? 'Indéterminée' : '${r.score!.toStringAsFixed(2)} /100'}'),
                                      if (r.stale)
                                        const Text(
                                            'Profil modifié depuis le calcul'),
                                      if (!r.sourceCurrent)
                                        const Text(
                                            'Guide inactif ou non déterminé'),
                                    ]),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                        builder: (_) =>
                                            RecommendationDetailPage(
                                                apiClient: widget.apiClient,
                                                id: r.id))))),
                      if (!busy && result?.content.isEmpty == true)
                        const ListTile(
                            title: Text(
                                'Aucune recommandation enregistrée. Vérifiez le profil confirmé et les guides disponibles.')),
                    ]))),
        if (result?.hasNext == true)
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton.icon(
                      onPressed: busy ? null : () => load(more: true),
                      icon: const Icon(Icons.add),
                      label: const Text('Voir plus de recommandations')))),
      ]));
}

class RecommendationDetailPage extends StatelessWidget {
  final ApiClient apiClient;
  final String id;
  const RecommendationDetailPage(
      {super.key, required this.apiClient, required this.id});
  @override
  Widget build(BuildContext context) => BusinessScaffold(
      appBar: AppBar(title: const Text('Comprendre ma recommandation')),
      body: AsyncContent<Recommendation>(
          load: () async => Recommendation.fromJson(
              object((await apiClient.call('/recommendations/$id')).data)),
          builder: (r, reload) =>
              ListView(padding: const EdgeInsets.all(16), children: [
                Text(r.name, style: Theme.of(context).textTheme.headlineSmall),
                EligibilityChip(r.eligibility),
                Text(
                    'Calcul du ${text(r.computedAt?.toLocal())} • Année : ${text(r.explanation['academicYearId'])}'),
                if (r.stale)
                  const Notice(
                      'Profil modifié : consultez ce résultat comme un historique et relancez un calcul.',
                      warning: true),
                if (!r.sourceCurrent)
                  const Notice(
                      'Le guide n’est plus actif ou n’est pas déterminé. Ce résultat ne constitue pas une décision actuelle.',
                      warning: true),
                ResultCard({
                  'name': r.name,
                  'score': r.score,
                  'dataCoverage': r.coverage,
                  'eligibilityStatus': r.eligibility == Eligibility.eligible
                      ? 'ELIGIBLE'
                      : r.eligibility == Eligibility.notEligible
                          ? 'NOT_ELIGIBLE'
                          : 'INSUFFICIENT_DATA',
                  ...r.explanation
                }),
                if (r.explanation['scoring'] is Map)
                  for (final component
                      in objects(r.explanation['scoring']['components']))
                    ListTile(
                        title: Text(text(component['scoreType'])),
                        subtitle: Text(
                            '${component['computed'] == true ? text(component['score']) : 'Non calculé'} • ${text(component['explanation'])}')),
                ExportButtons(apiClient: apiClient, id: r.id),
              ])));
}
