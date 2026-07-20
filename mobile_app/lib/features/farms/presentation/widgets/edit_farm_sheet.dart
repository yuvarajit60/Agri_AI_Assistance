import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/farm.dart';
import '../providers/farm_provider.dart';

Future<void> showEditFarmSheet({required BuildContext context, required Farm farm}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditFarmSheet(farm: farm),
  );
}

class _EditFarmSheet extends ConsumerStatefulWidget {
  const _EditFarmSheet({required this.farm});
  final Farm farm;

  @override
  ConsumerState<_EditFarmSheet> createState() => _EditFarmSheetState();
}

class _EditFarmSheetState extends ConsumerState<_EditFarmSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.farm.name);
  late final _areaController = TextEditingController(text: widget.farm.areaAcres.toString());
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final newArea = double.parse(_areaController.text.trim());
    final areaChanged = newArea != widget.farm.areaAcres;
    final updated = widget.farm.copyWith(name: _nameController.text.trim(), areaAcres: newArea);

    await ref.read(farmsControllerProvider.notifier).updateFarm(updated);

    // Area feeds directly into the crop engine's yield/investment math, so a
    // change here makes the currently-loaded dashboard report stale.
    final isActive = ref.read(activeFarmProvider)?.id == updated.id;
    if (isActive && areaChanged) {
      await ref.read(dashboardControllerProvider.notifier).loadForFarm(updated);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
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
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.editFarm, style: Theme.of(context).textTheme.headlineMedium),
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
                validator: (v) {
                  final value = double.tryParse(v?.trim() ?? '');
                  if (value == null || value <= 0) return s.enterValidArea;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: s.saveChanges, onPressed: _save, isLoading: _saving),
            ],
          ),
        ),
      ),
    );
  }
}
