import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confidence_badge.dart';
import '../../../dashboard/data/dashboard_data.dart';

/// Was previously showing MockDashboardData's static sample week regardless
/// of the real date or real forecast — including a "Today" label that
/// stayed fixed no matter what day it actually was. Now takes the same
/// live WeatherSection the dashboard card already fetched, and derives
/// each day's label from the real calendar date, not a hardcoded list.
class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key, required this.section});
  final WeatherSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.weatherTitle),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${section.avgTempC.toStringAsFixed(0)}°C', style: Theme.of(context).textTheme.displayLarge),
                      Icon(
                        section.totalRainfallMm > 20 ? Icons.water_drop_rounded : Icons.wb_cloudy_rounded,
                        size: 48,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.avgHumidity(section.humidityPercent), style: Theme.of(context).textTheme.bodyMedium),
                      ConfidenceBadge(score: section.confidence, compact: true),
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
                  for (final d in section.daily)
                    ListTile(
                      leading: Icon(
                        d.rainProbabilityPercent > 45 ? Icons.water_drop_rounded : Icons.wb_sunny_rounded,
                        color: d.rainProbabilityPercent > 45 ? AppColors.info : AppColors.accent,
                      ),
                      title: Text(
                        d.dayOffset == 0 ? s.today : s.weekdayName(today.add(Duration(days: d.dayOffset)).weekday),
                      ),
                      subtitle: Text(s.rainChance(d.rainProbabilityPercent)),
                      trailing: Text('${d.avgTempC.toStringAsFixed(0)}°C', style: Theme.of(context).textTheme.titleMedium),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.forecastConfidenceNote, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
