import 'package:flutter/material.dart';
import '../models/academic_models.dart';
import '../network/api_failure.dart';
import '../theme/app_theme.dart';

class AsyncContent<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(T, VoidCallback) builder;
  const AsyncContent({super.key, required this.load, required this.builder});
  @override
  State<AsyncContent<T>> createState() => _AsyncContentState<T>();
}

class _AsyncContentState<T> extends State<AsyncContent<T>> {
  T? data;
  Object? error;
  bool loading = true;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void didUpdateWidget(covariant AsyncContent<T> old) {
    super.didUpdateWidget(old);
    if (old.key != widget.key) reload();
  }

  void reload() async {
    final current = ++generation;
    setState(() {
      loading = true;
      error = null;
      data = null;
    });
    try {
      final value = await widget.load();
      if (mounted && current == generation) {
        setState(() {
          data = value;
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    }
    if (error != null) return ErrorNotice(error!, onRetry: reload);
    return widget.builder(data as T, reload);
  }
}

class ErrorNotice extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  const ErrorNotice(this.error, {super.key, this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(ApiFailure.from(error).message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            semanticsLabel: ApiFailure.from(error).message),
        if (onRetry != null)
          TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer')),
      ]));
}

class Notice extends StatelessWidget {
  final String message;
  final bool warning;
  const Notice(this.message, {super.key, this.warning = false});
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: warning ? AppTheme.warningSurface : AppTheme.primarySurface,
          borderRadius: BorderRadius.circular(12)),
      child: Text(message, style: const TextStyle(color: AppTheme.gray800)));
}

class EligibilityChip extends StatelessWidget {
  final Eligibility status;
  const EligibilityChip(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      Eligibility.eligible => const Color(0xFF166534),
      Eligibility.notEligible => const Color(0xFF991B1B),
      Eligibility.insufficientData => const Color(0xFF92400E)
    };
    return Chip(
        label: Text(status.label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        backgroundColor: color.withValues(alpha: .09),
        side: BorderSide.none);
  }
}

class SourceDetails extends StatelessWidget {
  final List<Json> sources;
  const SourceDetails(this.sources, {super.key});
  @override
  Widget build(BuildContext context) => ExpansionTile(
          title: Text('Sources et conditions (${sources.length})'),
          children: [
            if (sources.isEmpty)
              const ListTile(title: Text('Aucune citation disponible.')),
            for (final source in sources)
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (source['criterionName'] != null)
                          Text(text(source['criterionName']),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        if (source['expectedValue'] != null)
                          Text('Attendu : ${text(source['expectedValue'])}'),
                        if (source.containsKey('actualValue'))
                          Text(
                              'Observé : ${text(source['actualValue'], 'Manquant')}'),
                        if (source['status'] != null)
                          Text(Eligibility.parse(source['status']).label),
                        SelectableText(text(
                            source['passage'] ??
                                source['sourcePassage'] ??
                                source['message'],
                            'Passage indisponible')),
                        Text(
                            'Page ${text(source['pageNumber'] ?? source['sourcePage'])} • Année ${text(source['academicYearId'])}'),
                        Text('Guide : ${text(source['guideVersionId'])}',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(
                            'Référence : ${text(source['sourceFactId'] ?? source['factId'])}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ])),
          ]);
}

class ResultCard extends StatelessWidget {
  final Json row;
  final Widget? actions;
  const ResultCard(this.row, {super.key, this.actions});
  @override
  Widget build(BuildContext context) {
    final eligibility = row['eligibility'] is Map
        ? object(row['eligibility'])
        : <String, dynamic>{};
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  text(row['name'] ??
                      row['programName'] ??
                      row['programId'] ??
                      row['scholarshipId']),
                  style: Theme.of(context).textTheme.titleMedium),
              EligibilityChip(Eligibility.parse(
                  row['eligibilityStatus'] ?? eligibility['status'])),
              Text(
                  'Compatibilité : ${row['score'] == null ? 'Indéterminée' : '${row['score']} /100'}'),
              if (row.containsKey('dataCoverage'))
                Text('Couverture des données : ${text(row['dataCoverage'])}%'),
              if (row['university'] is Map)
                Text('Université : ${text(row['university']['name'])}'),
              for (final entry in {
                'Pays': row['countryName'] ??
                    (row['university'] is Map
                        ? row['university']['countryName']
                        : null),
                'Ville': row['cityName'] ??
                    (row['campus'] is Map ? row['campus']['cityName'] : null),
                'Diplôme': row['type'],
                'Durée': row['duration'],
                'Langue': row['language'],
                'Année': row['academicYearId'],
                'Frais': row['tuitionFee'] == null
                    ? null
                    : '${row['tuitionFee']} ${text(row['tuitionCurrency'])}',
                'Montant de la bourse': row['amount'] == null
                    ? null
                    : '${row['amount']} ${text(row['currency'])}'
              }.entries)
                Text('${entry.key} : ${text(entry.value)}'),
              if (row.containsKey('availability') ||
                  row.containsKey('openForApplications'))
                Text('Disponibilité : ${availabilityLabel(row)}'),
              if (row.containsKey('deadline'))
                Text('Échéance : ${text(row['deadline'])}'),
              for (final issue in (row['scopeIssues'] as List? ?? []))
                Text(issue.toString()),
              SourceDetails([
                ...objects(eligibility['criteria']),
                ...objects(row['sources'])
              ]),
              if (row['scholarships'] is List)
                ExpansionTile(
                    title: const Text('Bourses associées'),
                    children: [
                      for (final s in objects(row['scholarships']))
                        ResultCard(s)
                    ]),
              if (actions != null) actions!,
            ])));
  }
}

String availabilityLabel(Json row) => switch (row['availability']) {
      'OPEN' => 'Ouverte',
      'CLOSED' => 'Fermée',
      'UNVERIFIED' => 'Non vérifiée',
      _ => row['openForApplications'] == true
          ? 'Ouverte'
          : row['openForApplications'] == false
              ? 'Fermée'
              : 'Inconnue'
    };
Widget referenceSelect(
        {required String label,
        required List<Json> items,
        String? value,
        required ValueChanged<String?>? onChanged,
        String nameField = 'name'}) =>
    Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: DropdownButtonFormField<String>(
          key: ValueKey('$label-$value-${items.map((j) => j['id']).join(',')}'),
          initialValue: items.any((j) => j['id'] == value) ? value : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            const DropdownMenuItem<String>(
                value: null, child: Text('Non renseigné')),
            for (final j in items)
              DropdownMenuItem<String>(
                  value: j['id'] as String,
                  child:
                      Text(text(j[nameField]), overflow: TextOverflow.ellipsis))
          ],
          onChanged: onChanged,
        ));
List<String> separated(String text) =>
    text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
