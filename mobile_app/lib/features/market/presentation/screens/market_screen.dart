import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confidence_badge.dart';
import '../../../dashboard/data/dashboard_data.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../farms/presentation/providers/farm_provider.dart';
import '../../data/market_models.dart';
import '../../data/market_repository.dart';

/// A bottom-nav tab (see app_router.dart). The dashboard's own /dashboard
/// call already resolves a forecast for the top recommended crop for
/// free, so that's shown by default with no extra request; picking a
/// different recommended crop fetches its forecast on demand via
/// MarketRepository instead of the gateway forecasting every recommended
/// crop on every dashboard load (market_price is the heaviest service in
/// the platform — see docs/architecture/ROADMAP.md).
class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  bool _triedInitialLoad = false;
  final _repository = MarketRepository();

  String? _selectedCropName;
  AsyncValue<MarketForecastSection>? _selectedForecast;

  Future<void> _selectCrop(String cropName, double lat, double lon) async {
    setState(() {
      _selectedCropName = cropName;
      _selectedForecast = const AsyncValue.loading();
    });
    try {
      final forecast = await _repository.fetchForecast(
        commodity: cropName,
        latitude: lat,
        longitude: lon,
        language: ref.read(languageProvider),
      );
      if (!mounted) return;
      setState(() => _selectedForecast = AsyncValue.data(forecast));
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _selectedForecast = AsyncValue.error(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final activeFarm = ref.watch(activeFarmProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);

    if (!_triedInitialLoad && activeFarm != null && dashboardState.value == null && !dashboardState.isLoading) {
      _triedInitialLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dashboardControllerProvider.notifier).loadForFarm(activeFarm);
      });
    }

    Widget body;
    if (activeFarm == null) {
      body = _CenteredMessage(text: s.noFarmsYet);
    } else if (dashboardState.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (dashboardState.hasError) {
      body = _CenteredMessage(
        text: dashboardState.error.toString(),
        actionLabel: s.retry,
        onAction: () => ref.read(dashboardControllerProvider.notifier).loadForFarm(activeFarm),
      );
    } else if (dashboardState.value?.marketForecast == null) {
      body = _CenteredMessage(text: s.marketForecastUnavailable);
    } else {
      final crops = dashboardState.value!.cropRecommendation;
      final topCropName = crops?.top.cropName;
      final isViewingTop = _selectedCropName == null || _selectedCropName == topCropName;
      final currentForecast = isViewingTop ? AsyncValue.data(dashboardState.value!.marketForecast!) : _selectedForecast;

      body = Column(
        children: [
          if (crops != null && (crops.alternatives.isNotEmpty))
            _CropSelector(
              crops: [crops.top, ...crops.alternatives],
              selectedCropName: _selectedCropName ?? topCropName,
              s: s,
              onSelect: (cropName) => _selectCrop(cropName, activeFarm.latitude, activeFarm.longitude),
            ),
          Expanded(
            child: switch (currentForecast) {
              AsyncData(:final value) => _MarketForecastBody(section: value, s: s),
              AsyncError(:final error) => _CenteredMessage(
                  text: error.toString(),
                  actionLabel: s.retry,
                  onAction: () => _selectCrop(_selectedCropName!, activeFarm.latitude, activeFarm.longitude),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      );
    }

    return Scaffold(appBar: AppBar(title: Text(s.marketIntelligenceTitle)), body: SafeArea(child: body));
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

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text, this.actionLabel, this.onAction});
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarketForecastBody extends StatelessWidget {
  const _MarketForecastBody({required this.section, required this.s});
  final MarketForecastSection section;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(s.cropName(section.commodity), style: Theme.of(context).textTheme.titleLarge)),
                    ConfidenceBadge(score: section.confidence),
                  ],
                ),
                const SizedBox(height: 12),
                Text(s.predictedPriceRange, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '₹${section.nearTermLowInr.round()} – ₹${section.nearTermHighInr.round()} / quintal',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(s.bestSellingMonth(section.bestSellingMonth), style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(s.nearbyMandis, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final mandi in section.nearbyMandis)
          _MandiTile(name: mandi.name, distanceKm: mandi.distanceKm, priceInr: mandi.latestPriceInr),
      ],
    );
  }
}

class _MandiTile extends StatelessWidget {
  const _MandiTile({required this.name, required this.distanceKm, required this.priceInr});
  final String name;
  final double distanceKm;
  final double priceInr;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.storefront_rounded, color: AppColors.primary),
        ),
        title: Text(name),
        subtitle: Text('${distanceKm.toStringAsFixed(1)} km'),
        trailing: Text('₹${priceInr.round()} / quintal', style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}
