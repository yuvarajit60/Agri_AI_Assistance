import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/farm.dart';
import '../providers/farm_provider.dart';
import '../widgets/edit_farm_sheet.dart';
import '../widgets/soil_report_sheet.dart';

class FarmsScreen extends ConsumerWidget {
  const FarmsScreen({super.key});

  Future<bool> _confirmDelete(BuildContext context, AppStrings s, Farm farm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.removeThisFarm),
        content: Text(s.removeConfirmDesc(farm.name)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.remove, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _deleteFarm(BuildContext context, WidgetRef ref, AppStrings s, Farm farm) {
    final wasActive = ref.read(activeFarmProvider)?.id == farm.id;
    ref.read(farmsControllerProvider.notifier).removeFarm(farm.id);
    if (wasActive) {
      ref.read(selectedFarmIdProvider.notifier).state = null;
      ref.read(dashboardControllerProvider.notifier).reset();
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.removedFarm(farm.name))));
  }

  Future<void> _openActions(BuildContext context, WidgetRef ref, AppStrings s, Farm farm) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: Text(s.viewDashboard),
              onTap: () => Navigator.of(context).pop('dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(s.editFarmNameArea),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: Text(farm.soilReport != null ? s.viewEditSoilReportMenu : s.addSoilReportMenu),
              onTap: () => Navigator.of(context).pop('soil'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              title: Text(s.deleteFarm, style: const TextStyle(color: AppColors.danger)),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'dashboard':
        ref.read(selectedFarmIdProvider.notifier).state = farm.id;
        ref.read(dashboardControllerProvider.notifier).loadForFarm(farm);
        context.go('/dashboard');
      case 'edit':
        await showEditFarmSheet(context: context, farm: farm);
      case 'soil':
        await showSoilReportSheet(context: context, farm: farm);
      case 'delete':
        if (await _confirmDelete(context, s, farm) && context.mounted) {
          _deleteFarm(context, ref, s, farm);
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final farmsAsync = ref.watch(farmsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.myFarms)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/farms/add'),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addFarm),
      ),
      body: farmsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.couldNotLoadFarms(e.toString()))),
        data: (farms) {
          if (farms.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  s.noFarmsListDesc,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              for (final farm in farms.reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: ValueKey(farm.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(context, s, farm),
                    onDismissed: (_) => _deleteFarm(context, ref, s, farm),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    ),
                    child: _FarmCard(
                      farm: farm,
                      s: s,
                      onTap: () {
                        ref.read(selectedFarmIdProvider.notifier).state = farm.id;
                        ref.read(dashboardControllerProvider.notifier).loadForFarm(farm);
                        context.go('/dashboard');
                      },
                      onMore: () => _openActions(context, ref, s, farm),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  const _FarmCard({required this.farm, required this.onTap, required this.onMore, required this.s});
  final Farm farm;
  final VoidCallback onTap;
  final VoidCallback onMore;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.grass_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(farm.name, style: Theme.of(context).textTheme.titleMedium)),
                        if (farm.soilReport != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(s.labTested,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.success)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.acresValue(farm.areaAcres.toStringAsFixed(1))} · ${farm.latitude.toStringAsFixed(3)}, ${farm.longitude.toStringAsFixed(3)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onMore,
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
