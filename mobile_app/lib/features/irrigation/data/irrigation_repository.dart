import '../../../core/network/api_client.dart';
import '../../dashboard/data/dashboard_data.dart';

/// On-demand plan lookup for a specific crop, via the gateway's
/// /irrigation/plan proxy (backend/services/gateway/app/main.py). The
/// dashboard's own /dashboard call already resolves one plan for free —
/// the top recommended crop — so this is only used when the farmer picks
/// a *different* recommended crop to compare, same pattern as
/// MarketRepository.
class IrrigationRepository {
  Future<IrrigationPlanSection> fetchPlan({
    required String cropName,
    required double cropWaterRequirementMm,
    required int cropDurationDays,
    required double farmAreaAcres,
    String? irrigationMethod,
    double? soilMoisturePercent,
    String language = 'en',
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/irrigation/plan',
      data: {
        'crop_name': cropName,
        'crop_water_requirement_mm': cropWaterRequirementMm,
        'crop_duration_days': cropDurationDays,
        'farm_area_acres': farmAreaAcres,
        'irrigation_method': irrigationMethod,
        'soil_moisture_percent': soilMoisturePercent,
        'language': language,
      },
    );
    return IrrigationPlanSection.fromJson(response.data!);
  }
}
