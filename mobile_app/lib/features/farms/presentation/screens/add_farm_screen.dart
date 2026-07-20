import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/confirm_farm_sheet.dart';

class _LandIdMethod {
  const _LandIdMethod(this.icon, this.title, this.subtitle, {this.id, this.comingSoon = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final String? id;
  final bool comingSoon;
}

/// The land-identification methods from the product brief
/// (docs/architecture/MODULES.md §1). Country/Region/State/District/
/// City-Village are one merged cascading flow (id: 'location'), not five
/// separate stubs — a farmer picks a country, then state, then types
/// district/village, and it resolves to one point via geocoding.
List<_LandIdMethod> _methods(AppStrings s) => [
      _LandIdMethod(Icons.my_location_rounded, s.gpsCoordinates, s.useCurrentLocation, id: 'gps'),
      _LandIdMethod(Icons.map_rounded, s.googleMapsLocation, s.searchAndPin),
      _LandIdMethod(Icons.draw_rounded, s.drawFarmBoundary, s.traceField),
      _LandIdMethod(Icons.confirmation_number_outlined, s.surveyNumber, s.enterSurveyNumber),
      _LandIdMethod(Icons.map_outlined, s.locationHierarchyMethodTitle, s.searchByAdminArea, id: 'location'),
      _LandIdMethod(Icons.description_outlined, s.uploadLandDocument, s.autoDetectBoundary, comingSoon: true),
    ];

class AddFarmScreen extends ConsumerWidget {
  const AddFarmScreen({super.key});

  Future<void> _handleTap(BuildContext context, WidgetRef ref, AppStrings s, _LandIdMethod method) async {
    switch (method.id) {
      case 'gps':
        await _startGpsFlow(context, ref, s);
        return;
      case 'location':
        context.push('/farms/add/location');
        return;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.willConnectToService(method.title))),
        );
    }
  }

  Future<void> _startGpsFlow(BuildContext context, WidgetRef ref, AppStrings s) async {
    final messenger = ScaffoldMessenger.of(context);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      messenger.showSnackBar(SnackBar(content: Text(s.turnOnLocationServices)));
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      messenger.showSnackBar(SnackBar(content: Text(s.locationPermissionNeeded)));
      return;
    }

    if (!context.mounted) return;
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.couldNotGetLocation(e.toString()))));
      return;
    }

    if (!context.mounted) return;
    await showConfirmFarmSheet(
      context: context,
      latitude: position.latitude,
      longitude: position.longitude,
      resolutionMethod: 'gps_coordinates',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.addAFarmTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(s.howToIdentify, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(s.chooseEasiest, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          for (final m in _methods(s)) _MethodTile(method: m, s: s, onTap: () => _handleTap(context, ref, s, m)),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.method, required this.onTap, required this.s});
  final _LandIdMethod method;
  final VoidCallback onTap;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: method.comingSoon ? 0.5 : 1,
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: method.comingSoon ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(method.icon, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(method.title, style: Theme.of(context).textTheme.titleSmall),
                        Text(method.subtitle, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (method.comingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(s.soon, style: Theme.of(context).textTheme.labelSmall),
                    )
                  else
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
