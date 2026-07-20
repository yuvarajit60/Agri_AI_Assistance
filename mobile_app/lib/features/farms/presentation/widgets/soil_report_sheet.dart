import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/farm.dart';
import '../../data/soil_report.dart';
import '../providers/farm_provider.dart';

/// Doubles as "view" and "edit" — opening it always shows whatever is
/// currently on file for the farm (blank fields if none yet), addressing
/// both "I can't see what I submitted" and "I need to change it".
Future<void> showSoilReportSheet({required BuildContext context, required Farm farm}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SoilReportSheet(farm: farm),
  );
}

class _SoilReportSheet extends ConsumerStatefulWidget {
  const _SoilReportSheet({required this.farm});
  final Farm farm;

  @override
  ConsumerState<_SoilReportSheet> createState() => _SoilReportSheetState();
}

class _SoilReportSheetState extends ConsumerState<_SoilReportSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _phController = TextEditingController(text: widget.farm.soilReport?.ph.toString() ?? '');
  late final _ecController = TextEditingController(text: widget.farm.soilReport?.ecDsPerM.toString() ?? '');
  late final _ocController =
      TextEditingController(text: widget.farm.soilReport?.organicCarbonPercent.toString() ?? '');
  late final _nController = TextEditingController(text: widget.farm.soilReport?.nitrogenKgPerHa.toString() ?? '');
  late final _pController = TextEditingController(text: widget.farm.soilReport?.phosphorusKgPerHa.toString() ?? '');
  late final _kController = TextEditingController(text: widget.farm.soilReport?.potassiumKgPerHa.toString() ?? '');
  bool _saving = false;

  @override
  void dispose() {
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

  Future<void> _refreshIfActive(Farm updated) async {
    final isActive = ref.read(activeFarmProvider)?.id == updated.id;
    if (isActive) {
      await ref.read(dashboardControllerProvider.notifier).loadForFarm(updated);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final report = SoilLabReport(
      ph: double.parse(_phController.text.trim()),
      ecDsPerM: double.parse(_ecController.text.trim()),
      organicCarbonPercent: double.parse(_ocController.text.trim()),
      nitrogenKgPerHa: double.parse(_nController.text.trim()),
      phosphorusKgPerHa: double.parse(_pController.text.trim()),
      potassiumKgPerHa: double.parse(_kController.text.trim()),
    );
    final updated = widget.farm.copyWith(soilReport: report);
    await ref.read(farmsControllerProvider.notifier).updateFarm(updated);
    await _refreshIfActive(updated);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    setState(() => _saving = true);
    final updated = widget.farm.copyWith(clearSoilReport: true);
    await ref.read(farmsControllerProvider.notifier).updateFarm(updated);
    await _refreshIfActive(updated);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final hasExisting = widget.farm.soilReport != null;
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
                Text(hasExisting ? s.soilTestReport : s.addSoilTestReportTitle,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  hasExisting ? s.soilReportUsingInsteadOfEstimate : s.soilReportEnterLabValues,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
                PrimaryButton(
                  label: hasExisting ? s.saveChanges : s.addReport,
                  onPressed: _save,
                  isLoading: _saving,
                ),
                if (hasExisting) ...[
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: s.removeReportUseEstimate,
                    onPressed: _remove,
                    outlined: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
