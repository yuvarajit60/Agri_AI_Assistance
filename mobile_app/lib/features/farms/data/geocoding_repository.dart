import 'package:dio/dio.dart';

class GeocodeResult {
  const GeocodeResult({required this.latitude, required this.longitude, required this.displayName});
  final double latitude;
  final double longitude;
  final String displayName;
}

/// OpenStreetMap Nominatim — free, no API key required, used here since no
/// Google Maps Geocoding key is configured yet (see
/// docs/architecture/DATA_SOURCES.md). Swap for Google Maps Geocoding
/// before any real-scale deployment: Nominatim's public instance has a
/// strict 1 req/sec usage policy and isn't meant for production traffic.
class GeocodingRepository {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      headers: {'User-Agent': 'UzhavaninNanban-AgriApp/0.1 (dev/testing use)'},
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  Future<GeocodeResult?> search(String query) async {
    final response = await _dio.get<List<dynamic>>(
      '/search',
      queryParameters: {'q': query, 'format': 'json', 'limit': 1},
    );
    final results = response.data ?? [];
    if (results.isEmpty) return null;
    final first = results.first as Map<String, dynamic>;
    return GeocodeResult(
      latitude: double.parse(first['lat'] as String),
      longitude: double.parse(first['lon'] as String),
      displayName: first['display_name'] as String,
    );
  }
}
