/// The API Gateway is deployed to Render (see docs/architecture/ROADMAP.md
/// "Deployment reality") — this points at its public HTTPS URL by default.
/// Override with `--dart-define=GATEWAY_BASE_URL=http://lan-ip:8000` for
/// local backend development against a gateway running on your machine.
abstract final class AppConfig {
  static const String gatewayBaseUrl = String.fromEnvironment(
    'GATEWAY_BASE_URL',
    defaultValue: 'https://agri-gateway-mdxn.onrender.com',
  );
}
