import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'farm.dart';
import 'soil_report.dart';

/// Best-effort sync to the real PostgreSQL-backed farm_registry service
/// (via the gateway's proxy routes). Every method swallows network/backend
/// failures and returns null/false/empty rather than throwing — farms
/// stay fully usable offline (SharedPrefsFarmRepository is still the
/// source of truth the UI reads from); this only makes them durable
/// server-side when connectivity allows, per the offline-tolerant mobile
/// principle in docs/architecture/ARCHITECTURE.md.
class FarmSyncRepository {
  Future<String?> ensureBackendUser(String phoneNumber) async {
    try {
      final resp = await apiClient.post<Map<String, dynamic>>('/users', data: {'phone_number': phoneNumber});
      return resp.data?['id'] as String?;
    } on DioException {
      return null;
    }
  }

  Map<String, dynamic>? _soilReportJson(SoilLabReport? report) {
    if (report == null) return null;
    return {
      'ph': report.ph,
      'ec_ds_per_m': report.ecDsPerM,
      'organic_carbon_percent': report.organicCarbonPercent,
      'nitrogen_kg_per_ha': report.nitrogenKgPerHa,
      'phosphorus_kg_per_ha': report.phosphorusKgPerHa,
      'potassium_kg_per_ha': report.potassiumKgPerHa,
    };
  }

  Future<String?> createFarm({required String ownerId, required Farm farm}) async {
    try {
      final resp = await apiClient.post<Map<String, dynamic>>('/farms', data: {
        'owner_id': ownerId,
        'name': farm.name,
        'resolution_method': farm.resolutionMethod,
        'centroid_lat': farm.latitude,
        'centroid_lon': farm.longitude,
        'area_acres': farm.areaAcres,
        'soil_report': _soilReportJson(farm.soilReport),
      });
      return resp.data?['id'] as String?;
    } on DioException {
      return null;
    }
  }

  Future<bool> updateFarm(Farm farm) async {
    if (farm.serverId == null) return false;
    try {
      await apiClient.patch<Map<String, dynamic>>('/farms/${farm.serverId}', data: {
        'name': farm.name,
        'area_acres': farm.areaAcres,
        'soil_report': _soilReportJson(farm.soilReport),
        'clear_soil_report': farm.soilReport == null,
      });
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> deleteFarm(String serverId) async {
    try {
      await apiClient.delete('/farms/$serverId');
      return true;
    } on DioException {
      return false;
    }
  }

  Future<List<Farm>> fetchFarms(String ownerId) async {
    try {
      final resp = await apiClient.get<List<dynamic>>('/users/$ownerId/farms');
      final list = resp.data ?? [];
      return list.map((json) => _farmFromServerJson(json as Map<String, dynamic>)).toList();
    } on DioException {
      return [];
    }
  }

  Farm _farmFromServerJson(Map<String, dynamic> json) {
    final soilJson = json['soil_report'] as Map<String, dynamic>?;
    final id = json['id'] as String;
    return Farm(
      id: id,
      name: json['name'] as String,
      latitude: (json['centroid_lat'] as num).toDouble(),
      longitude: (json['centroid_lon'] as num).toDouble(),
      areaAcres: (json['area_acres'] as num?)?.toDouble() ?? 0,
      resolutionMethod: json['resolution_method'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      soilReport: soilJson == null
          ? null
          : SoilLabReport(
              ph: (soilJson['ph'] as num).toDouble(),
              ecDsPerM: (soilJson['ec_ds_per_m'] as num).toDouble(),
              organicCarbonPercent: (soilJson['organic_carbon_percent'] as num).toDouble(),
              nitrogenKgPerHa: (soilJson['nitrogen_kg_per_ha'] as num).toDouble(),
              phosphorusKgPerHa: (soilJson['phosphorus_kg_per_ha'] as num).toDouble(),
              potassiumKgPerHa: (soilJson['potassium_kg_per_ha'] as num).toDouble(),
            ),
      serverId: id,
    );
  }
}
