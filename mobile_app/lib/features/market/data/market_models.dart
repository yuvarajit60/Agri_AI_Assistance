/// Mirrors the gateway's `/market/price-forecast` response, shaped by
/// backend/services/market_price/app/schemas.py's PriceForecastResult
/// wrapped in the RecommendationEnvelope contract.
class MarketForecastSection {
  const MarketForecastSection({
    required this.commodity,
    required this.currentPriceInr,
    required this.nearTermLowInr,
    required this.nearTermHighInr,
    required this.bestSellingMonth,
    required this.bestSellingMonthPriceInr,
    required this.forecastPoints,
    required this.nearbyMandis,
    required this.confidence,
  });

  final String commodity;
  final double currentPriceInr;
  final double nearTermLowInr;
  final double nearTermHighInr;
  final String bestSellingMonth;
  final double bestSellingMonthPriceInr;
  final List<ForecastPoint> forecastPoints;
  final List<MandiInfo> nearbyMandis;
  final double confidence;

  factory MarketForecastSection.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? {};
    final pointsRaw = (result['forecast_points'] as List?) ?? const [];
    final mandisRaw = (result['nearby_mandis'] as List?) ?? const [];
    return MarketForecastSection(
      commodity: result['commodity'] as String? ?? '',
      currentPriceInr: (result['current_price_inr_per_quintal'] as num?)?.toDouble() ?? 0,
      nearTermLowInr: (result['near_term_low_inr_per_quintal'] as num?)?.toDouble() ?? 0,
      nearTermHighInr: (result['near_term_high_inr_per_quintal'] as num?)?.toDouble() ?? 0,
      bestSellingMonth: result['best_selling_month'] as String? ?? '',
      bestSellingMonthPriceInr: (result['best_selling_month_price_inr_per_quintal'] as num?)?.toDouble() ?? 0,
      forecastPoints: pointsRaw.map((p) => ForecastPoint.fromJson(p as Map<String, dynamic>)).toList(),
      nearbyMandis: mandisRaw.map((m) => MandiInfo.fromJson(m as Map<String, dynamic>)).toList(),
      confidence: (json['confidence_score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ForecastPoint {
  const ForecastPoint({required this.weekStart, required this.predictedPriceInr});
  final DateTime weekStart;
  final double predictedPriceInr;

  factory ForecastPoint.fromJson(Map<String, dynamic> json) => ForecastPoint(
        weekStart: DateTime.tryParse(json['week_start'] as String? ?? '') ?? DateTime.now(),
        predictedPriceInr: (json['predicted_price_inr_per_quintal'] as num?)?.toDouble() ?? 0,
      );
}

class MandiInfo {
  const MandiInfo({required this.name, required this.distanceKm, required this.latestPriceInr});
  final String name;
  final double distanceKm;
  final double latestPriceInr;

  factory MandiInfo.fromJson(Map<String, dynamic> json) => MandiInfo(
        name: json['name'] as String? ?? '',
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
        latestPriceInr: (json['latest_price_inr_per_quintal'] as num?)?.toDouble() ?? 0,
      );
}
