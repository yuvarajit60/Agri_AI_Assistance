/// Dev-only backend location. The API Gateway isn't deployed anywhere yet
/// (see docs/architecture/ARCHITECTURE.md) — this points at the gateway
/// running on a developer machine's LAN IP so a phone on the same WiFi can
/// reach it. Replace with a real deployed URL (and switch off cleartext
/// HTTP in the Android manifest) before this ships to anyone else.
abstract final class AppConfig {
  static const String gatewayBaseUrl = String.fromEnvironment(
    'GATEWAY_BASE_URL',
    defaultValue: 'http://192.168.0.102:8000',
  );
}
