import 'package:dio/dio.dart';
import '../config/app_config.dart';

final Dio apiClient = Dio(
  BaseOptions(
    baseUrl: AppConfig.gatewayBaseUrl,
    // Kept short deliberately: this hits a LAN dev server, so a slow
    // response almost always means "unreachable", not "still working" —
    // fail fast and let the UI's retry button take it from there.
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 8),
  ),
);
