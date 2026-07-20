import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../farms/data/soil_report.dart';
import 'dashboard_data.dart';

abstract class DashboardRepository {
  Future<DashboardData> fetchDashboard({
    required double latitude,
    required double longitude,
    required double areaAcres,
    String season = 'any',
    SoilLabReport? soilReport,
  });
}

class GatewayDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardData> fetchDashboard({
    required double latitude,
    required double longitude,
    required double areaAcres,
    String season = 'any',
    SoilLabReport? soilReport,
  }) async {
    final query = <String, dynamic>{
      'lat': latitude,
      'lon': longitude,
      'area_acres': areaAcres,
      'season': season,
    };
    if (soilReport != null) {
      query.addAll({
        'soil_ph': soilReport.ph,
        'soil_ec': soilReport.ecDsPerM,
        'soil_oc': soilReport.organicCarbonPercent,
        'soil_n': soilReport.nitrogenKgPerHa,
        'soil_p': soilReport.phosphorusKgPerHa,
        'soil_k': soilReport.potassiumKgPerHa,
      });
    }
    final response = await apiClient.get<Map<String, dynamic>>('/dashboard', queryParameters: query);
    return DashboardData.fromJson(response.data!);
  }
}

class DashboardFetchException implements Exception {
  DashboardFetchException(this.message);
  final String message;

  factory DashboardFetchException.fromDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
      return DashboardFetchException(
        'Could not reach the backend. Make sure your phone is on the same WiFi as the server.',
      );
    }
    return DashboardFetchException('Failed to load farm data: ${e.message}');
  }

  @override
  String toString() => message;
}
