import 'package:flutter/material.dart';
import '../../../core/data/orientation_repository.dart';
import '../../../core/models/academic_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/academic_widgets.dart';
import '../../decisions/presentation/decision_page.dart';

class CatalogPage extends StatefulWidget {
  final ApiClient apiClient;
  final String resource, title;
  final Json filters;
  const CatalogPage(
      {super.key,
      required this.apiClient,
      this.resource = 'universities',
      this.title = 'Explorer',
      this.filters = const {}});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late final repo = OrientationRepository(widget.apiClient);
  final search = TextEditingController(), language = TextEditingController();
  PageData<CatalogItem>? result;
  Object? error;
  bool loading = true;
  int page = 0, generation = 0;
  String? country, year;
  List<Json> countries = [], years = [];
  final selected = <String, CatalogItem>{};
  @override
  void initState() {
    super.initState();
    loadReferences();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    language.dispose();
    super.dispose();
  }

  Future<void> loadReferences() async {
    try {
      final refs = await Future.wait([
        repo.references('locations/countries'),
        repo.references('academic-years')
      ]);
      if (mounted) {
        setState(() {
          countries = refs[0];
          years = refs[1];
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  Future<void> load() async {
    final current = ++generation;
    setState(() {
      loading = true;
      error = null;
      result = null;
    });
    try {
      final r = await repo.catalog(widget.resource, page: page, filters: {
        ...widget.filters,
        if (search.text.trim().isNotEmpty) 'search': search.text.trim(),
        if (country != null) 'countryId': country,
        if (year != null) 'academicYearId': year,
        if (language.text.trim().isNotEmpty) 'language': language.text.trim()
      });
      if (mounted && current == generation) {
        setState(() {
          result = r;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted && current == generation) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  Future<void> compare() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => DecisionPage(
            apiClient: widget.apiClient,
            load: () => repo.compare(selected.keys.toList()),
            title: 'Comparer les formations')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        if (widget.resource == 'programs')
          TextButton(
              onPressed: selected.length >= 2 && !loading ? compare : null,
              child: Text('Comparer (${selected.length}/6)')),
      ]),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              TextField(
                  controller: search,
                  decoration: InputDecoration(
                      labelText: 'Rechercher',
                      suffixIcon: IconButton(
                          onPressed: () {
                            page = 0;
                            load();
                          },
                          icon: const Icon(Icons.search),
                          tooltip: 'Rechercher')),
                  onSubmitted: (_) {
                    page = 0;
                    load();
                  }),
              ExpansionTile(title: const Text('Filtres'), children: [
                referenceSelect(
                    label: 'Pays',
                    items: countries,
                    value: country,
                    onChanged: (v) => setState(() => country = v)),
                referenceSelect(
                    label: 'Année applicable',
                    items: years,
                    value: year,
                    nameField: 'label',
                    onChanged: (v) => setState(() => year = v)),
                if (widget.resource == 'programs')
                  TextField(
                      controller: language,
                      decoration:
                          const InputDecoration(labelText: 'Langue publiée')),
                FilledButton(
                    onPressed: () {
                      page = 0;
                      load();
                    },
                    child: const Text('Appliquer les filtres')),
              ]),
            ])),
        if (loading) const LinearProgressIndicator(),
        if (error != null) ErrorNotice(error!, onRetry: load),
        Expanded(
            child: RefreshIndicator(
                onRefresh: load,
                child: ListView(padding: const EdgeInsets.all(12), children: [
                  if (!loading && result?.content.isEmpty == true)
                    const Padding(
                        padding: EdgeInsets.all(32),
                        child:
                            Text('Aucun résultat vérifié pour ces filtres.')),
                  for (final item in result?.content ?? <CatalogItem>[])
                    Card(
                        child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                          '${text(item.fields['countryName'] ?? item.fields['universityName'])}\n${item.verified ? 'Catalogue vérifié' : 'Vérification non déterminée'}${widget.resource == 'scholarships' ? ' • ${availabilityLabel(item.fields)}' : ''}'),
                      isThreeLine: true,
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => CatalogDetailPage(
                                  apiClient: widget.apiClient,
                                  resource: widget.resource,
                                  id: item.id))),
                      trailing: widget.resource == 'programs'
                          ? Checkbox(
                              value: selected.containsKey(item.id),
                              onChanged: (v) {
                                if (v == true && selected.length >= 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Six formations au maximum.')));
                                  return;
                                }
                                setState(() {
                                  v == true
                                      ? selected[item.id] = item
                                      : selected.remove(item.id);
                                });
                              })
                          : const Icon(Icons.chevron_right),
                    )),
                ]))),
        SafeArea(
            top: false,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                      onPressed: page > 0 && !loading
                          ? () {
                              page--;
                              load();
                            }
                          : null,
                      child: const Text('Précédent')),
                  Text('Page ${page + 1}'),
                  TextButton(
                      onPressed: result?.hasNext == true && !loading
                          ? () {
                              page++;
                              load();
                            }
                          : null,
                      child: const Text('Suivant')),
                ])),
      ]));
}

class CatalogDetailPage extends StatelessWidget {
  final ApiClient apiClient;
  final String resource, id;
  const CatalogDetailPage(
      {super.key,
      required this.apiClient,
      required this.resource,
      required this.id});
  @override
  Widget build(BuildContext context) {
    final repo = OrientationRepository(apiClient);
    return Scaffold(
        appBar: AppBar(title: const Text('Détails et sources')),
        body: AsyncContent<List<Object>>(load: () async {
          final detail = await repo.detail(resource, id);
          final sources = await repo.sources(resource, id);
          final rules = resource == 'programs'
              ? objects(object((await apiClient.call('/admission-criteria',
                      query: {'programId': id, 'size': 100}))
                  .data)['content'])
              : <Json>[];
          return [detail, sources, rules];
        }, builder: (values, reload) {
          final j = values[0] as Json;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(text(j['name']),
                style: Theme.of(context).textTheme.headlineSmall),
            Notice(j['verified'] == true
                ? 'Données vérifiées pour le catalogue ; aucune admission ni bourse garantie.'
                : 'Vérification non déterminée.'),
            for (final entry in {
              'Pays': j['countryName'],
              'Ville': j['cityName'],
              'Université': j['universityName'],
              'Campus': j['campusName'],
              'Faculté': j['facultyName'],
              'Diplôme': j['type'],
              'Durée': j['duration'],
              'Langue': j['language'],
              'Domaine': j['studyField'],
              'Année': j['academicYearId'],
              'Frais': j['tuitionFee'] == null
                  ? null
                  : '${j['tuitionFee']} ${text(j['tuitionCurrency'])}',
              'Montant': j['amount'] == null
                  ? null
                  : '${j['amount']} ${text(j['currency'])}',
              'Échéance': j['deadline']
            }.entries)
              ListTile(
                  title: Text(entry.key), subtitle: Text(text(entry.value))),
            if (j['description'] != null)
              SelectableText(text(j['description'])),
            if (resource == 'scholarships') ...[
              Notice(
                  'Disponibilité : ${availabilityLabel(j)}. L’éligibilité se vérifie séparément ; une bourse éligible n’est pas une bourse obtenue.'),
              FilledButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => DecisionPage(
                              apiClient: apiClient,
                              load: () => repo.scholarships(id: id),
                              title: 'Évaluer cette bourse'))),
                  child: const Text('Évaluer mon éligibilité')),
            ],
            if (resource == 'universities') ...[
              _related(context, 'Campus', 'campuses', {'universityId': id}),
              _related(context, 'Formations', 'programs', {'universityId': id}),
            ],
            if (resource == 'campuses')
              _related(context, 'Facultés', 'faculties', {'campusId': id}),
            if (resource == 'faculties')
              _related(context, 'Formations', 'programs', {'facultyId': id}),
            if (resource == 'programs') SourceDetails(values[2] as List<Json>),
            SourceDetails(values[1] as List<Json>),
          ]);
        }));
  }

  Widget _related(
          BuildContext context, String title, String kind, Json filters) =>
      OutlinedButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => CatalogPage(
                  apiClient: apiClient,
                  resource: kind,
                  title: title,
                  filters: filters))),
          child: Text(title));
}
