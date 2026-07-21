import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confidence_badge.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../farms/presentation/providers/farm_provider.dart';
import '../../data/market_models.dart';

/// A bottom-nav tab (see app_router.dart), so unlike /water this screen
/// can be reached without any `extra` payload -- it reads the same
/// dashboardControllerProvider the dashboard tab already populated
/// (services/gateway/app/main.py's /dashboard now resolves market_forecast
/// as part of the same fan-out), rather than re-fetching independently.
class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  bool _triedInitialLoad = false;

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
      body = _MarketForecastBody(section: dashboardState.value!.marketForecast!, s: s);
    }

    return Scaffold(appBar: AppBar(title: Text(s.marketIntelligenceTitle)), body: SafeArea(child: body));
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
