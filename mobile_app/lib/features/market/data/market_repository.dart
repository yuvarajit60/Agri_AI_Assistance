import '../../../core/network/api_client.dart';
import 'market_models.dart';

/// On-demand forecast lookup for a specific commodity, via the gateway's
/// /market/price-forecast proxy (backend/services/gateway/app/main.py).
/// The dashboard's own /dashboard call already resolves one forecast for
/// free — the top recommended crop — so this is only used when the farmer
/// picks a *different* crop than the top recommendation to compare.
class MarketRepository {
  Future<MarketForecastSection> fetchForecast({
    required String commodity,
    required double latitude,
    required double longitude,
    String language = 'en',
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/market/price-forecast',
      data: {'commodity': commodity, 'lat': latitude, 'lon': longitude, 'language': language},
    );
    return MarketForecastSection.fromJson(response.data!);
  }
}
