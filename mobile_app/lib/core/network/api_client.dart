import 'package:dio/dio.dart';
import '../config/app_config.dart';

final Dio apiClient = Dio(
  BaseOptions(
    baseUrl: AppConfig.gatewayBaseUrl,
    // The cloud gateway's free-tier downstream services spin down after
    // ~15 min idle and take 12-22s to wake (observed) — the gateway itself
    // waits up to 30s per upstream call (see backend config.py), so these
    // need enough headroom for a full cold-start round trip, not just a
    // "server is reachable" ping.
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 45),
  ),
);
