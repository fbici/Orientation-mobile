typedef Json = Map<String, dynamic>;
Json object(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Objet JSON attendu');
}

List<Json> objects(Object? value) =>
    value is List ? value.map(object).toList() : [];
double? decimal(Object? value) => value is num
    ? value.toDouble()
    : value is String
        ? double.tryParse(value)
        : null;
String text(Object? value, [String unknown = 'Inconnu']) =>
    value == null || value.toString().trim().isEmpty
        ? unknown
        : value.toString();

enum Eligibility {
  eligible,
  notEligible,
  insufficientData;

  static Eligibility parse(Object? value) => switch (value) {
        'ELIGIBLE' => eligible,
        'NOT_ELIGIBLE' => notEligible,
        _ => insufficientData
      };
  String get label => switch (this) {
        eligible => 'Éligible',
        notEligible => 'Non éligible',
        insufficientData => 'Données insuffisantes'
      };
}

class PageData<T> {
  final List<T> content;
  final int total, page, size;
  const PageData(this.content, this.total, this.page, this.size);
  bool get hasNext => (page + 1) * size < total;
  factory PageData.parse(Object? value, T Function(Json) parse) {
    final j = object(value);
    return PageData(
        objects(j['content']).map(parse).toList(),
        (j['totalElements'] as num?)?.toInt() ?? 0,
        (j['number'] as num?)?.toInt() ?? 0,
        (j['size'] as num?)?.toInt() ?? 20);
  }
}

class CatalogItem {
  final String id, name;
  final Json fields;
  CatalogItem.fromJson(Json j)
      : id = j['id'] as String,
        name = text(j['name']),
        fields = j;
  bool get verified =>
      fields['verified'] == true ||
      fields['verificationStatus'] == 'VERIFIED' ||
      fields['verificationStatus'] == 'VALIDATED';
}

class AcademicProfileView {
  final String candidateId;
  final int version;
  final DateTime? confirmedAt;
  final Json data;
  AcademicProfileView.fromJson(Json j)
      : candidateId = j['candidateId'] as String,
        version = (j['version'] as num).toInt(),
        confirmedAt = DateTime.tryParse(j['confirmedAt']?.toString() ?? ''),
        data = j['data'] is Map ? object(j['data']) : {};
  bool get confirmed => confirmedAt != null && data['academicYearId'] != null;
  Json request(Json modifications) =>
      {...data, ...modifications, 'version': version};
}

class Recommendation {
  final String id, programId, name;
  final Eligibility eligibility;
  final double? score, coverage;
  final bool stale, sourceCurrent;
  final Json explanation;
  final DateTime? computedAt;
  Recommendation.fromJson(Json j)
      : id = j['id'] as String,
        programId = j['programId'] as String,
        name = text(
            j['explanation'] is Map ? j['explanation']['programName'] : null),
        eligibility = Eligibility.parse(j['eligibilityStatus']),
        score = decimal(j['score']),
        coverage = decimal(j['dataCoverage']),
        stale = j['stale'] == true,
        sourceCurrent = j['sourceCurrent'] == true,
        explanation = j['explanation'] is Map ? object(j['explanation']) : {},
        computedAt = DateTime.tryParse(j['computedAt']?.toString() ?? '');
}

class Decision {
  final String id, kind;
  final Json result;
  final bool profileChanged, sourceCurrent;
  final DateTime? computedAt;
  Decision.fromJson(Json j)
      : id = j['id'] as String,
        kind = j['kind'] as String,
        result = object(j['result']),
        profileChanged = j['profileChanged'] == true,
        sourceCurrent = j['sourceCurrent'] == true,
        computedAt = DateTime.tryParse(j['computedAt']?.toString() ?? '');
}

class TranscriptAnalysis {
  final String id, transcriptId, status;
  final Json data;
  TranscriptAnalysis.fromJson(Json j)
      : id = j['id'] as String,
        transcriptId = j['transcriptId'] as String,
        status = j['status'] as String,
        data = object(j['data']);
  Json get review => data['review'] is Map ? object(data['review']) : {};
  bool get confirmed => status == 'SELF_CONFIRMED';
}
