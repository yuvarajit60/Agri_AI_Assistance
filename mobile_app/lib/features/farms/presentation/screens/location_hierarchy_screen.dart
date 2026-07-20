import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/india_states.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/geocoding_repository.dart';
import '../widgets/confirm_farm_sheet.dart';

/// Merges the Country / Region / State / District / City-Village
/// land-identification methods (docs/architecture/MODULES.md §1) into one
/// cascading flow instead of four separate near-identical stubs: pick a
/// country, then a state, then type the district and village, then
/// resolve that to a real point via geocoding.
class LocationHierarchyScreen extends ConsumerStatefulWidget {
  const LocationHierarchyScreen({super.key});

  @override
  ConsumerState<LocationHierarchyScreen> createState() => _LocationHierarchyScreenState();
}

class _LocationHierarchyScreenState extends ConsumerState<LocationHierarchyScreen> {
  final _geocoder = GeocodingRepository();

  final String _country = 'India';
  String? _state;
  final _districtController = TextEditingController();
  final _villageController = TextEditingController();

  bool _searching = false;
  String? _error;
  GeocodeResult? _resolved;

  @override
  void dispose() {
    _districtController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  bool get _canSearch => _state != null && _districtController.text.trim().isNotEmpty;

  Future<void> _search() async {
    if (!_canSearch) return;
    setState(() {
      _searching = true;
      _error = null;
      _resolved = null;
    });

    final village = _villageController.text.trim();
    final district = _districtController.text.trim();
    final query = [if (village.isNotEmpty) village, district, _state, _country].join(', ');
    final s = ref.read(appStringsProvider);

    try {
      final result = await _geocoder.search(query);
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _searching = false;
          _error = s.couldNotFindLocation(query);
        });
        return;
      }
      setState(() {
        _searching = false;
        _resolved = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = s.locationLookupFailed(e.toString());
      });
    }
  }

  void _confirm() {
    final resolved = _resolved;
    if (resolved == null) return;
    final village = _villageController.text.trim();
    showConfirmFarmSheet(
      context: context,
      latitude: resolved.latitude,
      longitude: resolved.longitude,
      resolutionMethod: 'location_search',
      suggestedName: village.isNotEmpty ? village : (_districtController.text.trim()),
      locationLabel: resolved.displayName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.findYourLand)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(s.country, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _country,
            items: [DropdownMenuItem(value: 'India', child: Text(s.india))],
            onChanged: (v) {}, // single option for now — extensible per ARCHITECTURE.md §8
          ),
          const SizedBox(height: 18),
          Text(s.state, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _state,
            isExpanded: true,
            hint: Text(s.selectYourState),
            items: kIndianStates.map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
            onChanged: (v) => setState(() {
              _state = v;
              _resolved = null;
            }),
          ),
          const SizedBox(height: 18),
          AnimatedOpacity(
            opacity: _state != null ? 1 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: _state == null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.district, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _districtController,
                    decoration: InputDecoration(hintText: s.districtHint),
                    onChanged: (_) => setState(() => _resolved = null),
                  ),
                  const SizedBox(height: 18),
                  Text(s.cityVillageOptional, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _villageController,
                    decoration: InputDecoration(hintText: s.villageHint),
                    onChanged: (_) => setState(() => _resolved = null),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: s.findThisLocation,
            onPressed: _canSearch ? _search : () {},
            isLoading: _searching,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          if (_resolved != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(s.locationFound, style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_resolved!.displayName, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: s.continueLabel, onPressed: _confirm),
          ],
        ],
      ),
    );
  }
}
