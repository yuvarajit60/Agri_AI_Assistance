import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confidence_badge.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../farms/data/farm.dart';
import '../../../farms/presentation/providers/farm_provider.dart';
import '../../../farms/presentation/widgets/soil_report_sheet.dart';
import '../../data/dashboard_data.dart';
import '../../data/mock_dashboard_data.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_section_card.dart';
import '../widgets/land_health_gauge.dart';
import 'crop_comparison_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _triedInitialLoad = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final user = ref.watch(authControllerProvider).user;
    final firstName = (user?.name ?? s.farmerFallback).split(' ').first;
    final farmsAsync = ref.watch(farmsControllerProvider);
    final activeFarm = ref.watch(activeFarmProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);

    if (!_triedInitialLoad && activeFarm != null && dashboardState.value == null && !dashboardState.isLoading) {
      _triedInitialLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dashboardControllerProvider.notifier).loadForFarm(activeFarm);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(firstName: firstName, s: s)),
            if (farmsAsync.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (activeFarm == null)
              SliverFillRemaining(hasScrollBody: false, child: _NoFarmEmptyState(s: s))
            else ...[
              SliverToBoxAdapter(child: _FarmBanner(farm: activeFarm, s: s)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                sliver: SliverList.list(
                  children: [
                    if (dashboardState.isLoading) _LoadingSection(s: s),
                    if (dashboardState.hasError)
                      _ErrorSection(
                        s: s,
                        message: dashboardState.error.toString(),
                        onRetry: () => ref.read(dashboardControllerProvider.notifier).loadForFarm(activeFarm),
                      ),
                    if (dashboardState.value != null) ...[
                      if (dashboardState.value!.warnings.isNotEmpty) _WarningsBanner(warnings: dashboardState.value!.warnings),
                      if (dashboardState.value!.landHealth != null) ...[
                        const SizedBox(height: 4),
                        _LandHealthCard(section: dashboardState.value!.landHealth!, farm: activeFarm, s: s),
                        const SizedBox(height: 14),
                      ],
                      if (dashboardState.value!.weather != null) ...[
                        _WeatherCard(section: dashboardState.value!.weather!, s: s),
                        const SizedBox(height: 14),
                      ],
                      if (dashboardState.value!.waterResources != null) ...[
                        _WaterResourceCard(section: dashboardState.value!.waterResources!, s: s),
                        const SizedBox(height: 14),
                      ],
                      if (dashboardState.value!.cropRecommendation != null) ...[
                        _CropRecommendationsLive(section: dashboardState.value!.cropRecommendation!, s: s),
                        const SizedBox(height: 14),
                      ],
                    ],
                    DashboardSectionCard(
                      title: s.diagnoseTitle,
                      icon: Icons.medical_services_outlined,
                      onTap: () => context.push('/diagnose'),
                      child: Text(s.diagnoseCardSubtitle, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    const SizedBox(height: 14),
                    _DemoDataNotice(s: s),
                    const SizedBox(height: 14),
                    DashboardSectionCard(
                      title: s.marketPredictionTitle(MockDashboardData.marketCommodity),
                      icon: Icons.storefront_rounded,
                      trailing: const ConfidenceBadge(score: MockDashboardData.marketConfidence, compact: true),
                      onTap: () => context.go('/market'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(MockDashboardData.marketPriceRange, style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 4),
                          Text(s.bestSellingMonth(MockDashboardData.marketBestMonth),
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.firstName, required this.s});
  final String firstName;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.namaste(firstName), style: Theme.of(context).textTheme.headlineMedium),
                Text(s.farmLooksToday, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
                style: IconButton.styleFrom(backgroundColor: AppColors.surfaceAlt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoFarmEmptyState extends StatelessWidget {
  const _NoFarmEmptyState({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.grass_rounded, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(s.noFarmsYet, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              s.addFirstFarmDesc,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: s.addAFarm, onPressed: () => context.push('/farms/add')),
          ],
        ),
      ),
    );
  }
}

class _FarmBanner extends StatelessWidget {
  const _FarmBanner({required this.farm, required this.s});
  final Farm farm;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(farm.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                  Text(
                    '${s.acresValue(farm.areaAcres.toStringAsFixed(1))} · ${farm.latitude.toStringAsFixed(4)}, ${farm.longitude.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.push('/farms/add'),
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(s.fetchingLiveData),
          ],
        ),
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.s, required this.message, required this.onRetry});
  final AppStrings s;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger),
              const SizedBox(width: 10),
              Expanded(child: Text(s.couldNotLoadFarmData, style: Theme.of(context).textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: 6),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onRetry, child: Text(s.retry)),
        ],
      ),
    );
  }
}

class _WarningsBanner extends StatelessWidget {
  const _WarningsBanner({required this.warnings});
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final w in warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(w, style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _DemoDataNotice extends StatelessWidget {
  const _DemoDataNotice({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              s.demoDataNotice,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _LandHealthCard extends StatelessWidget {
  const _LandHealthCard({required this.section, required this.farm, required this.s});
  final LandHealthSection section;
  final Farm? farm;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final sub = section.subIndices;
    return DashboardSectionCard(
      title: s.landHealthScore,
      icon: Icons.eco_rounded,
      trailing: ConfidenceBadge(score: section.confidence, compact: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LandHealthGauge(score: section.score),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FactorRow(label: s.organicCarbon, value: sub['organic_carbon_index'] ?? 0),
                    _FactorRow(label: s.npkBalance, value: sub['npk_balance_index'] ?? 0),
                    _FactorRow(label: s.phSuitability, value: sub['ph_suitability_index'] ?? 0),
                    _FactorRow(label: s.erosionRisk, value: sub['erosion_risk'] ?? 0, inverse: true),
                  ],
                ),
              ),
            ],
          ),
          if (farm != null) ...[
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showSoilReportSheet(context: context, farm: farm!),
                icon: const Icon(Icons.science_outlined, size: 18),
                label: Text(farm!.soilReport != null ? s.viewEditSoilReport : s.addYourSoilTestReport),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.section, required this.s});
  final WeatherSection section;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: s.weather7Day,
      icon: Icons.wb_sunny_outlined,
      trailing: ConfidenceBadge(score: section.confidence, compact: true),
      onTap: () => context.push('/weather'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${section.avgTempC.toStringAsFixed(0)}°C', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(width: 12),
              // Expanded so longer translated text (e.g. Tamil) wraps within
              // the remaining row width instead of overflowing past the card edge.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.avgHumidity(section.humidityPercent), style: Theme.of(context).textTheme.bodyMedium),
                    Text(s.rainfallThisWeek(section.totalRainfallMm.toStringAsFixed(0)),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (section.daily.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              // Taller than a plain 3-line English layout needs, because
              // Tamil glyphs (vowel signs above/below the baseline) render
              // with more vertical extent per line than Latin text.
              height: 76,
              child: Row(
                children: [
                  for (final d in section.daily)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            d.dayOffset == 0 ? s.today : '+${d.dayOffset}d',
                            style: Theme.of(context).textTheme.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            d.rainProbabilityPercent > 45 ? Icons.water_drop_rounded : Icons.wb_sunny_rounded,
                            size: 16,
                            color: d.rainProbabilityPercent > 45 ? AppColors.info : AppColors.accent,
                          ),
                          const SizedBox(height: 4),
                          Text('${d.avgTempC.toStringAsFixed(0)}°', style: Theme.of(context).textTheme.labelMedium),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WaterResourceCard extends StatelessWidget {
  const _WaterResourceCard({required this.section, required this.s});
  final WaterResourceSection section;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final nearest = section.features.isEmpty
        ? null
        : section.features.reduce((a, b) => a.distanceKm < b.distanceKm ? a : b);
    return DashboardSectionCard(
      title: s.waterResourcesTitle,
      icon: Icons.water_drop_outlined,
      trailing: ConfidenceBadge(score: section.confidence, compact: true),
      onTap: () => context.push('/water', extra: section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nearest != null)
            Text(
              '${s.waterFeatureType(nearest.type)} · ${s.distanceAway(nearest.distanceKm.toStringAsFixed(1))}',
              style: Theme.of(context).textTheme.headlineMedium,
            )
          else
            Text(s.noWaterFeaturesFound, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            '${s.groundwaterStatus}: ${s.groundwaterCategory(section.groundwaterCategory)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '${s.irrigationFeasibilitySection}: ${s.irrigationMethod(section.irrigationMethod)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CropRecommendationsLive extends StatelessWidget {
  const _CropRecommendationsLive({required this.section, required this.s});
  final CropRecommendationSection section;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final all = [section.top, ...section.alternatives];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(s.cropRecommendations, style: Theme.of(context).textTheme.titleLarge)),
            ConfidenceBadge(score: section.confidence, compact: true),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CropComparisonScreen(section: section)),
              ),
              child: Text(s.compareAll),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          // Taller than a plain 2-line English crop name needs, because
          // longer translated names (e.g. Tamil's "பருப்பு வகைகள் (துவரை)")
          // can wrap to 3 lines.
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _LiveCropCard(crop: all[i], s: s),
          ),
        ),
      ],
    );
  }
}

class _LiveCropCard extends StatelessWidget {
  const _LiveCropCard({required this.crop, required this.s});
  final CropRecommendation crop;
  final AppStrings s;

  Color _riskColor() {
    switch (crop.riskLevel) {
      case 'low':
        return AppColors.confidenceHigh;
      case 'high':
        return AppColors.confidenceLow;
      default:
        return AppColors.confidenceMedium;
    }
  }

  String _riskLabel() {
    switch (crop.riskLevel) {
      case 'low':
        return s.riskLabel(s.lowRisk);
      case 'high':
        return s.riskLabel(s.highRisk);
      default:
        return s.riskLabel(s.mediumRisk);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.cropTerm(crop.term),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary)),
              ),
              Text('${crop.suitabilityPercent.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(s.cropName(crop.cropName), style: Theme.of(context).textTheme.titleMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text('₹${crop.expectedProfitInr.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: _riskColor(), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(_riskLabel(), style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.label, required this.value, this.inverse = false});
  final String label;
  final double value; // 0-1
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final good = inverse ? 1 - value : value;
    final color = good >= 0.7 ? AppColors.confidenceHigh : (good >= 0.45 ? AppColors.confidenceMedium : AppColors.confidenceLow);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value.clamp(0, 1),
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
