import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confidence_badge.dart';
import '../../../dashboard/data/mock_dashboard_data.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.marketIntelligenceTitle)),
      body: ListView(
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
                      Expanded(
                        child: Text(MockDashboardData.marketCommodity, style: Theme.of(context).textTheme.titleLarge),
                      ),
                      const ConfidenceBadge(score: MockDashboardData.marketConfidence),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(s.predictedPriceRange, style: Theme.of(context).textTheme.bodySmall),
                  Text(MockDashboardData.marketPriceRange, style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 8),
                  Text(s.bestSellingMonth(MockDashboardData.marketBestMonth),
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.nearbyMandis, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _MandiTile(name: 'Nashik APMC', distance: '6.2 km', price: '₹7,150 / quintal'),
          _MandiTile(name: 'Lasalgaon Market', distance: '14.8 km', price: '₹7,320 / quintal'),
          _MandiTile(name: 'Pimpalgaon Mandi', distance: '21.4 km', price: '₹6,980 / quintal'),
        ],
      ),
    );
  }
}

class _MandiTile extends StatelessWidget {
  const _MandiTile({required this.name, required this.distance, required this.price});
  final String name;
  final String distance;
  final String price;

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
        subtitle: Text(distance),
        trailing: Text(price, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}
