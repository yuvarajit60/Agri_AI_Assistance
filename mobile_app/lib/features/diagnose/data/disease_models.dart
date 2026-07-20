class DiseaseSource {
  const DiseaseSource({required this.name, required this.url});
  final String name;
  final String url;

  factory DiseaseSource.fromJson(Map<String, dynamic> json) =>
      DiseaseSource(name: json['name'] as String, url: json['url'] as String);
}

class DiseaseSummary {
  const DiseaseSummary({required this.id, required this.diseaseName, required this.crops});
  final String id;
  final String diseaseName;
  final List<String> crops;

  factory DiseaseSummary.fromJson(Map<String, dynamic> json) => DiseaseSummary(
        id: json['id'] as String,
        diseaseName: json['disease_name'] as String,
        crops: (json['crops'] as List).cast<String>(),
      );
}

class DiseaseMatch {
  const DiseaseMatch({
    required this.diseaseId,
    required this.diseaseName,
    required this.pathogen,
    required this.crops,
    required this.symptoms,
    required this.favorableConditions,
    required this.organicTreatment,
    required this.prevention,
    required this.sources,
    required this.similarityScore,
  });

  final String diseaseId;
  final String diseaseName;
  final String pathogen;
  final List<String> crops;
  final String symptoms;
  final String favorableConditions;
  final String organicTreatment;
  final String prevention;
  final List<DiseaseSource> sources;
  final double similarityScore;

  factory DiseaseMatch.fromJson(Map<String, dynamic> json) => DiseaseMatch(
        diseaseId: json['disease_id'] as String,
        diseaseName: json['disease_name'] as String,
        pathogen: json['pathogen'] as String? ?? '',
        crops: ((json['crops'] as List?) ?? []).cast<String>(),
        symptoms: json['symptoms'] as String? ?? '',
        favorableConditions: json['favorable_conditions'] as String? ?? '',
        organicTreatment: json['organic_treatment'] as String? ?? '',
        prevention: json['prevention'] as String? ?? '',
        sources: ((json['sources'] as List?) ?? []).map((s) => DiseaseSource.fromJson(s as Map<String, dynamic>)).toList(),
        similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0,
      );
}

/// Mirrors the backend's Standard Output Contract envelope
/// (docs/architecture/ARCHITECTURE.md §9) — every diagnosis response
/// carries confidence, assumptions, reasoning and an action plan, not
/// just a bare answer.
class GuidanceEnvelope {
  const GuidanceEnvelope({
    required this.confidenceScore,
    required this.assumptions,
    required this.reasoning,
    required this.actionPlan,
    this.topMatch,
    this.alternatives = const [],
    this.riskLevel,
  });

  final double confidenceScore;
  final List<String> assumptions;
  final String reasoning;
  final List<String> actionPlan;
  final DiseaseMatch? topMatch;
  final List<DiseaseMatch> alternatives;
  final String? riskLevel;

  factory GuidanceEnvelope.fromJson(Map<String, dynamic> json) {
    final resultJson = json['result'] as Map<String, dynamic>?;
    final isDiseaseMatch = resultJson != null && resultJson.containsKey('disease_id');
    return GuidanceEnvelope(
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0,
      assumptions: ((json['assumptions'] as List?) ?? []).cast<String>(),
      reasoning: json['reasoning'] as String? ?? '',
      actionPlan: ((json['action_plan'] as List?) ?? []).cast<String>(),
      topMatch: isDiseaseMatch ? DiseaseMatch.fromJson(resultJson) : null,
      alternatives: ((json['alternatives'] as List?) ?? [])
          .where((a) => a is Map<String, dynamic> && a.containsKey('disease_id'))
          .map((a) => DiseaseMatch.fromJson(a as Map<String, dynamic>))
          .toList(),
      riskLevel: (json['risk_analysis'] as Map<String, dynamic>?)?['level'] as String?,
    );
  }
}
