import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/academic_models.dart';
import '../network/api_client.dart';

class OrientationRepository {
  final ApiClient api;
  OrientationRepository(this.api);
  Future<AcademicProfileView> profile() async => AcademicProfileView.fromJson(
      object((await api.getCandidateProfile()).data));
  Future<AcademicProfileView> saveProfile(Json data) async =>
      AcademicProfileView.fromJson(
          object((await api.updateCandidateProfile(data)).data));
  Future<List<Json>> references(String path, {Json? filters}) async =>
      objects((await api.call('/$path', query: filters)).data);
  Future<PageData<CatalogItem>> catalog(String kind,
          {int page = 0, Json filters = const {}}) async =>
      PageData.parse(
          (await api.catalog(kind, page: page, filters: filters)).data,
          CatalogItem.fromJson);
  Future<Json> detail(String kind, String id) async =>
      object((await api.call('/$kind/$id')).data);
  Future<List<Json>> sources(String kind, String id) async =>
      objects((await api.call('/$kind/$id/sources')).data);
  Future<List<Json>> admissionCriteria(String programId) async {
    final result = <Json>[];
    for (var page = 0; page < 100; page++) {
      final current = PageData<Json>.parse(
          (await api.call('/admission-criteria', query: {
            'programId': programId,
            'page': page,
            'size': 100
          }))
              .data,
          (value) => value);
      result.addAll(current.content);
      if (!current.hasNext) return result;
      if (current.page != page || current.content.isEmpty) {
        throw const FormatException('Pagination des critères incohérente');
      }
    }
    throw const FormatException(
        'Trop de critères pour afficher une liste complète');
  }

  Future<PageData<Recommendation>> recommendations(
          {int page = 0, String? runId}) async =>
      PageData.parse(
          (await api.call('/recommendations', query: {
            'page': page,
            'size': 20,
            if (runId != null) 'runId': runId
          }))
              .data,
          Recommendation.fromJson);
  Future<String> generate() async {
    final p = await profile();
    if (!p.confirmed) throw const FormatException('Profil à confirmer');
    return object((await api.generateRecommendations({})).data)['runId']
        as String;
  }

  Future<Decision> simulate(Json changes) async => Decision.fromJson(
      object((await api.simulateRecommendation(changes)).data));
  Future<Decision> compare(List<String> ids) async {
    final comparison = object((await api.comparePrograms(ids)).data);
    return decision(comparison['id'] as String);
  }

  Future<Decision> scholarships({String? id, String? programId}) async =>
      Decision.fromJson(object(
          (await api.call('/scholarships/evaluate', method: 'POST', data: {
        if (id != null) 'scholarshipIds': [id],
        if (programId != null) 'programId': programId
      }))
              .data));
  Future<PageData<Decision>> history(String kind, {int page = 0}) async =>
      PageData.parse(
          (await api.call('/ai/decisions',
                  query: {'kind': kind, 'page': page, 'size': 20}))
              .data,
          Decision.fromJson);
  Future<Decision> decision(String id) async =>
      Decision.fromJson(object((await api.call('/ai/decisions/$id')).data));
  Future<PageData<Json>> recommendationRuns(
          {int page = 0}) async =>
      PageData.parse(
          (await api.call('/recommendations/history',
                  query: {'page': page, 'size': 20}))
              .data,
          (j) => j);
  Future<PageData<Json>> transcripts({int page = 0}) async =>
      PageData.parse((await api.getTranscripts(page: page)).data, (j) => j);
  Future<Json> upload(Uint8List bytes, String extension, String year,
      {ProgressCallback? progress}) async {
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const FormatException('Taille de document invalide');
    }
    final pdf =
        bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-';
    final png = bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71;
    final jpg = bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    if (!(extension == 'pdf' && pdf ||
        extension == 'png' && png ||
        ['jpg', 'jpeg'].contains(extension) && jpg)) {
      throw const FormatException('Signature ou type de fichier invalide');
    }
    final form = FormData.fromMap({
      'academicYearId': year,
      'file': MultipartFile.fromBytes(bytes, filename: 'releve.$extension')
    });
    return object(
        (await api.uploadTranscript(form, onProgress: progress)).data);
  }

  Future<PageData<TranscriptAnalysis>> analyses(String id,
          {int page = 0}) async =>
      PageData.parse(
          (await api.call('/transcripts/$id/analyses',
                  query: {'page': page, 'size': 20}))
              .data,
          TranscriptAnalysis.fromJson);
  Future<TranscriptAnalysis> analyze(
          String id, String scale, String period) async =>
      TranscriptAnalysis.fromJson(object((await api.call(
              '/transcripts/$id/analyses',
              method: 'POST',
              data: {'gradeScaleId': scale, 'period': period}))
          .data));
  Future<TranscriptAnalysis> correct(TranscriptAnalysis a, Json review) async =>
      TranscriptAnalysis.fromJson(object((await api.call(
              '/transcripts/${a.transcriptId}/analyses/${a.id}',
              method: 'PUT',
              data: review))
          .data));
  Future<TranscriptAnalysis> confirm(TranscriptAnalysis a) async =>
      TranscriptAnalysis.fromJson(object((await api.call(
              '/transcripts/${a.transcriptId}/analyses/${a.id}/confirm',
              method: 'POST'))
          .data));
  Future<Uint8List> export(String id, String format) async {
    if (!['pdf', 'csv', 'excel'].contains(format)) {
      throw ArgumentError('Format');
    }
    final response = await api.call('/ai/export/$format/$id',
        responseType: ResponseType.bytes);
    final data = Uint8List.fromList(List<int>.from(response.data as List));
    if (format == 'pdf' &&
        (data.length < 5 || String.fromCharCodes(data.take(5)) != '%PDF-')) {
      throw const FormatException('PDF invalide');
    }
    if (format == 'excel' &&
        (data.length < 2 || data[0] != 80 || data[1] != 75)) {
      throw const FormatException('XLSX invalide');
    }
    return data;
  }
}
