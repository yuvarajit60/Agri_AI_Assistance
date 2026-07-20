import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/india_states.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _districtController = TextEditingController();
  String? _selectedState;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    await ref.read(authControllerProvider.notifier).completeProfile(
          name: _nameController.text.trim(),
          stateName: _selectedState,
          district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
        );
    if (!mounted) return;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.tellUsAboutYou, style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text(s.profileSetupSubtitle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                AppTextField(
                  label: s.fullName,
                  controller: _nameController,
                  hint: s.fullNameHint,
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? s.enterYourName : null,
                ),
                const SizedBox(height: 20),
                Text(s.state, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedState,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.map_outlined, size: 20),
                    hintText: s.selectYourState,
                  ),
                  items: kIndianStates
                      .map((st) => DropdownMenuItem(value: st, child: Text(st, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedState = v),
                  validator: (v) => v == null ? s.selectYourState : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: s.districtOptional,
                  controller: _districtController,
                  hint: s.districtHint,
                  prefixIcon: Icons.location_city_rounded,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),
                PrimaryButton(label: s.continueToDashboard, onPressed: _submit, isLoading: _submitting),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    s.addFarmAfterThisNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
