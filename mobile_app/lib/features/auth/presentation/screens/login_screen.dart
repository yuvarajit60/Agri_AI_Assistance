import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final phone = '+91${_phoneController.text.trim()}';
    final ok = await ref.read(authControllerProvider.notifier).sendOtp(phone);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      context.push('/otp');
    } else {
      final s = ref.read(appStringsProvider);
      final error = ref.read(authControllerProvider).errorMessage ?? s.somethingWentWrong;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset('assets/icons/app_logo.png', fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(s.welcomeBack, style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 8),
                      Text(s.loginSubtitle, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 36),
                      Text(s.mobileNumber, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text('+91', style: Theme.of(context).textTheme.titleMedium),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              autofillHints: const [AutofillHints.telephoneNumberNational],
                              decoration: InputDecoration(hintText: s.phoneHint, counterText: ''),
                              validator: (value) {
                                final digits = (value ?? '').trim();
                                if (digits.length != 10) return s.phoneValidationError;
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(label: s.sendOtp, onPressed: _submit, isLoading: _submitting),
                      const SizedBox(height: 32),
                      Text(
                        s.termsText,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
