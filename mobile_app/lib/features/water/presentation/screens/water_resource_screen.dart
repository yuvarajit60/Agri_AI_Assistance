import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confidence_badge.dart';
import '../../../dashboard/data/dashboard_data.dart';

class WaterResourceScreen extends ConsumerWidget {
  const WaterResourceScreen({super.key, required this.section});
  final WaterResourceSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.waterResourcesTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: ConfidenceBadge(score: section.confidence, compact: true)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(s.nearbyWaterSources, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (section.features.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(s.noWaterFeaturesFound, style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final f in section.features)
                      ListTile(
                        leading: const Icon(Icons.water_outlined, color: AppColors.info),
                        title: Text(s.waterFeatureType(f.type)),
                        subtitle: Text(
                          '${s.seasonalAvailability(f.seasonalAvailability)} · ${s.waterAvailabilityLevel(f.estimatedWaterAvailability)}',
                        ),
                        trailing: Text(s.distanceAway(f.distanceKm.toStringAsFixed(1))),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(s.groundwaterStatus, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.groundwaterCategory(section.groundwaterCategory), style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(s.depthBelowGround(section.depthToWaterTableM.toStringAsFixed(1)),
                      style: Theme.of(context).textTheme.bodyMedium),
                  const Divider(height: 24),
                  Text(s.borewellFeasibility, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(section.borewellFeasibility, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(s.irrigationFeasibilitySection, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(s.irrigationMethod(section.irrigationMethod), style: Theme.of(context).textTheme.headlineMedium),
                      if (section.nearestSourceDistanceKm != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          s.distanceAway(section.nearestSourceDistanceKm!.toStringAsFixed(1)),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(section.irrigationNotes, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
