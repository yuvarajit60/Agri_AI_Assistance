import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confidence_badge.dart';
import '../../../dashboard/data/dashboard_data.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../farms/presentation/providers/farm_provider.dart';
import '../../data/fertilizer_repository.dart';

/// Reached from the dashboard's Fertilizer card. Same crop-selector
/// pattern as MarketScreen/IrrigationScreen — the dashboard's own
/// /dashboard call already resolves a recommendation for the top
/// recommended crop for free; picking a different recommended crop
/// fetches its recommendation on demand, since fertilizer need is
/// genuinely crop-specific.
class FertilizerScreen extends ConsumerStatefulWidget {
  const FertilizerScreen({super.key});

  @override
  ConsumerState<FertilizerScreen> createState() => _FertilizerScreenState();
}

class _FertilizerScreenState extends ConsumerState<FertilizerScreen> {
  final _repository = FertilizerRepository();

  String? _selectedCropName;
  AsyncValue<FertilizerRecommendationSection>? _selectedRecommendation;

  Future<void> _selectCrop(String cropName, double farmAreaAcres, LandHealthSection? soil, double soilConfidence) async {
    if (soil == null) return;
    setState(() {
      _selectedCropName = cropName;
      _selectedRecommendation = const AsyncValue.loading();
    });
    try {
      final recommendation = await _repository.fetchRecommendation(
        cropName: cropName,
        farmAreaAcres: farmAreaAcres,
        soilNitrogenKgPerHa: soil.nitrogenKgPerHa,
        soilPhosphorusKgPerHa: soil.phosphorusKgPerHa,
        soilPotassiumKgPerHa: soil.potassiumKgPerHa,
        soilPh: soil.ph,
        organicCarbonPercent: soil.organicCarbonPercent,
        soilConfidence: soilConfidence,
        language: ref.read(languageProvider),
      );
      if (!mounted) return;
      setState(() => _selectedRecommendation = AsyncValue.data(recommendation));
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _selectedRecommendation = AsyncValue.error(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final activeFarm = ref.watch(activeFarmProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
    final data = dashboardState.value;

    Widget body;
    if (activeFarm == null || data == null || data.fertilizerRecommendation == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(s.fertilizerRecommendationUnavailable, textAlign: TextAlign.center),
        ),
      );
    } else {
      final crops = data.cropRecommendation;
      final topCropName = crops?.top.cropName;
      final isViewingTop = _selectedCropName == null || _selectedCropName == topCropName;
      final currentRecommendation =
          isViewingTop ? AsyncValue.data(data.fertilizerRecommendation!) : _selectedRecommendation;
      final soilConfidence = data.landHealth?.confidence ?? 0.6;

      body = Column(
        children: [
          if (crops != null && crops.alternatives.isNotEmpty)
            _CropSelector(
              crops: [crops.top, ...crops.alternatives],
              selectedCropName: _selectedCropName ?? topCropName,
              s: s,
              onSelect: (cropName) => _selectCrop(cropName, activeFarm.areaAcres, data.landHealth, soilConfidence),
            ),
          Expanded(
            child: switch (currentRecommendation) {
              AsyncData(:final value) => _FertilizerBody(section: value, s: s),
              AsyncError(:final error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(error.toString(), textAlign: TextAlign.center),
                  ),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      );
    }

    return Scaffold(appBar: AppBar(title: Text(s.fertilizerRecommendationTitle)), body: SafeArea(child: body));
  }
}

class _CropSelector extends StatelessWidget {
  const _CropSelector({required this.crops, required this.selectedCropName, required this.s, required this.onSelect});
  final List<CropRecommendation> crops;
  final String? selectedCropName;
  final AppStrings s;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: crops.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final crop = crops[i];
          final selected = crop.cropName == selectedCropName;
          return ChoiceChip(
            label: Text(s.cropName(crop.cropName)),
            selected: selected,
            onSelected: (_) => onSelect(crop.cropName),
          );
        },
      ),
    );
  }
}

class _FertilizerBody extends StatelessWidget {
  const _FertilizerBody({required this.section, required this.s});
  final FertilizerRecommendationSection section;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Row(
          children: [
            Expanded(child: Text(s.cropName(section.cropName), style: Theme.of(context).textTheme.titleMedium)),
            ConfidenceBadge(score: section.confidence, compact: true),
          ],
        ),
        const SizedBox(height: 12),
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
