import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'disease_models.dart';

/// Talks to the disease_kb service (RAG over a curated organic-treatment
/// knowledge base) via the gateway proxy — see
/// backend/services/disease_kb and docs/architecture/MODULES.md §9.
class DiseaseRepository {
  Future<List<DiseaseSummary>> listDiseases() async {
    final resp = await apiClient.get<List<dynamic>>('/disease/list');
    return (resp.data ?? []).map((j) => DiseaseSummary.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<GuidanceEnvelope> searchOrganicGuidance({
    required String query,
    String? crop,
    int topK = 3,
    String language = 'en',
  }) async {
    final resp = await apiClient.post<Map<String, dynamic>>(
      '/disease/search-organic-guidance',
      data: {'query': query, if (crop != null) 'crop': crop, 'top_k': topK, 'language': language},
    );
    return GuidanceEnvelope.fromJson(resp.data!);
  }

  Future<GuidanceEnvelope> chemicalGuidance({required String query, String? crop, String language = 'en'}) async {
    final resp = await apiClient.post<Map<String, dynamic>>(
      '/disease/chemical-guidance',
      data: {'query': query, if (crop != null) 'crop': crop, 'language': language},
    );
    return GuidanceEnvelope.fromJson(resp.data!);
  }

  /// Uploads the photo for real (proving the pipeline works end to end);
  /// the backend is honest about whether it could actually be analyzed —
  /// see disease_kb/app/main.py's diagnose_photo for why a guess isn't
  /// fabricated when no vision model is configured.
  Future<GuidanceEnvelope> diagnosePhoto({
    required File photo,
    required String crop,
    String notes = '',
    String language = 'en',
  }) async {
    final formData = FormData.fromMap({
      'crop': crop,
      'notes': notes,
      'language': language,
      'photo': await MultipartFile.fromFile(photo.path, filename: photo.uri.pathSegments.last),
    });
    final resp = await apiClient.post<Map<String, dynamic>>('/disease/diagnose-photo', data: formData);
    return GuidanceEnvelope.fromJson(resp.data!);
  }
}
