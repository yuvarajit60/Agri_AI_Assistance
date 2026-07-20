import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confidence_badge.dart';
import '../../../dashboard/data/mock_dashboard_data.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.weatherTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(MockDashboardData.weatherTodayTemp, style: Theme.of(context).textTheme.displayLarge),
                      const Icon(Icons.wb_cloudy_rounded, size: 48, color: AppColors.accent),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(MockDashboardData.weatherTodayCondition, style: Theme.of(context).textTheme.bodyMedium),
                      const ConfidenceBadge(score: MockDashboardData.weatherConfidence, compact: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.sevenDayForecast, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final d in MockDashboardData.weeklyForecast)
                    ListTile(
                      leading: Icon(
                        d.rain > 45 ? Icons.water_drop_rounded : Icons.wb_sunny_rounded,
                        color: d.rain > 45 ? AppColors.info : AppColors.accent,
                      ),
                      title: Text(d.day == 'Today' ? s.today : d.day),
                      subtitle: Text(s.rainChance(d.rain)),
                      trailing: Text('${d.temp}°C', style: Theme.of(context).textTheme.titleMedium),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.forecastConfidenceNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
