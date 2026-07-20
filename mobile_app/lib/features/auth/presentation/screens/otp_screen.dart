import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _codeController = TextEditingController();
  bool _submitting = false;
  bool _resending = false;
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeController.text.trim().length != 6) return;
    setState(() => _submitting = true);
    final ok = await ref.read(authControllerProvider.notifier).verifyOtp(_codeController.text.trim());
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      final status = ref.read(authControllerProvider).status;
      if (status == AuthStatus.authenticatedIncompleteProfile) {
        context.go('/profile-setup');
      } else {
        context.go('/dashboard');
      }
    } else {
      final s = ref.read(appStringsProvider);
      final error = ref.read(authControllerProvider).errorMessage ?? s.invalidCode;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      _codeController.clear();
    }
  }

  Future<void> _resend() async {
    final phone = ref.read(authControllerProvider).pendingPhoneNumber;
    if (phone == null) return;
    setState(() => _resending = true);
    await ref.read(authControllerProvider.notifier).sendOtp(phone);
    if (!mounted) return;
    setState(() => _resending = false);
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.read(appStringsProvider).newCodeSent)));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final phone = ref.watch(authControllerProvider).pendingPhoneNumber ?? '';

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.verifyYourNumber, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              // A bold sub-span for just the phone number would assume the
              // number always appears at the same position in the sentence,
              // which isn't true across languages (e.g. Tamil puts it first) —
              // rendered as one plain string instead.
              Text(s.otpSubtitle(phone), style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _codeController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                autoFocus: true,
                onCompleted: (_) => _verify(),
                onChanged: (_) {},
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 52,
                  fieldWidth: 46,
                  activeColor: AppColors.primary,
                  selectedColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  activeFillColor: AppColors.surfaceAlt,
                  selectedFillColor: AppColors.surfaceAlt,
                  inactiveFillColor: AppColors.surfaceAlt,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    _secondsLeft > 0 ? s.resendIn("00:${_secondsLeft.toString().padLeft(2, '0')}") : s.didntGetCode,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_secondsLeft == 0)
                    TextButton(
                      onPressed: _resending ? null : _resend,
                      child: Text(_resending ? s.sendingEllipsis : s.resend),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              PrimaryButton(label: s.verifyAndContinue, onPressed: _verify, isLoading: _submitting),
            ],
          ),
        ),
      ),
    );
  }
}
