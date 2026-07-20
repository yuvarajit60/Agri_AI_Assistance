/// Values a farmer reads straight off a Soil Health Card or lab report.
/// Stored alongside the Farm so it's reused every time the dashboard is
/// refetched, instead of silently falling back to the satellite estimate.
class SoilLabReport {
  const SoilLabReport({
    required this.ph,
    required this.ecDsPerM,
    required this.organicCarbonPercent,
    required this.nitrogenKgPerHa,
    required this.phosphorusKgPerHa,
    required this.potassiumKgPerHa,
  });

  final double ph;
  final double ecDsPerM;
  final double organicCarbonPercent;
  final double nitrogenKgPerHa;
  final double phosphorusKgPerHa;
  final double potassiumKgPerHa;

  Map<String, dynamic> toJson() => {
        'ph': ph,
        'ecDsPerM': ecDsPerM,
        'organicCarbonPercent': organicCarbonPercent,
        'nitrogenKgPerHa': nitrogenKgPerHa,
        'phosphorusKgPerHa': phosphorusKgPerHa,
        'potassiumKgPerHa': potassiumKgPerHa,
      };

  factory SoilLabReport.fromJson(Map<String, dynamic> json) => SoilLabReport(
        ph: (json['ph'] as num).toDouble(),
        ecDsPerM: (json['ecDsPerM'] as num).toDouble(),
        organicCarbonPercent: (json['organicCarbonPercent'] as num).toDouble(),
        nitrogenKgPerHa: (json['nitrogenKgPerHa'] as num).toDouble(),
        phosphorusKgPerHa: (json['phosphorusKgPerHa'] as num).toDouble(),
        potassiumKgPerHa: (json['potassiumKgPerHa'] as num).toDouble(),
      );
}
