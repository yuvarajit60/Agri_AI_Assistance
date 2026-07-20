import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/farm.dart';
import '../../data/soil_report.dart';
import '../providers/farm_provider.dart';

/// Shared "name it, size it, optionally attach a soil report" step used by
/// every land-identification method once it has resolved a lat/lon —
/// see docs/architecture/MODULES.md §1. Keeping this in one place means
/// the soil-report input and duplicate-farm check aren't re-implemented
/// per method.
Future<void> showConfirmFarmSheet({
  required BuildContext context,
  required double latitude,
  required double longitude,
  required String resolutionMethod,
  String? suggestedName,
  String? locationLabel,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ConfirmFarmSheet(
      latitude: latitude,
      longitude: longitude,
      resolutionMethod: resolutionMethod,
      suggestedName: suggestedName,
      locationLabel: locationLabel,
    ),
  );
}

class _ConfirmFarmSheet extends ConsumerStatefulWidget {
  const _ConfirmFarmSheet({
    required this.latitude,
    required this.longitude,
    required this.resolutionMethod,
    this.suggestedName,
    this.locationLabel,
  });

  final double latitude;
  final double longitude;
  final String resolutionMethod;
  final String? suggestedName;
  final String? locationLabel;

  @override
  ConsumerState<_ConfirmFarmSheet> createState() => _ConfirmFarmSheetState();
}

class _ConfirmFarmSheetState extends ConsumerState<_ConfirmFarmSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _areaController = TextEditingController(text: '1');

  bool _hasSoilReport = false;
  final _phController = TextEditingController();
  final _ecController = TextEditingController();
  final _ocController = TextEditingController();
  final _nController = TextEditingController();
  final _pController = TextEditingController();
  final _kController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.suggestedName ?? 'My Farm');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _phController.dispose();
    _ecController.dispose();
    _ocController.dispose();
    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    super.dispose();
  }

  String? _requiredNumber(String? v, {double min = 0, double max = double.infinity, required String label}) {
    final value = double.tryParse(v?.trim() ?? '');
    if (value == null || value < min || value > max) return label;
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final s = ref.read(appStringsProvider);

    final duplicate = ref.read(farmsControllerProvider.notifier).findNearbyFarm(widget.latitude, widget.longitude);
    if (duplicate != null) {
      setState(() => _error = s.alreadyHaveFarmHere(duplicate.name));
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final soilReport = _hasSoilReport
        ? SoilLabReport(
            ph: double.parse(_phController.text.trim()),
            ecDsPerM: double.parse(_ecController.text.trim()),
            organicCarbonPercent: double.parse(_ocController.text.trim()),
            nitrogenKgPerHa: double.parse(_nController.text.trim()),
            phosphorusKgPerHa: double.parse(_pController.text.trim()),
            potassiumKgPerHa: double.parse(_kController.text.trim()),
          )
        : null;

    final farm = Farm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      latitude: widget.latitude,
      longitude: widget.longitude,
      areaAcres: double.parse(_areaController.text.trim()),
      resolutionMethod: widget.resolutionMethod,
      createdAt: DateTime.now(),
      soilReport: soilReport,
    );

    await ref.read(farmsControllerProvider.notifier).addFarm(farm);
    ref.read(selectedFarmIdProvider.notifier).state = farm.id;
    await ref.read(dashboardControllerProvider.notifier).loadForFarm(farm);

    if (!mounted) return;

    final dashboardState = ref.read(dashboardControllerProvider);
    if (dashboardState.hasError) {
      setState(() {
        _submitting = false;
        _error = dashboardState.error.toString();
      });
      return;
    }

    if (context.mounted) {
      Navigator.of(context).pop();
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.confirmYourFarm, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  widget.locationLabel ??
                      s.locationCoords(widget.latitude.toStringAsFixed(5), widget.longitude.toStringAsFixed(5)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: s.farmName),
                  validator: (v) => (v == null || v.trim().isEmpty) ? s.enterFarmName : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _areaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: s.approximateAreaAcres),
                  validator: (v) => _requiredNumber(v, min: 0.01, label: s.enterValidArea),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.iHaveSoilReport),
                  subtitle: Text(s.soilReportSwitchSubtitle),
                  value: _hasSoilReport,
                  onChanged: (v) => setState(() => _hasSoilReport = v),
                ),
                if (_hasSoilReport) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: s.ph),
                          validator: (v) => _requiredNumber(v, min: 0, max: 14, label: '${s.ph} (0-14)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _ecController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: s.ecDsPerM),
                          validator: (v) => _requiredNumber(v, min: 0, label: s.ecDsPerM),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _ocController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: s.organicCarbonPercent),
                    validator: (v) => _requiredNumber(v, min: 0, max: 20, label: s.organicCarbonPercent),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: s.nitrogenKgHa),
                          validator: (v) => _requiredNumber(v, min: 0, label: s.nitrogenKgHa),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _pController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: s.phosphorusKgHa),
                          validator: (v) => _requiredNumber(v, min: 0, label: s.phosphorusKgHa),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _kController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: s.potassiumKgHa),
                          validator: (v) => _requiredNumber(v, min: 0, label: s.potassiumKgHa),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 20),
                PrimaryButton(label: s.fetchFarmInsights, onPressed: _submit, isLoading: _submitting),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
