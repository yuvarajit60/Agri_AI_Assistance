import '../../../core/network/api_client.dart';
import '../../dashboard/data/dashboard_data.dart';

/// On-demand recommendation lookup for a specific crop, via the gateway's
/// /fertilizer/recommend proxy (backend/services/gateway/app/main.py). The
/// dashboard's own /dashboard call already resolves one recommendation for
/// free — the top recommended crop — so this is only used when the farmer
/// picks a *different* recommended crop to compare, same pattern as
/// MarketRepository / IrrigationRepository.
class FertilizerRepository {
  Future<FertilizerRecommendationSection> fetchRecommendation({
    required String cropName,
    required double farmAreaAcres,
    required double soilNitrogenKgPerHa,
    required double soilPhosphorusKgPerHa,
    required double soilPotassiumKgPerHa,
    required double soilPh,
    required double organicCarbonPercent,
    required double soilConfidence,
    String language = 'en',
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/fertilizer/recommend',
      data: {
        'crop_name': cropName,
        'farm_area_acres': farmAreaAcres,
        'soil_nitrogen_kg_per_ha': soilNitrogenKgPerHa,
        'soil_phosphorus_kg_per_ha': soilPhosphorusKgPerHa,
        'soil_potassium_kg_per_ha': soilPotassiumKgPerHa,
        'soil_ph': soilPh,
        'organic_carbon_percent': organicCarbonPercent,
        'soil_confidence': soilConfidence,
        'language': language,
      },
    );
    return FertilizerRecommendationSection.fromJson(response.data!);
  }
}
