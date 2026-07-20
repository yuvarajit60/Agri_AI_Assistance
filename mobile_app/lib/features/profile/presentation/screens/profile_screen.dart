import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/india_states.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _languages = [
  (code: 'en', label: 'English'),
  (code: 'ta', label: 'தமிழ் (Tamil)'),
  (code: 'hi', label: 'हिन्दी (Hindi)'),
];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _openEditProfile(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        initialName: user.name ?? '',
        initialState: user.state,
        initialDistrict: user.district ?? '',
      ),
    );
  }

  Future<void> _openLanguagePicker(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appStringsProvider);
    final current = ref.read(languageProvider);
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(s.chooseLanguage),
        children: [
          RadioGroup<String>(
            groupValue: current,
            onChanged: (v) => Navigator.of(context).pop(v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final lang in _languages)
                  RadioListTile<String>(value: lang.code, title: Text(lang.label)),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected == null || selected == current) return;

    // languageProvider is the source of truth the whole app renders from;
    // preferredLanguage on the profile is kept in sync alongside it purely
    // as account metadata (useful once there's a backend to sync to).
    await ref.read(languageProvider.notifier).setLanguage(selected);
    await ref.read(authControllerProvider.notifier).updateProfile(preferredLanguage: selected);
    if (!context.mounted) return;

    final newStrings = AppStrings.of(selected);
    if (selected == 'hi') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStrings.languageSavedNoTranslationYet),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newStrings.languagePreferenceSaved)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final user = ref.watch(authControllerProvider).user;
    final currentLanguage = ref.watch(languageProvider);
    final languageLabel = _languages.firstWhere(
      (l) => l.code == currentLanguage,
      orElse: () => _languages.first,
    ).label;

    return Scaffold(
      appBar: AppBar(title: Text(s.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  (user?.name?.isNotEmpty ?? false) ? user!.name![0].toUpperCase() : 'F',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? s.farmerFallback, style: Theme.of(context).textTheme.headlineMedium),
                    Text(user?.phoneNumber ?? '', style: Theme.of(context).textTheme.bodyMedium),
                    if (user?.state != null)
                      Text('${user?.district ?? ''} ${user?.state ?? ''}'.trim(),
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _SettingsSection(
            title: s.account,
            items: [
              _SettingsItem(Icons.edit_outlined, s.editProfile, () => _openEditProfile(context, ref)),
              _SettingsItem(Icons.language_rounded, s.language, () => _openLanguagePicker(context, ref),
                  trailingText: languageLabel),
              _SettingsItem(Icons.notifications_none_rounded, s.notificationPreferences, () {}),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: s.support,
            items: [
              _SettingsItem(Icons.help_outline_rounded, s.helpFaqs, () {}),
              _SettingsItem(Icons.description_outlined, s.termsPrivacy, () {}),
              _SettingsItem(Icons.info_outline_rounded, s.about, () {}),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text(s.signOut),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.initialName, required this.initialState, required this.initialDistrict});
  final String initialName;
  final String? initialState;
  final String initialDistrict;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initialName);
  late final _districtController = TextEditingController(text: widget.initialDistrict);
  String? _selectedState;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedState = widget.initialState;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await ref.read(authControllerProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          stateName: _selectedState,
          district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
        );
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
              Text(s.editProfile, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: s.fullName),
                validator: (v) => (v == null || v.trim().isEmpty) ? s.enterYourName : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedState,
                isExpanded: true,
                decoration: InputDecoration(labelText: s.state),
                items: kIndianStates.map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                onChanged: (v) => setState(() => _selectedState = v),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _districtController,
                decoration: InputDecoration(labelText: s.districtOptional),
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

class _SettingsItem {
  const _SettingsItem(this.icon, this.label, this.onTap, {this.trailingText});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailingText;
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});
  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                ListTile(
                  leading: Icon(items[i].icon, color: AppColors.textSecondary),
                  title: Text(items[i].label),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (items[i].trailingText != null) ...[
                        Text(items[i].trailingText!, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 6),
                      ],
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    ],
                  ),
                  onTap: items[i].onTap,
                ),
                if (i != items.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
