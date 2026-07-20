import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confidence_badge.dart';
import '../../data/dashboard_data.dart';

/// Smart Comparison (docs/architecture/MODULES.md §7) — every field the
/// Crop Recommendation Engine actually computes, side by side, not just
/// the subset shown on the dashboard's compact crop cards.
class CropComparisonScreen extends ConsumerWidget {
  const CropComparisonScreen({super.key, required this.section});
  final CropRecommendationSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final crops = [section.top, ...section.alternatives];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.compareCrops),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: ConfidenceBadge(score: section.confidence, compact: true)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceAlt),
          columns: [
            DataColumn(label: Text(s.colCrop)),
            DataColumn(label: Text(s.colTerm)),
            DataColumn(label: Text(s.colSuitability), numeric: true),
            DataColumn(label: Text(s.colYield), numeric: true),
            DataColumn(label: Text(s.colWater), numeric: true),
            DataColumn(label: Text(s.colInvestment), numeric: true),
            DataColumn(label: Text(s.colMaintenance), numeric: true),
            DataColumn(label: Text(s.colProfit), numeric: true),
            DataColumn(label: Text(s.colRoi), numeric: true),
            DataColumn(label: Text(s.colHarvestDays), numeric: true),
            DataColumn(label: Text(s.colRisk)),
            DataColumn(label: Text(s.colRank), numeric: true),
          ],
          rows: [
            for (int i = 0; i < crops.length; i++) _buildRow(crops[i], i + 1, s),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(CropRecommendation crop, int rank, AppStrings s) {
    Color riskColor;
    String riskText;
    switch (crop.riskLevel) {
      case 'low':
        riskColor = AppColors.confidenceHigh;
        riskText = s.lowRisk;
      case 'high':
        riskColor = AppColors.confidenceLow;
        riskText = s.highRisk;
      default:
        riskColor = AppColors.confidenceMedium;
        riskText = s.mediumRisk;
    }

    return DataRow(
      cells: [
        DataCell(Text(crop.cropName, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(crop.term)),
        DataCell(Text('${crop.suitabilityPercent.toStringAsFixed(0)}%')),
        DataCell(Text(crop.expectedYieldQuintals.toStringAsFixed(1))),
        DataCell(Text('${crop.waterRequirementMm}')),
        DataCell(Text('₹${crop.investmentInr.toStringAsFixed(0)}')),
        DataCell(Text('₹${crop.maintenanceCostInr.toStringAsFixed(0)}')),
        DataCell(Text('₹${crop.expectedProfitInr.toStringAsFixed(0)}')),
        DataCell(Text('${crop.roiPercent.toStringAsFixed(0)}%')),
        DataCell(Text('${crop.timeToHarvestDays}')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(riskText),
            ],
          ),
        ),
        DataCell(Text('#$rank')),
      ],
    );
  }
}
