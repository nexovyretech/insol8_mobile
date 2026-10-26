import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';

import 'package:insol8_mobile/pages/onboarding/onboarding_shared_widgets.dart';

class OnboardingConnectDeviceStep extends StatelessWidget {
  const OnboardingConnectDeviceStep({
    super.key,
    required this.deviceCodeController,
    required this.error,
    required this.onChanged,
    required this.onBack,
    required this.onSkip,
    required this.onConnect,
    required this.onScan,
  });

  final TextEditingController deviceCodeController;
  final String? error;
  final VoidCallback onChanged;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onConnect;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showBack: false,
      showGradient: false,
      headerSlotHeight: 0,
      child: Column(
        children: [
          _SetupHeader(title: 'Connect Dryer', onBack: onBack, onSkip: onSkip),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Scan Device QR Code',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Point your camera at the QR code located on the InSOL8 controller box or rear panel of the dryer.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: InkWell(
                      onTap: onScan,
                      borderRadius: BorderRadius.circular(16),
                      child: const SizedBox(
                        width: 96,
                        height: 96,
                        child: Icon(
                          Icons.crop_free,
                          size: 72,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the icon to scan the QR code',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 14, color: AppColors.fieldHint),
                  ),
                  const SizedBox(height: 18),
                  const _OrDivider(label: 'or enter manually'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: deviceCodeController,
                    onChanged: (_) => onChanged(),
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Device Serial / ID',
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    'Where is my code?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check the silver label sticker on the side of your InSOL8 solar thermal controller box or next to the exhaust duct.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 14, color: AppColors.fieldHint),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 14, color: AppColors.fieldHint),
                      children: const [
                        TextSpan(text: "Can't see your code? "),
                        TextSpan(
                          text: 'Contact Support.',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          OnboardingGradientButton(
            label: 'Verify Device',
            onPressed: deviceCodeController.text.trim().isEmpty
                ? null
                : onConnect,
          ),
        ],
      ),
    );
  }
}

class OnboardingDevicePairingLoadingStep extends StatelessWidget {
  const OnboardingDevicePairingLoadingStep({super.key, required this.isQrScan});

  final bool isQrScan;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showBack: false,
      showGradient: false,
      headerSlotHeight: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OnboardingLoadingMark(),
            const SizedBox(height: 22),
            Text(
              isQrScan ? 'Scanning QR code' : 'Connecting device',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isQrScan
                  ? 'Please wait while we find the device ID for your InSOL8 dryer.'
                  : 'Please wait while we verify the device ID for your InSOL8 dryer.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingVerifyDeviceStep extends StatelessWidget {
  const OnboardingVerifyDeviceStep({
    super.key,
    required this.deviceCode,
    required this.error,
    required this.onBack,
    required this.onSkip,
    required this.onVerify,
  });

  final String deviceCode;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showBack: false,
      showGradient: false,
      headerSlotHeight: 0,
      child: OnboardingStickyLayout(
        header: _SetupHeader(
          title: 'Connect Dryer',
          onBack: onBack,
          onSkip: onSkip,
        ),
        content: [
          const SizedBox(height: 24),
          Text(
            'Verify Device ID',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 10),
          Text(
            'Check the hardware serial number found on your InSOL8 drying unit or controller label.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: deviceCode,
            readOnly: true,
            decoration: const InputDecoration(hintText: 'INSOL8-DRY-0941'),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
        ],
        actions: [
          OnboardingGradientButton(label: 'Verify Device', onPressed: onVerify),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class OnboardingDeviceSetupStep extends StatelessWidget {
  const OnboardingDeviceSetupStep({
    super.key,
    required this.deviceNameController,
    required this.deviceCode,
    required this.error,
    required this.onChanged,
    required this.onBack,
    required this.onSkip,
    required this.onFinish,
    required this.onAddAnother,
  });

  final TextEditingController deviceNameController;
  final String deviceCode;
  final String? error;
  final VoidCallback onChanged;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onFinish;
  final VoidCallback onAddAnother;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showBack: false,
      showGradient: false,
      headerSlotHeight: 0,
      child: OnboardingStickyLayout(
        header: _SetupHeader(
          title: 'Device Details',
          onBack: onBack,
          onSkip: onSkip,
        ),
        content: [
          const SizedBox(height: 24),
          Text(
            deviceCode,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'Check the hardware serial number found on your InSOL8 drying unit or controller label.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: deviceNameController,
            onChanged: (_) => onChanged(),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Device nickname'),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
        ],
        actions: [
          OnboardingGradientButton(
            label: 'Complete Registration',
            onPressed: deviceNameController.text.trim().isEmpty
                ? null
                : onFinish,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: deviceNameController.text.trim().isEmpty
                  ? null
                  : onAddAnother,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.fieldHint,
                disabledForegroundColor: AppColors.fieldHint,
                backgroundColor: const Color(0xFFFFF7F2),
                textStyle: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                side: const BorderSide(color: Color(0xFFFFE6D8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Add Another Device'),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({
    required this.title,
    required this.onBack,
    required this.onSkip,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontSize: 13, color: AppColors.fieldHint);
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.disabled, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(label, style: style),
        ),
        const Expanded(child: Divider(color: AppColors.disabled, height: 1)),
      ],
    );
  }
}
