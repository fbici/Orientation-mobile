import '../../../core/widgets/business_scaffold.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/data/orientation_repository.dart';
import '../../../core/models/academic_models.dart';
import '../../../core/widgets/academic_widgets.dart';
import '../../profile/presentation/academic_profile_page.dart';

class DocumentsPage extends StatefulWidget {
  final ApiClient apiClient;
  const DocumentsPage({super.key, required this.apiClient});
  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  late final repo = OrientationRepository(widget.apiClient);
  PageData<Json>? transcripts;
  final documents = <Json>[];
  int generation = 0;
  List<Json> years = [];
  String? year;
  int page = 0;
  bool loading = true, uploading = false;
  Object? error;
  double? progress;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool more = false}) async {
    if (more && loading) return;
    final request = ++generation;
    final nextPage = more ? page + 1 : 0;
    setState(() {
      loading = true;
      error = null;
      if (!more) {
        documents.clear();
        transcripts = null;
        page = 0;
      }
    });
    try {
      final refs = await repo.references('academic-years');
      final list = await repo.transcripts(page: nextPage);
      if (mounted && request == generation) {
        setState(() {
          years = refs;
          transcripts = list;
          page = nextPage;
          documents.addAll(list.content);
          loading = false;
        });
      }
    } catch (e) {
      if (mounted && request == generation) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  Future<void> upload() async {
    if (year == null) {
      setState(() => error = const FormatException('Choisir une année'));
      return;
    }
    setState(() {
      uploading = true;
      error = null;
      progress = null;
    });
    try {
      final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
          withData: true);
      if (picked == null || !mounted) return;
      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null || file.size > 10 * 1024 * 1024) {
        throw const FormatException('Fichier trop volumineux');
      }
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
                  title: const Text('Vérifier le document'),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${file.name} • ${file.size} octets'),
                    if (['png', 'jpg', 'jpeg']
                        .contains(file.extension?.toLowerCase()))
                      Image.memory(bytes, height: 240, fit: BoxFit.contain),
                    const Text(
                        'Le document est envoyé au backend pour une analyse privée. Les valeurs inconnues resteront à vérifier.'),
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Annuler')),
                    FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Envoyer'))
                  ]));
      if (confirmed != true || !mounted) return;
      await repo.upload(
          Uint8List.fromList(bytes), file.extension!.toLowerCase(), year!,
          progress: (sent, total) {
        if (mounted) setState(() => progress = total > 0 ? sent / total : null);
      });
      await load();
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      try {
        await FilePicker.platform.clearTemporaryFiles();
      } catch (_) {}
      PaintingBinding.instance.imageCache.clear();
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => BusinessScaffold(
      appBar: AppBar(title: const Text('Mes relevés')),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              referenceSelect(
                  label: 'Année des résultats du document',
                  items: years,
                  value: year,
                  nameField: 'label',
                  onChanged:
                      uploading ? (_) {} : (v) => setState(() => year = v)),
              FilledButton.icon(
                  onPressed: uploading ? null : upload,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Ajouter un PDF ou une image')),
              if (uploading) LinearProgressIndicator(value: progress),
              if (error != null)
                ErrorNotice(error!,
                    onRetry: () => load(more: documents.isNotEmpty)),
            ])),
        if (loading) const LinearProgressIndicator(),
        Expanded(
            child: RefreshIndicator(
                onRefresh: () => load(),
                child: ListView(children: [
                  for (final t in documents)
                    Card(
                        child: ListTile(
                            title:
                                Text(text(t['originalFileName'] ?? t['title'])),
                            subtitle: Text(
                                'Année : ${text(t['academicYearId'])} • ${text(t['status'])}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                    builder: (_) => TranscriptPage(
                                        apiClient: widget.apiClient,
                                        transcript: t))))),
                  if (!loading && transcripts?.content.isEmpty == true)
                    const ListTile(
                        title: Text(
                            'Aucun relevé. Ajoutez votre premier document.')),
                ]))),
        if (transcripts?.hasNext == true)
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton.icon(
                      onPressed: loading ? null : () => load(more: true),
                      icon: const Icon(Icons.add),
                      label: const Text('Voir plus')))),
      ]));
}

class TranscriptPage extends StatefulWidget {
  final ApiClient apiClient;
  final Json transcript;
  const TranscriptPage(
      {super.key, required this.apiClient, required this.transcript});
  @override
  State<TranscriptPage> createState() => _TranscriptPageState();
}

class _TranscriptPageState extends State<TranscriptPage> {
  late final repo = OrientationRepository(widget.apiClient);
  List<Json> scales = [];
  PageData<TranscriptAnalysis>? history;
  final analyses = <TranscriptAnalysis>[];
  int generation = 0;
  final period = TextEditingController();
  String? scale;
  int page = 0;
  bool busy = true;
  Object? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    period.dispose();
    super.dispose();
  }

  Future<void> load({bool more = false}) async {
    if (more && busy) return;
    final request = ++generation;
    final nextPage = more ? page + 1 : 0;
    setState(() {
      busy = true;
      error = null;
      if (!more) {
        analyses.clear();
        history = null;
        page = 0;
      }
    });
    try {
      final refs = await repo.references('grade-scales');
      final h = await repo.analyses(widget.transcript['id'] as String,
          page: nextPage);
      if (mounted && request == generation) {
        setState(() {
          scales = refs
              .where((s) =>
                  s['academicYearId'] == widget.transcript['academicYearId'])
              .toList();
          history = h;
          page = nextPage;
          analyses.addAll(h.content);
          busy = false;
        });
      }
    } catch (e) {
      if (mounted && request == generation) {
        setState(() {
          error = e;
          busy = false;
        });
      }
    }
  }

  Future<void> analyze() async {
    if (scale == null || period.text.trim().isEmpty) {
      setState(() => error = const FormatException('Barème et période requis'));
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final a = await repo.analyze(
          widget.transcript['id'] as String, scale!, period.text.trim());
      if (!mounted) return;
      await open(a);
      await load();
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> open(TranscriptAnalysis a) async {
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => AnalysisPage(
                apiClient: widget.apiClient,
                analysis: a,
                transcript: widget.transcript)));
  }

  @override
  Widget build(BuildContext context) => BusinessScaffold(
      appBar: AppBar(title: const Text('Analyse et versions')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(text(widget.transcript['originalFileName'])),
        referenceSelect(
            label: 'Barème explicite de cette année',
            items: scales,
            value: scale,
            onChanged: (v) => setState(() => scale = v)),
        TextField(
            controller: period,
            decoration: const InputDecoration(
                labelText:
                    'Période scolaire — par exemple Année ou Trimestre 1')),
        FilledButton(
            onPressed: busy ? null : analyze,
            child: const Text('Lancer une analyse OCR')),
        if (busy) ...[
          const LinearProgressIndicator(),
          const Text(
              'Traitement en cours. En cas d’interruption, consultez les versions avant de relancer.')
        ],
        if (error != null)
          ErrorNotice(error!, onRetry: () => load(more: analyses.isNotEmpty)),
        for (final a in analyses)
          Card(
              child: ListTile(
                  title: Text(a.confirmed
                      ? 'Analyse confirmée personnellement'
                      : a.status),
                  subtitle: Text('Version : ${a.id}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(a))),
        if (history?.hasNext == true)
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton.icon(
                      onPressed: busy ? null : () => load(more: true),
                      icon: const Icon(Icons.add),
                      label: const Text('Voir plus')))),
      ]));
}

class AnalysisPage extends StatefulWidget {
  final ApiClient apiClient;
  final TranscriptAnalysis analysis;
  final Json transcript;
  const AnalysisPage(
      {super.key,
      required this.apiClient,
      required this.analysis,
      required this.transcript});
  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  late final repo = OrientationRepository(widget.apiClient);
  late TranscriptAnalysis analysis = widget.analysis;
  late final average =
      TextEditingController(text: analysis.review['average']?.toString() ?? '');
  late final markData = objects(analysis.review['marks']);
  late final values = [
    for (final m in markData)
      TextEditingController(text: m['value']?.toString() ?? '')
  ];
  late final coefficients = [
    for (final m in markData)
      TextEditingController(text: m['coefficient']?.toString() ?? '')
  ];
  List<Json> subjects = [];
  bool consent = false, busy = false, dirty = false;
  Object? error;
  @override
  void initState() {
    super.initState();
    for (final controller in [average, ...values, ...coefficients]) {
      controller.addListener(() {
        if (mounted) {
          setState(() {
            dirty = true;
            consent = false;
          });
        }
      });
    }
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    try {
      final all = await repo.references('subjects');
      if (mounted) {
        setState(() => subjects = all
            .where((s) => s['gradeScaleId'] == analysis.review['gradeScaleId'])
            .toList());
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  @override
  void dispose() {
    average.dispose();
    for (final c in [...values, ...coefficients]) {
      c.dispose();
    }
    super.dispose();
  }

  double? parse(TextEditingController c) {
    if (c.text.trim().isEmpty) return null;
    final n = double.tryParse(c.text.trim().replaceAll(',', '.'));
    if (n == null || !n.isFinite) throw const FormatException('Note invalide');
    return n;
  }

  Future<void> action(String operation) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (operation == 'save') {
        final review = {
          ...analysis.review,
          'average': parse(average),
          'marks': [
            for (int i = 0; i < markData.length; i++)
              {
                ...markData[i],
                'value': parse(values[i]),
                'coefficient': parse(coefficients[i])
              }
          ]
        };
        final next = await repo.correct(analysis, review);
        if (mounted) {
          setState(() {
            analysis = next;
            consent = false;
            dirty = false;
          });
        }
      } else if (operation == 'confirm') {
        final next = await repo.confirm(analysis);
        if (mounted) setState(() => analysis = next);
      } else {
        final p = await repo.profile();
        final scales = await repo.references('grade-scales');
        final source = scales
            .singleWhere((s) => s['id'] == analysis.review['gradeScaleId']);
        if (!mounted) return;
        final yes = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
                    title: const Text('Utiliser cette analyse ?'),
                    content: const Text(
                        'Le profil utilisera le pays, le barème et l’année de ce relevé. Il sera enregistré comme brouillon pour vous permettre de le vérifier et le confirmer.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Annuler')),
                      FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Utiliser'))
                    ]));
        if (yes != true) return;
        await repo.saveProfile(p.request({
          'transcriptAnalysisId': analysis.id,
          'gradeScaleId': analysis.review['gradeScaleId'],
          'gradesAcademicYearId': widget.transcript['academicYearId'],
          'countryId': source['countryId'],
          'generalAverage': null,
          'subjectGrades': <String, double>{},
          'confirmed': false
        }));
        if (mounted) {
          await Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) =>
                      AcademicProfilePage(apiClient: widget.apiClient)));
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => BusinessScaffold(
      appBar: AppBar(title: const Text('Vérifier les notes extraites')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Notice(
            analysis.confirmed
                ? 'Confirmation personnelle enregistrée, sans certification officielle.'
                : 'Les valeurs inconnues restent vides. Vérifiez la source avant toute confirmation.',
            warning: !analysis.confirmed),
        if (analysis.review.isEmpty)
          const Notice(
              'Aucun résultat exploitable. Consultez l’état du document et relancez une analyse si nécessaire.',
              warning: true),
        TextField(
            controller: average,
            readOnly: analysis.confirmed,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Moyenne extraite — inconnue si vide')),
        for (int i = 0; i < markData.length; i++)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Text(text(markData[i]['rawSubject']),
                        style: Theme.of(context).textTheme.titleMedium),
                    referenceSelect(
                        label: 'Matière configurée',
                        items: subjects,
                        value: markData[i]['subjectId'] as String?,
                        onChanged: analysis.confirmed
                            ? null
                            : (v) {
                                setState(() {
                                  markData[i]['subjectId'] = v;
                                  dirty = true;
                                  consent = false;
                                });
                              }),
                    TextField(
                        controller: values[i],
                        readOnly: analysis.confirmed,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Note — vide si inconnue')),
                    TextField(
                        controller: coefficients[i],
                        readOnly: analysis.confirmed,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Coefficient — facultatif')),
                    Text('Page ${text(markData[i]['page'])}'),
                    SelectableText(text(markData[i]['passage'])),
                  ]))),
        if (!analysis.confirmed) ...[
          FilledButton(
              onPressed:
                  busy || analysis.review.isEmpty ? null : () => action('save'),
              child: const Text('Enregistrer une nouvelle correction')),
          CheckboxListTile(
              value: consent,
              onChanged: (v) => setState(() => consent = v ?? false),
              title: const Text(
                  'J’ai vérifié cette version. Les modifications doivent être enregistrées avant confirmation.')),
          OutlinedButton(
              onPressed: busy || !consent || dirty || analysis.review.isEmpty
                  ? null
                  : () => action('confirm'),
              child: const Text('Confirmer la version enregistrée')),
        ] else
          FilledButton(
              onPressed: busy ? null : () => action('select'),
              child: const Text('Sélectionner cette analyse dans mon profil')),
        if (busy) const LinearProgressIndicator(),
        if (error != null) ErrorNotice(error!),
      ]));
}
