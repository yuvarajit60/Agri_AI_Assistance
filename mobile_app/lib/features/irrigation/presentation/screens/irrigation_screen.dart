import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confidence_badge.dart';
import '../../../dashboard/data/dashboard_data.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../farms/presentation/providers/farm_provider.dart';
import '../../data/irrigation_repository.dart';

/// Reached from the dashboard's Irrigation card. The dashboard's own
/// /dashboard call already resolves a plan for the top recommended crop
/// for free, so that's shown by default with no extra request; picking a
/// different recommended crop fetches its plan on demand — same pattern
/// as MarketScreen, since irrigation need is genuinely crop-specific
/// (a fix for "only shows one crop" reported after the same limitation
/// was already fixed on the Market screen).
class IrrigationScreen extends ConsumerStatefulWidget {
  const IrrigationScreen({super.key});

  @override
  ConsumerState<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends ConsumerState<IrrigationScreen> {
  final _repository = IrrigationRepository();

  String? _selectedCropName;
  AsyncValue<IrrigationPlanSection>? _selectedPlan;

  Future<void> _selectCrop(
    CropRecommendation crop,
    double farmAreaAcres,
    String? irrigationMethod,
    double? soilMoisturePercent,
  ) async {
    setState(() {
      _selectedCropName = crop.cropName;
      _selectedPlan = const AsyncValue.loading();
    });
    try {
      final plan = await _repository.fetchPlan(
        cropName: crop.cropName,
        cropWaterRequirementMm: crop.waterRequirementMm.toDouble(),
        cropDurationDays: crop.timeToHarvestDays,
        farmAreaAcres: farmAreaAcres,
        irrigationMethod: irrigationMethod,
        soilMoisturePercent: soilMoisturePercent,
        language: ref.read(languageProvider),
      );
      if (!mounted) return;
      setState(() => _selectedPlan = AsyncValue.data(plan));
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _selectedPlan = AsyncValue.error(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final activeFarm = ref.watch(activeFarmProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
    final data = dashboardState.value;

    Widget body;
    if (activeFarm == null || data == null || data.irrigationPlan == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(s.irrigationPlanUnavailable, textAlign: TextAlign.center),
        ),
      );
    } else {
      final crops = data.cropRecommendation;
      final topCropName = crops?.top.cropName;
      final isViewingTop = _selectedCropName == null || _selectedCropName == topCropName;
      final currentPlan = isViewingTop ? AsyncValue.data(data.irrigationPlan!) : _selectedPlan;
      final irrigationMethod = data.waterResources?.irrigationMethod;

      body = Column(
        children: [
          if (crops != null && crops.alternatives.isNotEmpty)
            _CropSelector(
              crops: [crops.top, ...crops.alternatives],
              selectedCropName: _selectedCropName ?? topCropName,
              s: s,
              onSelect: (crop) =>
                  _selectCrop(crop, activeFarm.areaAcres, irrigationMethod, data.landHealth?.moisturePercent),
            ),
          Expanded(
            child: switch (currentPlan) {
              AsyncData(:final value) => _IrrigationBody(section: value, s: s),
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

    return Scaffold(appBar: AppBar(title: Text(s.irrigationPlanTitle)), body: SafeArea(child: body));
  }
}

class _CropSelector extends StatelessWidget {
  const _CropSelector({required this.crops, required this.selectedCropName, required this.s, required this.onSelect});
  final List<CropRecommendation> crops;
  final String? selectedCropName;
  final AppStrings s;
  final ValueChanged<CropRecommendation> onSelect;

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
            onSelected: (_) => onSelect(crop),
          );
        },
      ),
    );
  }
}

class _IrrigationBody extends StatelessWidget {
  const _IrrigationBody({required this.section, required this.s});
  final IrrigationPlanSection section;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (section.methodAssumed)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Text(s.irrigationMethodAssumedNotice, style: Theme.of(context).textTheme.bodySmall),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(s.cropName(section.cropName), style: Theme.of(context).textTheme.titleMedium)),
                    ConfidenceBadge(score: section.confidence, compact: true),
                  ],
                ),
                const SizedBox(height: 10),
                Text(s.irrigationMethod(section.method), style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 4),
                Text(
                  s.applicationEfficiency(section.applicationEfficiencyPercent),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Divider(height: 24),
                Text(section.methodNotes, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(label: s.totalWaterNeeded, value: _formatLiters(section.totalWaterRequirementLiters)),
            ),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: s.numberOfIrrigations, value: '${section.numberOfIrrigations}')),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.info),
              const SizedBox(width: 10),
              Expanded(child: Text(section.criticalStageAlert, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(s.irrigationScheduleTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final entry in section.schedule)
                  ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text('${entry.irrigationNumber}', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                    ),
                    title: Text(s.dayOffsetLabel(entry.dayOffset)),
                    trailing: Text('${_formatLiters(entry.volumeLiters)} L', style: Theme.of(context).textTheme.titleSmall),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

String _formatLiters(double liters) {
  if (liters >= 1000) return '${(liters / 1000).toStringAsFixed(1)}k';
  return liters.toStringAsFixed(0);
}
