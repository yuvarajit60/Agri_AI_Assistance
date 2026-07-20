/// Static sample data so the dashboard is fully navigable before the
/// backend gateway (docs/architecture/ARCHITECTURE.md) exists. Shaped to
/// mirror the real Standard Output Contract fields (confidence, source)
/// so swapping in live API data later doesn't change the widget tree.
class MockCropRecommendation {
  const MockCropRecommendation({
    required this.name,
    required this.suitability,
    required this.expectedProfit,
    required this.riskLevel,
    required this.confidence,
    required this.term,
  });

  final String name;
  final int suitability; // %
  final String expectedProfit;
  final String riskLevel;
  final double confidence;
  final String term;
}

class MockDashboardData {
  static const farmName = 'Krishna Farm';
  static const farmArea = '4.2 acres';
  static const village = 'Wadgaon, Nashik, Maharashtra';
  static const landHealthScore = 74.0;
  static const landHealthConfidence = 0.68;

  static const weatherTodayTemp = '31°C';
  static const weatherTodayCondition = 'Partly cloudy';
  static const weatherRainChance = '20%';
  static const weatherConfidence = 0.86;
  static const weeklyForecast = [
    (day: 'Today', temp: 31, rain: 20),
    (day: 'Tue', temp: 32, rain: 10),
    (day: 'Wed', temp: 30, rain: 40),
    (day: 'Thu', temp: 29, rain: 65),
    (day: 'Fri', temp: 28, rain: 55),
    (day: 'Sat', temp: 30, rain: 15),
    (day: 'Sun', temp: 31, rain: 5),
  ];

  static const cropRecommendations = [
    MockCropRecommendation(
      name: 'Cotton',
      suitability: 88,
      expectedProfit: '₹42,000/acre',
      riskLevel: 'Medium',
      confidence: 0.81,
      term: 'Short-term',
    ),
    MockCropRecommendation(
      name: 'Maize',
      suitability: 82,
      expectedProfit: '₹28,500/acre',
      riskLevel: 'Low',
      confidence: 0.77,
      term: 'Short-term',
    ),
    MockCropRecommendation(
      name: 'Banana',
      suitability: 75,
      expectedProfit: '₹1,10,000/acre',
      riskLevel: 'Medium',
      confidence: 0.64,
      term: 'Medium-term',
    ),
    MockCropRecommendation(
      name: 'Pomegranate',
      suitability: 70,
      expectedProfit: '₹1,85,000/acre',
      riskLevel: 'High',
      confidence: 0.58,
      term: 'Long-term',
    ),
  ];

  static const marketCommodity = 'Cotton';
  static const marketPriceRange = '₹6,800 – ₹7,400 / quintal';
  static const marketBestMonth = 'November';
  static const marketConfidence = 0.71;

  static const disasterRiskLevel = 'Moderate';
  static const disasterRiskType = 'Heavy rain (next 5–7 days)';
  static const disasterConfidence = 0.62;
}
