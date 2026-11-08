import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/data/orientation_repository.dart';
import '../../../core/models/academic_models.dart';
import '../../../core/widgets/academic_widgets.dart';

class AcademicProfilePage extends StatefulWidget {
  final ApiClient apiClient;
  const AcademicProfilePage({super.key, required this.apiClient});
  @override
  State<AcademicProfilePage> createState() => _AcademicProfilePageState();
}

class _AcademicProfilePageState extends State<AcademicProfilePage> {
  late final repo = OrientationRepository(widget.apiClient);
  AcademicProfileView? profile;
  Object? error;
  bool loading = true, saving = false, consent = false;
  int step = 0;
  List<Json> countries = [], years = [], scales = [], subjects = [];
  String? country, year, gradesYear, scale, bacType, nationality, incomePeriod;
  final fields = <String, TextEditingController>{
    for (final k in [
      'bacSeries',
      'diploma',
      'educationLevel',
      'highSchool',
      'generalAverage',
      'interests',
      'preferredLanguages',
      'language',
      'budget',
      'budgetCurrency',
      'householdIncome',
      'incomeCurrency'
    ])
      k: TextEditingController()
  };
  final marks = <String, TextEditingController>{};
  Set<String> destinations = {};
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    for (final c in [...fields.values, ...marks.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final p = await repo.profile();
      final refs = await Future.wait([
        repo.references('locations/countries'),
        repo.references('academic-years'),
        repo.references('grade-scales'),
        repo.references('subjects')
      ]);
      if (!mounted) return;
      final d = p.data;
      for (final e in fields.entries) {
        final v = d[e.key];
        e.value.text = v is List ? v.join(', ') : v?.toString() ?? '';
      }
      for (final c in marks.values) {
        c.dispose();
      }
      marks.clear();
      if (d['subjectGrades'] is Map) {
        for (final e in object(d['subjectGrades']).entries) {
          marks[e.key] = TextEditingController(text: e.value?.toString() ?? '');
        }
      }
      setState(() {
        profile = p;
        countries = refs[0];
        years = refs[1];
        scales = refs[2];
        subjects = refs[3];
        country = d['countryId'] as String?;
        year = d['academicYearId'] as String?;
        gradesYear = d['gradesAcademicYearId'] as String?;
        scale = d['gradeScaleId'] as String?;
        bacType = d['bacType'] as String?;
        nationality = d['nationalityCountryId'] as String?;
        incomePeriod = d['incomePeriod'] as String?;
        destinations = Set<String>.from(d['preferredCountries'] as List? ?? []);
        loading = false;
        consent = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  double? number(String key) {
    final s = fields[key]!.text.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    final n = double.tryParse(s);
    if (n == null || !n.isFinite) {
      throw FormatException('Nombre invalide: $key');
    }
    return n;
  }

  Future<void> save(bool confirmed) async {
    if (confirmed && !consent) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final values = <String, dynamic>{
        for (final e in fields.entries)
          e.key: e.value.text.trim().isEmpty ? null : e.value.text.trim()
      };
      for (final k in ['generalAverage', 'budget', 'householdIncome']) {
        values[k] = number(k);
      }
      final grades = <String, double>{};
      for (final e in marks.entries) {
        final s = e.value.text.trim().replaceAll(',', '.');
        if (s.isEmpty) continue;
        final n = double.tryParse(s);
        if (n == null || !n.isFinite) {
          throw const FormatException('Note invalide');
        }
        grades[e.key] = n;
      }
      final request = profile!.request({
        ...values,
        'countryId': country,
        'academicYearId': year,
        'gradesAcademicYearId': gradesYear,
        'gradeScaleId': scale,
        'bacType': bacType,
        'subjectGrades': grades,
        'interests': separated(fields['interests']!.text),
        'preferredLanguages': separated(fields['preferredLanguages']!.text),
        'preferredCountries': destinations.toList(),
        'nationalityCountryId': nationality,
        'incomePeriod': incomePeriod,
        'confirmed': confirmed
      });
      final updated = await repo.saveProfile(request);
      if (!mounted) return;
      setState(() {
        profile = updated;
        consent = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(confirmed
              ? 'Profil confirmé personnellement.'
              : 'Brouillon enregistré.')));
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget input(String name, String label, {bool numeric = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
          controller: fields[name],
          decoration: InputDecoration(labelText: label),
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          maxLength: numeric ? 16 : null));
  void resetScale() {
    scale = null;
    fields['generalAverage']!.clear();
    for (final c in marks.values) {
      c.clear();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Mon profil académique'), actions: [
        IconButton(
            onPressed: saving ? null : load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recharger le dossier')
      ]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? ErrorNotice(error ?? const FormatException(), onRetry: load)
              : Column(children: [
                  LinearProgressIndicator(value: (step + 1) / 4),
                  Expanded(
                      child: Stepper(
                    currentStep: step,
                    onStepTapped:
                        saving ? null : (s) => setState(() => step = s),
                    onStepContinue: saving
                        ? null
                        : () => setState(() => step = step < 3 ? step + 1 : 3),
                    onStepCancel: saving
                        ? null
                        : () => setState(() => step = step > 0 ? step - 1 : 0),
                    controlsBuilder: (context, d) => Row(children: [
                      if (step < 3)
                        FilledButton(
                            onPressed: d.onStepContinue,
                            child: const Text('Continuer')),
                      if (step > 0)
                        TextButton(
                            onPressed: d.onStepCancel,
                            child: const Text('Précédent'))
                    ]),
                    steps: [
                      Step(
                          title: const Text('Pays, années et barème'),
                          isActive: step >= 0,
                          content: Column(children: [
                            referenceSelect(
                                label: 'Pays de scolarité',
                                items: countries,
                                value: country,
                                onChanged: (v) => setState(() {
                                      country = v;
                                      resetScale();
                                    })),
                            referenceSelect(
                                label: 'Année d’admission',
                                items: years,
                                value: year,
                                nameField: 'label',
                                onChanged: (v) => setState(() => year = v)),
                            referenceSelect(
                                label: 'Année de vos résultats',
                                items: years,
                                value: gradesYear,
                                nameField: 'label',
                                onChanged: (v) => setState(() {
                                      gradesYear = v;
                                      resetScale();
                                    })),
                            referenceSelect(
                                label: 'Barème configuré',
                                items: scales
                                    .where((s) =>
                                        s['countryId'] == country &&
                                        s['academicYearId'] == gradesYear)
                                    .toList(),
                                value: scale,
                                onChanged: (v) => setState(() {
                                      resetScale();
                                      scale = v;
                                    })),
                            const Notice(
                                'Les notes utilisent uniquement le barème choisi. Un champ vide reste inconnu. Changer de barème efface les notes saisies dans le formulaire.'),
                          ])),
                      Step(
                          title: const Text('Diplôme et résultats'),
                          isActive: step >= 1,
                          content: Column(children: [
                            DropdownButtonFormField<String>(
                                initialValue: bacType,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                    labelText: 'Catégorie du bac'),
                                items: [
                                  for (final v in [
                                    'SCIENTIFIQUE',
                                    'LITTERAIRE',
                                    'MATHEMATIQUES',
                                    'EXPERIMENTALES',
                                    'TECHNIQUE',
                                    'ECONOMIQUE',
                                    'ARTS',
                                    'OTHER'
                                  ])
                                    DropdownMenuItem(value: v, child: Text(v))
                                ],
                                onChanged: (v) => setState(() => bacType = v)),
                            input('bacSeries',
                                'Série exacte du bac — sans déduction automatique'),
                            input('diploma', 'Diplôme'),
                            input('educationLevel', 'Niveau d’études'),
                            input('highSchool', 'Établissement'),
                            input('generalAverage',
                                'Moyenne générale dans le barème choisi',
                                numeric: true),
                            if (profile!.data['transcriptAnalysisId'] != null)
                              const Notice(
                                  'Une analyse confirmée est sélectionnée : ses résultats sont utilisés par le moteur. Pour utiliser la saisie manuelle, dissociez-la explicitement.'),
                            if (profile!.data['transcriptAnalysisId'] != null)
                              TextButton(
                                  onPressed: () => setState(() => profile!
                                      .data['transcriptAnalysisId'] = null),
                                  child: const Text(
                                      'Dissocier l’analyse dans le prochain enregistrement')),
                            for (final subject in subjects
                                .where((s) => s['gradeScaleId'] == scale))
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: TextField(
                                      controller: marks.putIfAbsent(
                                          subject['code'] as String,
                                          () => TextEditingController()),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: InputDecoration(
                                          labelText:
                                              '${subject['name']} — ${subject['code']}'))),
                          ])),
                      Step(
                          title: const Text('Préférences et bourses'),
                          isActive: step >= 2,
                          content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                input('interests',
                                    'Domaines d’intérêt, séparés par des virgules'),
                                const Text('Destinations souhaitées'),
                                Wrap(spacing: 8, children: [
                                  for (final c in countries)
                                    FilterChip(
                                        label: Text(text(c['name'])),
                                        selected:
                                            destinations.contains(c['id']),
                                        onSelected: (selected) => setState(() {
                                              selected
                                                  ? destinations
                                                      .add(c['id'] as String)
                                                  : destinations
                                                      .remove(c['id']);
                                            }))
                                ]),
                                input('preferredLanguages',
                                    'Langues souhaitées, séparées par des virgules'),
                                input('language', 'Langue déclarée'),
                                input('budget', 'Budget facultatif',
                                    numeric: true),
                                input('budgetCurrency',
                                    'Devise du budget — code ISO, par exemple XOF'),
                                referenceSelect(
                                    label: 'Nationalité — facultative',
                                    items: countries,
                                    value: nationality,
                                    onChanged: (v) =>
                                        setState(() => nationality = v)),
                                input('householdIncome',
                                    'Ressources du foyer — facultatives',
                                    numeric: true),
                                input(
                                    'incomeCurrency', 'Devise des ressources'),
                                DropdownButtonFormField<String>(
                                    initialValue: incomePeriod,
                                    decoration: const InputDecoration(
                                        labelText: 'Période des ressources'),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'MONTH',
                                          child: Text('Mensuelle')),
                                      DropdownMenuItem(
                                          value: 'YEAR',
                                          child: Text('Annuelle'))
                                    ],
                                    onChanged: (v) =>
                                        setState(() => incomePeriod = v)),
                              ])),
                      Step(
                          title: const Text('Vérifier et confirmer'),
                          isActive: step >= 3,
                          content: Column(children: [
                            const Notice(
                                'Votre confirmation est une déclaration personnelle, pas une certification officielle. Le backend vérifie la cohérence des années, du barème et des notes.'),
                            CheckboxListTile(
                                value: consent,
                                onChanged: saving
                                    ? null
                                    : (v) =>
                                        setState(() => consent = v ?? false),
                                title: const Text(
                                    'J’ai vérifié mes informations et je souhaite confirmer ce profil.')),
                            Wrap(spacing: 12, children: [
                              OutlinedButton(
                                  onPressed: saving ? null : () => save(false),
                                  child:
                                      const Text('Enregistrer le brouillon')),
                              FilledButton(
                                  onPressed: saving || !consent
                                      ? null
                                      : () => save(true),
                                  child: const Text('Confirmer le profil'))
                            ]),
                            if (saving) const LinearProgressIndicator(),
                            if (error != null)
                              ErrorNotice(error!, onRetry: load),
                          ])),
                    ],
                  )),
                ]));
}
