/// Defensive parsing of the gateway's `/dashboard` response
/// (services/gateway/app/main.py). Every section is nullable because the
/// gateway itself degrades gracefully — a downstream service being down
/// means a null section plus a warning, not a failed request.
class DashboardData {
  const DashboardData({
    required this.generatedAt,
    this.landHealth,
    this.weather,
    this.cropRecommendation,
    this.warnings = const [],
  });

  final DateTime generatedAt;
  final LandHealthSection? landHealth;
  final WeatherSection? weather;
  final CropRecommendationSection? cropRecommendation;
  final List<String> warnings;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      generatedAt: DateTime.tryParse(json['generated_at'] as String? ?? '') ?? DateTime.now(),
      landHealth: json['land_health'] != null
          ? LandHealthSection.fromJson(json['land_health'] as Map<String, dynamic>)
          : null,
      weather: json['weather'] != null ? WeatherSection.fromJson(json['weather'] as Map<String, dynamic>) : null,
      cropRecommendation: json['crop_recommendations'] != null
          ? CropRecommendationSection.fromJson(json['crop_recommendations'] as Map<String, dynamic>)
          : null,
      warnings: (json['warnings'] as List?)?.cast<String>() ?? const [],
    );
  }
}

class LandHealthSection {
  const LandHealthSection({required this.score, required this.confidence, required this.subIndices});
  final double score;
  final double confidence;
  final Map<String, double> subIndices;

  factory LandHealthSection.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? {};
    final subIndicesRaw = result['sub_indices'] as Map<String, dynamic>? ?? {};
    return LandHealthSection(
      score: (result['land_health_score'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence_score'] as num?)?.toDouble() ?? 0,
      subIndices: subIndicesRaw.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }
}

class WeatherSection {
  const WeatherSection({
    required this.avgTempC,
    required this.totalRainfallMm,
    required this.humidityPercent,
    required this.confidence,
    required this.daily,
  });
  final double avgTempC;
  final double totalRainfallMm;
  final int humidityPercent;
  final double confidence;
  final List<DailyForecast> daily;

  factory WeatherSection.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? {};
    final dailyRaw = (result['daily'] as List?) ?? const [];
    return WeatherSection(
      avgTempC: (result['avg_temp_c'] as num?)?.toDouble() ?? 0,
      totalRainfallMm: (result['total_rainfall_mm'] as num?)?.toDouble() ?? 0,
      humidityPercent: (result['avg_humidity_percent'] as num?)?.toInt() ?? 0,
      confidence: (json['confidence_score'] as num?)?.toDouble() ?? 0,
      daily: dailyRaw.map((d) => DailyForecast.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}

class DailyForecast {
  const DailyForecast({required this.dayOffset, required this.avgTempC, required this.rainProbabilityPercent});
  final int dayOffset;
  final double avgTempC;
  final int rainProbabilityPercent;

  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
        dayOffset: (json['day_offset'] as num?)?.toInt() ?? 0,
        avgTempC: (json['avg_temp_c'] as num?)?.toDouble() ?? 0,
        rainProbabilityPercent: (json['rain_probability_percent'] as num?)?.toInt() ?? 0,
      );
}

class CropRecommendationSection {
  const CropRecommendationSection({required this.top, required this.alternatives, required this.confidence});
  final CropRecommendation top;
  final List<CropRecommendation> alternatives;
  final double confidence;

  factory CropRecommendationSection.fromJson(Map<String, dynamic> json) {
    final alternativesRaw = (json['alternatives'] as List?) ?? const [];
    return CropRecommendationSection(
      top: CropRecommendation.fromJson(json['result'] as Map<String, dynamic>? ?? {}),
      alternatives: alternativesRaw.map((a) => CropRecommendation.fromJson(a as Map<String, dynamic>)).toList(),
      confidence: (json['confidence_score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CropRecommendation {
  const CropRecommendation({
    required this.cropName,
    required this.term,
    required this.suitabilityPercent,
    required this.expectedYieldQuintals,
    required this.waterRequirementMm,
    required this.investmentInr,
    required this.maintenanceCostInr,
    required this.expectedProfitInr,
    required this.timeToHarvestDays,
    required this.riskLevel,
    required this.roiPercent,
  });
  final String cropName;
  final String term;
  final double suitabilityPercent;
  final double expectedYieldQuintals;
  final int waterRequirementMm;
  final double investmentInr;
  final double maintenanceCostInr;
  final double expectedProfitInr;
  final int timeToHarvestDays;
  final String riskLevel;
  final double roiPercent;

  factory CropRecommendation.fromJson(Map<String, dynamic> json) => CropRecommendation(
        cropName: json['crop_name'] as String? ?? 'Unknown',
        term: json['term'] as String? ?? 'short-term',
        suitabilityPercent: (json['suitability_percent'] as num?)?.toDouble() ?? 0,
        expectedYieldQuintals: (json['expected_yield_quintals'] as num?)?.toDouble() ?? 0,
        waterRequirementMm: (json['water_requirement_mm'] as num?)?.toInt() ?? 0,
        investmentInr: (json['investment_inr'] as num?)?.toDouble() ?? 0,
        maintenanceCostInr: (json['maintenance_cost_inr'] as num?)?.toDouble() ?? 0,
        expectedProfitInr: (json['expected_profit_inr'] as num?)?.toDouble() ?? 0,
        timeToHarvestDays: (json['time_to_harvest_days'] as num?)?.toInt() ?? 0,
        riskLevel: json['risk_level'] as String? ?? 'medium',
        roiPercent: (json['roi_percent'] as num?)?.toDouble() ?? 0,
      );
}
