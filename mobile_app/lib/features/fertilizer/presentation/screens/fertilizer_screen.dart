import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confidence_badge.dart';
import '../../../dashboard/data/dashboard_data.dart';

class FertilizerScreen extends ConsumerWidget {
  const FertilizerScreen({super.key, required this.section});
  final FertilizerRecommendationSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.fertilizerRecommendationTitle),
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
          if (!section.cropReferenceMatched)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Text(s.cropNotInReferenceList(s.cropName(section.cropName)), style: Theme.of(context).textTheme.bodySmall),
            ),
          Text(s.nutrientGapTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _NutrientRow(label: s.nitrogenLabel, value: section.nitrogenGapKgPerHa),
                  const Divider(height: 20),
                  _NutrientRow(label: s.phosphorusLabel, value: section.phosphorusGapKgPerHa),
                  const Divider(height: 20),
                  _NutrientRow(label: s.potassiumLabel, value: section.potassiumGapKgPerHa),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(s.recommendedProductsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (section.products.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(s.noFertilizerNeeded, style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final p in section.products)
                      ListTile(
                        leading: const Icon(Icons.science_outlined, color: AppColors.primary),
                        title: Text(p.product),
                        subtitle: Text(p.nutrientSupplied),
                        trailing: Text(
                          '${p.quantityKgTotal.toStringAsFixed(0)} kg',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (section.applicationSchedule.isNotEmpty && section.applicationSchedule.first.stage != 'none_needed') ...[
            const SizedBox(height: 20),
            Text(s.applicationScheduleTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final stage in section.applicationSchedule)
                      ListTile(
                        leading: const Icon(Icons.event_outlined, color: AppColors.primary),
                        title: Text(s.fertilizerStage(stage.stage)),
                        subtitle: Text('${s.fertilizerTiming(stage.timing)} · ${stage.products.join(', ')}'),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (section.phCorrection != null) ...[
            const SizedBox(height: 20),
            Text(s.phCorrectionTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(section.phCorrection!, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          ],
          if (section.organicMatterNote != null) ...[
            const SizedBox(height: 20),
            Text(s.organicMatterTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(section.organicMatterNote!, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text('${value.toStringAsFixed(0)} kg/ha', style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
