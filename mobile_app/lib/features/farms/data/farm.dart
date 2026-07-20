import 'soil_report.dart';

class Farm {
  const Farm({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.areaAcres,
    required this.resolutionMethod,
    required this.createdAt,
    this.soilReport,
    this.serverId,
  });

  /// Local (client-generated) identity — stable even before the farm has
  /// ever reached the backend, so the UI never has to special-case an
  /// "unsynced" farm.
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double areaAcres;
  final String resolutionMethod;
  final DateTime createdAt;
  final SoilLabReport? soilReport;

  /// The farm_registry-assigned UUID once this farm has synced to
  /// PostgreSQL — null means "local only" (offline, or sync hasn't
  /// happened yet). See farm_sync_repository.dart.
  final String? serverId;

  Farm copyWith({
    String? name,
    double? areaAcres,
    SoilLabReport? soilReport,
    bool clearSoilReport = false,
    String? serverId,
  }) {
    return Farm(
      id: id,
      name: name ?? this.name,
      latitude: latitude,
      longitude: longitude,
      areaAcres: areaAcres ?? this.areaAcres,
      resolutionMethod: resolutionMethod,
      createdAt: createdAt,
      soilReport: clearSoilReport ? null : (soilReport ?? this.soilReport),
      serverId: serverId ?? this.serverId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'areaAcres': areaAcres,
        'resolutionMethod': resolutionMethod,
        'createdAt': createdAt.toIso8601String(),
        'soilReport': soilReport?.toJson(),
        'serverId': serverId,
      };

  factory Farm.fromJson(Map<String, dynamic> json) => Farm(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        areaAcres: (json['areaAcres'] as num).toDouble(),
        resolutionMethod: json['resolutionMethod'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        soilReport:
            json['soilReport'] != null ? SoilLabReport.fromJson(json['soilReport'] as Map<String, dynamic>) : null,
        serverId: json['serverId'] as String?,
      );
}
