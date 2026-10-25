import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/models/device_setup_data.dart';
import 'package:insol8_mobile/models/subscription_plan.dart';
import 'package:insol8_mobile/constants/legal_documents.dart';
import 'package:insol8_mobile/models/legal_document.dart';
import 'package:insol8_mobile/pages/legal_document_page.dart';
import 'package:insol8_mobile/pages/qr_scanner_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';

/// Post-registration onboarding screens. Payment is intentionally a UI preview
/// until the team's subscription API and payment gateway are available.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.repository});

  final OnboardingRepository repository;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _page = 0;
  int _plan = 0;
  SubscriptionPaymentMethod _paymentMethod = SubscriptionPaymentMethod.gcash;
  bool _isLoadingPlans = true;
  List<SubscriptionPlan> _plans = const [];
  String? _planError;
  final _branchFormKey = GlobalKey<FormState>();
  final _branchNameController = TextEditingController();
  final _branchAddressController = TextEditingController();
  final _managerFirstNameController = TextEditingController();
  final _managerLastNameController = TextEditingController();
  final _deviceCodeController = TextEditingController();
  final _deviceNameController = TextEditingController();
  bool _isQrScanning = false;
  BranchManagerOption? _managerOption;
  bool _isSavingBranch = false;
  String? _deviceError;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _branchAddressController.dispose();
    _managerFirstNameController.dispose();
    _managerLastNameController.dispose();
    _deviceCodeController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _planError = null;
    });
    try {
      final plans = await widget.repository.fetchSubscriptionPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        final basicPlanIndex = plans.indexWhere(
          (plan) => plan.id == 'monthly-basic',
        );
        _plan = basicPlanIndex < 0 ? 0 : basicPlanIndex;
        _isLoadingPlans = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingPlans = false;
        _planError = 'We could not load subscription plans. Please try again.';
      });
    }
  }

  void _next() {
    FocusScope.of(context).unfocus();
    setState(() => _page++);
  }

  Future<void> _startPayment() async {
    setState(() {
      _page = 4;
    });
    try {
      final session = await widget.repository.createCheckoutSession(
        planId: _plans[_plan].id,
        paymentMethod: _paymentMethod,
      );
      if (!mounted) return;
      // The current mock repository returns no checkout URL. A real provider
      // integration must complete and confirm payment before showing success.
      if (session.checkoutUrl != null) {
        setState(() {
          _page = 3;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment provider redirect is not configured yet.'),
          ),
        );
        return;
      }
      setState(() {
        _page = 5;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _page = 3;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start checkout. Please try again.'),
        ),
      );
    }
  }

  Future<void> _saveBranch() async {
    if (!(_branchFormKey.currentState?.validate() ?? false) ||
        _managerOption == null) {
      return;
    }

    setState(() => _isSavingBranch = true);
    try {
      await widget.repository.createBranch(
        BranchSetupData(
          name: _branchNameController.text.trim(),
          address: _branchAddressController.text.trim(),
          managerOption: _managerOption!,
          managerFirstName: _managerOption == BranchManagerOption.newManager
              ? _managerFirstNameController.text.trim()
              : null,
          managerLastName: _managerOption == BranchManagerOption.newManager
              ? _managerLastNameController.text.trim()
              : null,
        ),
      );
      if (!mounted) return;
      setState(() => _page = 7);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save this branch. Please retry.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingBranch = false);
    }
  }

  Future<void> _pairDevice() async {
    final deviceCode = _deviceCodeController.text.trim();
    if (deviceCode.isEmpty) {
      setState(() => _deviceError = 'Enter the device ID or serial number.');
      return;
    }
    setState(() {
      _deviceError = null;
      _page = 8;
    });
    try {
      await widget.repository.pairDevice(
        DevicePairingRequest(
          deviceCode: deviceCode,
          branchName: _branchNameController.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() => _page = 9);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deviceError =
            'We could not connect this device. Check the ID and retry.';
        _page = 7;
      });
    }
  }

  Future<void> _scanQrCode() async {
    final scannedValue = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const QrScannerPage()),
    );
    if (!mounted || scannedValue == null || scannedValue.trim().isEmpty) {
      return;
    }

    setState(() {
      _deviceCodeController.text = scannedValue.trim();
      _deviceError = null;
      _isQrScanning = true;
    });
    await _pairDevice();
  }

  Future<void> _verifyDevice() async {
    setState(() => _deviceError = null);
    try {
      await widget.repository.verifyDevice(
        DeviceVerificationRequest(
          deviceCode: _deviceCodeController.text.trim(),
        ),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFFFDFDFD),
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Hardware Verified',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFF9B18A), fontSize: 16),
          ),
          content: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _deviceCodeController.text.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(
                  text:
                      ' has been verified from our system. Please continue '
                      'to register the device.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
      setState(() => _page = 10);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deviceError =
            'That device ID could not be verified. Please try again.';
        _page = 9;
      });
    }
  }

  Future<void> _finishDeviceSetup() async {
    if (_deviceNameController.text.trim().isEmpty) {
      setState(() => _deviceError = 'Enter a name for this device.');
      return;
    }
    setState(() {
      _deviceError = null;
    });
    try {
      await widget.repository.configureDevice(
        DeviceSetupData(
          deviceCode: _deviceCodeController.text.trim(),
          deviceName: _deviceNameController.text.trim(),
          branchName: _branchNameController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deviceError = 'Could not save device settings. Please retry.';
        _page = 10;
      });
    }
  }

  Future<void> _addAnotherDevice() async {
    if (_deviceNameController.text.trim().isEmpty) {
      setState(() => _deviceError = 'Enter a device nickname first.');
      return;
    }
    try {
      await widget.repository.configureDevice(
        DeviceSetupData(
          deviceCode: _deviceCodeController.text.trim(),
          deviceName: _deviceNameController.text.trim(),
          branchName: _branchNameController.text.trim(),
        ),
      );
      if (!mounted) return;
      _deviceCodeController.clear();
      _deviceNameController.clear();
      setState(() {
        _deviceError = null;
        _page = 7;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deviceError = 'Could not save this device. Please retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: switch (_page) {
            0 => _WelcomeStep(
              key: const ValueKey('welcome'),
              title: 'Welcome to\ninSOL8!',
              description:
                  "Your account is ready. Let's take a few steps to set up "
                  'your smart drying system and get everything ready for your business.',
              pageIndex: 0,
              buttonLabel: 'Continue',
              onContinue: _next,
            ),
            1 => _WelcomeStep(
              key: const ValueKey('business'),
              title: "Let's set up your\nbusiness",
              description:
                  'Tell us a few details about your business so we can '
                  'personalize your InSOL8 experience and set up your system according to your needs.',
              pageIndex: 1,
              buttonLabel: 'Get Started',
              onContinue: _next,
            ),
            2 =>
              _plans.isEmpty
                  ? _SubscriptionPlanLoading(
                      key: const ValueKey('subscription-loading'),
                      isLoading: _isLoadingPlans,
                      error: _planError,
                      onRetry: _loadPlans,
                      onBack: () => setState(() => _page = 1),
                    )
                  : _SubscriptionStep(
                      key: const ValueKey('subscription'),
                      plans: _plans,
                      selectedPlan: _plan,
                      onPlanSelected: (value) => setState(() => _plan = value),
                      onBack: () => setState(() => _page = 1),
                      onContinue: _next,
                    ),
            3 => _PaymentStep(
              key: const ValueKey('payment'),
              plan: _plans[_plan],
              paymentMethod: _paymentMethod,
              onPaymentMethodChanged: (value) =>
                  setState(() => _paymentMethod = value),
              onBack: () => setState(() => _page = 2),
              onContinue: _startPayment,
            ),
            4 => _PaymentLoadingStep(key: const ValueKey('payment-loading')),
            5 => _PaymentSuccessStep(
              key: const ValueKey('payment-success'),
              plan: _plans[_plan],
              buttonLabel: _plans[_plan].id == 'monthly-basic'
                  ? 'Connect Dryer'
                  : 'Set Up Branch',
              onContinue: () {
                final isBasicPlan = _plans[_plan].id == 'monthly-basic';
                if (isBasicPlan) {
                  // Start device pairing with an empty serial field each time.
                  _deviceCodeController.clear();
                  _deviceError = null;
                  _isQrScanning = false;
                }
                setState(() => _page = isBasicPlan ? 7 : 6);
              },
              onSkip: () =>
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
            ),
            6 => _BranchSetupStep(
              key: const ValueKey('branch-setup'),
              onBack: () => setState(() => _page = 5),
              formKey: _branchFormKey,
              branchNameController: _branchNameController,
              branchAddressController: _branchAddressController,
              managerFirstNameController: _managerFirstNameController,
              managerLastNameController: _managerLastNameController,
              managerOption: _managerOption,
              isSaving: _isSavingBranch,
              onManagerOptionChanged: (value) =>
                  setState(() => _managerOption = value),
              onFieldChanged: () => setState(() {}),
              onSkip: () =>
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
              onFinish: _saveBranch,
            ),
            7 => _ConnectDeviceStep(
              key: const ValueKey('connect-device'),
              deviceCodeController: _deviceCodeController,
              error: _deviceError,
              onChanged: () => setState(() {
                _deviceError = null;
                _isQrScanning = false;
              }),
              onBack: () => setState(
                () => _page = _plans[_plan].id == 'monthly-basic' ? 5 : 6,
              ),
              onSkip: () =>
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
              onConnect: _pairDevice,
              onScan: _scanQrCode,
            ),
            8 => _DevicePairingLoadingStep(
              key: const ValueKey('device-loading'),
              isQrScan: _isQrScanning,
            ),
            9 => _VerifyDeviceStep(
              key: const ValueKey('verify-device'),
              deviceCode: _deviceCodeController.text.trim(),
              error: _deviceError,
              onBack: () => setState(() => _page = 7),
              onSkip: () =>
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
              onVerify: _verifyDevice,
            ),
            10 => _DeviceSetupStep(
              key: const ValueKey('device-setup'),
              deviceNameController: _deviceNameController,
              deviceCode: _deviceCodeController.text.trim(),
              error: _deviceError,
              onChanged: () => setState(() => _deviceError = null),
              onBack: () => setState(() => _page = 9),
              onSkip: () =>
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
              onFinish: _finishDeviceSetup,
              onAddAnother: _addAnotherDevice,
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    super.key,
    required this.title,
    required this.description,
    required this.pageIndex,
    required this.buttonLabel,
    required this.onContinue,
  });

  final String title;
  final String description;
  final int pageIndex;
  final String buttonLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      showBack: false,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SvgPicture.asset(
                'assets/logo/getstarted_logo.svg',
                width: 190,
                fit: BoxFit.contain,
                semanticsLabel: 'inSOL8',
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              final active = index == pageIndex;
              return Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : AppColors.fieldHint,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 60,
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontSize: 22, height: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 72,
            child: Center(
              child: Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(height: 1.35),
              ),
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: _GradientButton(
              label: buttonLabel,
              trailingIcon: Icons.chevron_right,
              height: 52,
              borderRadius: 16,
              fontSize: 15,
              gradientColors: const [AppColors.primary, Color(0xFFB94220)],
              onPressed: onContinue,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionStep extends StatelessWidget {
  const _SubscriptionStep({
    super.key,
    required this.plans,
    required this.selectedPlan,
    required this.onPlanSelected,
    required this.onBack,
    required this.onContinue,
  });

  final int selectedPlan;
  final List<SubscriptionPlan> plans;
  final ValueChanged<int> onPlanSelected;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      showBack: true,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Turning sunlight into\nsavings',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 12),
          Text(
            'Scale your shops with multi-branch management, smart solar-thermal drying, and real-time fleet analytics.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.body, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 22),
          const _FeaturesCard(),
          const SizedBox(height: 16),
          _PlanSelectionCard(
            plans: plans,
            selectedPlan: selectedPlan,
            onPlanSelected: onPlanSelected,
          ),
          const SizedBox(height: 12),
          Text(
            'Auto-renews unless canceled at least 24 hours before your billing cycle ends. Cancel anytime in Account Settings.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.fieldHint,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const Spacer(),
          _GradientButton(label: 'Get Subscription', onPressed: onContinue),
          const SizedBox(height: 12),
          const Center(child: _OnboardingLegalLinks()),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _OnboardingLegalLinks extends StatefulWidget {
  const _OnboardingLegalLinks();

  @override
  State<_OnboardingLegalLinks> createState() => _OnboardingLegalLinksState();
}

class _OnboardingLegalLinksState extends State<_OnboardingLegalLinks> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openDocument(LegalDocuments.terms);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openDocument(LegalDocuments.privacy);
  }

  void _openDocument(LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentPage(document: document),
      ),
    );
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.primary, fontSize: 12);
    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
        children: [
          TextSpan(
            text: 'Terms of Service',
            style: linkStyle,
            recognizer: _termsRecognizer,
          ),
          const TextSpan(text: ' & '),
          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _SubscriptionPlanLoading extends StatelessWidget {
  const _SubscriptionPlanLoading({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onBack,
  });

  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      showBack: true,
      onBack: onBack,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const CircularProgressIndicator(color: AppColors.primary)
            else ...[
              Text(
                error ?? 'No subscription plans are available.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeaturesCard extends StatelessWidget {
  const _FeaturesCard();

  static const _features = [
    (
      'Multiple Device Registration',
      'Connect and pair all your drying units',
      Icons.hub_outlined,
    ),
    (
      'Device Monitoring',
      'Real-time status, temps, and battery tracking',
      Icons.monitor_heart_outlined,
    ),
    (
      'Energy Analytics',
      'Measure solar heat efficiency and power usage',
      Icons.bolt_outlined,
    ),
    (
      'Profit Analytics',
      'Track operating costs, runs, and revenue trends',
      Icons.trending_up,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < _features.length; i++) ...[
            Row(
              children: [
                Icon(_features[i].$3, size: 17, color: AppColors.ink),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _features[i].$1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _features[i].$2,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 17,
                ),
              ],
            ),
            if (i != _features.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _PlanSelectionCard extends StatelessWidget {
  const _PlanSelectionCard({
    required this.plans,
    required this.selectedPlan,
    required this.onPlanSelected,
  });

  final List<SubscriptionPlan> plans;
  final int selectedPlan;
  final ValueChanged<int> onPlanSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 144,
      child: Row(
        children: [
          for (var index = 0; index < plans.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(
              child: _PlanOption(
                plan: plans[index],
                selected: selectedPlan == index,
                onTap: () => onPlanSelected(index),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.primary;
    return Material(
      color: selected ? AppColors.primaryDark : const Color(0xFFFFF7F2),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? AppColors.primaryDark : const Color(0xFFFFE6D8),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                plan.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: foreground, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '₱ ${plan.price.toStringAsFixed(2)}',
                maxLines: 1,
                style: TextStyle(
                  color: foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                plan.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground.withValues(alpha: selected ? 1 : 0.72),
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentStep extends StatelessWidget {
  const _PaymentStep({
    super.key,
    required this.plan,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.onBack,
    required this.onContinue,
  });

  final SubscriptionPlan plan;
  final SubscriptionPaymentMethod paymentMethod;
  final ValueChanged<SubscriptionPaymentMethod> onPaymentMethodChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      showBack: true,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            'Complete your\nsubscription',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            "You're one step away from unlocking your inSOL8 subscription access.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Subscription Summary'),
          const SizedBox(height: 8),
          _SubscriptionSummary(plan: plan),
          const SizedBox(height: 14),
          const _SectionLabel('Payment Method'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _PaymentMethodRow(
                  method: SubscriptionPaymentMethod.gcash,
                  selected: paymentMethod == SubscriptionPaymentMethod.gcash,
                  onTap: () =>
                      onPaymentMethodChanged(SubscriptionPaymentMethod.gcash),
                ),
                _PaymentMethodRow(
                  method: SubscriptionPaymentMethod.maya,
                  selected: paymentMethod == SubscriptionPaymentMethod.maya,
                  onTap: () =>
                      onPaymentMethodChanged(SubscriptionPaymentMethod.maya),
                ),
              ],
            ),
          ),
          const Spacer(),
          _GradientButton(
            label:
                'Pay ₱ ${plan.price.toStringAsFixed(2)} via ${paymentMethod.label}',
            onPressed: onContinue,
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TrustNote(
                icon: Icons.shield_outlined,
                title: 'Secure payment',
                subtitle: 'Your data is encrypted',
              ),
              SizedBox(width: 18),
              _TrustNote(
                icon: Icons.lock_outline,
                title: 'Privacy first',
                subtitle: 'We respect your data',
              ),
            ],
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _SubscriptionSummary extends StatelessWidget {
  const _SubscriptionSummary({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      plan.description,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '₱ ${plan.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '/ month',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 13),
            ),
          ),
          const Divider(height: 18, color: Color(0xFFFFD7C2)),
          Text(
            'Features included:',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 5),
          for (final feature in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      feature,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 16, color: Color(0xFFFFD7C2)),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Next Billing Date:',
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ),
              Text(
                'November 01, 2026',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 15, color: Color(0xFFFFD7C2)),
          Center(
            child: Text(
              'Cancel anytime. No commitments.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.fieldHint, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            SizedBox(
              width: 82,
              height: 30,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  method == SubscriptionPaymentMethod.gcash
                      ? 'assets/icons/gcash_logo.svg'
                      : 'assets/icons/maya_logo.svg',
                  width: method == SubscriptionPaymentMethod.gcash ? 78 : 50,
                  height: method == SubscriptionPaymentMethod.gcash ? 28 : 19,
                  fit: BoxFit.contain,
                  semanticsLabel: method.label,
                ),
              ),
            ),
            const SizedBox(width: 9),
            const Spacer(),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.primary,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentLoadingStep extends StatelessWidget {
  const _PaymentLoadingStep({super.key});

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      showBack: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LoadingMark(),
            const SizedBox(height: 22),
            Text(
              "We're almost there",
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Please wait while we securely connect you to the payment gateway to complete your transaction.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 13, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSuccessStep extends StatelessWidget {
  const _PaymentSuccessStep({
    super.key,
    required this.plan,
    required this.buttonLabel,
    required this.onContinue,
    required this.onSkip,
  });

  final SubscriptionPlan plan;
  final String buttonLabel;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      showBack: false,
      child: Column(
        children: [
          const Spacer(),
          Text(
            'Your payment has been successful!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 22),
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration_outlined,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'You paid ₱ ${plan.price.toStringAsFixed(2)} to',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            _subscriptionDisplayName(plan),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: _SectionLabel('Transaction Details'),
          ),
          const SizedBox(height: 8),
          _MockTransactionCard(plan: plan),
          const SizedBox(height: 8),
          Text(
            'Preview only — no real payment has been processed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.fieldHint, fontSize: 14),
          ),
          const Spacer(),
          _GradientButton(
            label: buttonLabel,
            onPressed: onContinue,
            gradientColors: const [AppColors.primary, Color(0xFFB94220)],
            borderRadius: 16,
            fontSize: 14,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
            ),
            child: const Text(
              'Skip to Dashboard for now',
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _MockTransactionCard extends StatelessWidget {
  const _MockTransactionCard({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              plan.id == 'monthly-org'
                  ? 'MONTHLY ORGANIZATION TIER'
                  : 'MONTHLY BASIC TIER',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 18, color: Color(0xFFFFD7C2)),
          const SizedBox(height: 10),
          const _SummaryRow(label: 'Transaction ID:', value: 'TXN-10012026'),
          const SizedBox(height: 8),
          const _SummaryRow(
            label: 'Next Billing Date:',
            value: 'October 01, 2026',
          ),
          const Divider(height: 18, color: Color(0xFFFFD7C2)),
          Text(
            'Your plan is now active. Official receipt sent to your email.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.body, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 12),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

String _subscriptionDisplayName(SubscriptionPlan plan) =>
    plan.id == 'monthly-org'
    ? 'InSOL8 Monthly Organization Tier'
    : 'InSOL8 Monthly Basic Tier';

class _BranchSetupStep extends StatelessWidget {
  const _BranchSetupStep({
    super.key,
    required this.onBack,
    required this.formKey,
    required this.branchNameController,
    required this.branchAddressController,
    required this.managerFirstNameController,
    required this.managerLastNameController,
    required this.managerOption,
    required this.isSaving,
    required this.onManagerOptionChanged,
    required this.onFieldChanged,
    required this.onSkip,
    required this.onFinish,
  });

  final VoidCallback onBack;
  final GlobalKey<FormState> formKey;
  final TextEditingController branchNameController;
  final TextEditingController branchAddressController;
  final TextEditingController managerFirstNameController;
  final TextEditingController managerLastNameController;
  final BranchManagerOption? managerOption;
  final bool isSaving;
  final ValueChanged<BranchManagerOption> onManagerOptionChanged;
  final VoidCallback onFieldChanged;
  final VoidCallback onSkip;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final canFinish =
        branchNameController.text.trim().isNotEmpty &&
        branchAddressController.text.trim().isNotEmpty &&
        managerOption != null &&
        (managerOption == BranchManagerOption.myself ||
            (managerFirstNameController.text.trim().isNotEmpty &&
                managerLastNameController.text.trim().isNotEmpty));

    return _OnboardingScaffold(
      showBack: false,
      showGradient: false,
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 42,
                child: IconButton(
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  color: AppColors.ink,
                  tooltip: 'Back',
                ),
              ),
              Expanded(
                child: Text(
                  'Branch Setup',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.ink,
                ),
                child: const Text('Skip'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Name your first branch',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontSize: 22, height: 1.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Set your primary laundry shop location so you can assign managers and link your inSOL8 dryers.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 12, color: AppColors.body),
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel('Branch Details'),
                    const SizedBox(height: 12),
                    _BranchTextField(
                      controller: branchNameController,
                      hint: 'Branch name',
                      onChanged: onFieldChanged,
                    ),
                    const SizedBox(height: 12),
                    _BranchTextField(
                      controller: branchAddressController,
                      hint: 'Store address',
                      capitalization: TextCapitalization.words,
                      onChanged: onFieldChanged,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A branch represents a physical shop location. It helps you group drying units, view store-level analytics, and assign on-site managers.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 12, color: AppColors.fieldHint),
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('Store Manager'),
                    const SizedBox(height: 12),
                    _ManagerOptionTile(
                      title: 'Assign myself as manager',
                      value: BranchManagerOption.myself,
                      selected: managerOption == BranchManagerOption.myself,
                      onTap: () =>
                          onManagerOptionChanged(BranchManagerOption.myself),
                    ),
                    const SizedBox(height: 10),
                    _ManagerOptionTile(
                      title: 'Add a new manager',
                      value: BranchManagerOption.newManager,
                      selected: managerOption == BranchManagerOption.newManager,
                      onTap: () => onManagerOptionChanged(
                        BranchManagerOption.newManager,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Managers can start cycles, monitor chamber temperatures, and report branch issues.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 12, color: AppColors.fieldHint),
                    ),
                    if (managerOption == BranchManagerOption.newManager) ...[
                      const SizedBox(height: 14),
                      const _SectionLabel('Assign Manager'),
                      const SizedBox(height: 10),
                      _BranchTextField(
                        controller: managerFirstNameController,
                        hint: 'First name',
                        capitalization: TextCapitalization.words,
                        onChanged: onFieldChanged,
                      ),
                      const SizedBox(height: 12),
                      _BranchTextField(
                        controller: managerLastNameController,
                        hint: 'Last name',
                        capitalization: TextCapitalization.words,
                        onChanged: onFieldChanged,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _GradientButton(
            label: isSaving ? 'Saving…' : 'Finish Setup',
            onPressed: canFinish && !isSaving ? onFinish : null,
          ),
          const SizedBox(height: 8),
          Text(
            'You can add more branches, change addresses, or reassign store managers anytime in your Account Settings.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 12, color: AppColors.fieldHint),
          ),
        ],
      ),
    );
  }
}

class _ConnectDeviceStep extends StatelessWidget {
  const _ConnectDeviceStep({
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
    return _OnboardingScaffold(
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
          _GradientButton(
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

class _DevicePairingLoadingStep extends StatelessWidget {
  const _DevicePairingLoadingStep({super.key, required this.isQrScan});

  final bool isQrScan;

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      showBack: false,
      showGradient: false,
      headerSlotHeight: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LoadingMark(),
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

class _VerifyDeviceStep extends StatelessWidget {
  const _VerifyDeviceStep({
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
    return _OnboardingScaffold(
      showBack: false,
      showGradient: false,
      headerSlotHeight: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SetupHeader(title: 'Connect Dryer', onBack: onBack, onSkip: onSkip),
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
          const Spacer(),
          _GradientButton(label: 'Verify Device', onPressed: onVerify),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _DeviceSetupStep extends StatelessWidget {
  const _DeviceSetupStep({
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
    return _OnboardingScaffold(
      showBack: false,
      showGradient: false,
      headerSlotHeight: 0,
      child: Column(
        children: [
          _SetupHeader(title: 'Device Details', onBack: onBack, onSkip: onSkip),
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
          const Spacer(),
          _GradientButton(
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

class _BranchTextField extends StatelessWidget {
  const _BranchTextField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.capitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: capitalization,
      onChanged: (_) => onChanged(),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'This field is required.'
          : null,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
      ),
    );
  }
}

class _ManagerOptionTile extends StatelessWidget {
  const _ManagerOptionTile({
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final BranchManagerOption value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF5EF) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected ? AppColors.primary : AppColors.body,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingMark extends StatefulWidget {
  const _LoadingMark();

  @override
  State<_LoadingMark> createState() => _LoadingMarkState();
}

class _LoadingMarkState extends State<_LoadingMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;
          return Transform.rotate(
            angle: progress * math.pi * 2,
            child: Stack(
              children: [
                _animatedDot(left: 3, top: 21, index: 0, progress: progress),
                _animatedDot(right: 3, top: 7, index: 1, progress: progress),
                _animatedDot(right: 3, bottom: 5, index: 2, progress: progress),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _animatedDot({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required int index,
    required double progress,
  }) {
    final phase = (progress + index / 3) % 1;
    final colorProgress = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    final color = Color.lerp(
      AppColors.primary,
      const Color(0xFFFFB18E),
      colorProgress,
    );
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 12),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.fieldHint,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.height = 54,
    this.borderRadius = 14,
    this.fontSize = 14,
    this.gradientColors = const [AppColors.primary, AppColors.primaryDark],
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final double height;
  final double borderRadius;
  final double fontSize;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isEnabled ? null : AppColors.disabled,
          gradient: isEnabled ? LinearGradient(colors: gradientColors) : null,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: Colors.white, fontSize: fontSize),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 12),
                    Icon(trailingIcon, color: Colors.white, size: 19),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingScaffold extends StatelessWidget {
  const _OnboardingScaffold({
    required this.child,
    required this.showBack,
    this.showGradient = true,
    this.headerSlotHeight = 42,
    this.onBack,
  });

  final Widget child;
  final bool showBack;
  final bool showGradient;
  final double headerSlotHeight;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: showGradient
          ? const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, 1.04),
                radius: 1.15,
                colors: [Color(0xFFFFD1B9), AppColors.background],
                stops: [0, 0.78],
              ),
            )
          : const BoxDecoration(color: AppColors.background),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.pageVertical,
          AppSpacing.pageHorizontal,
          AppSpacing.pageVertical,
        ),
        child: Column(
          children: [
            SizedBox(
              height: headerSlotHeight,
              child: showBack
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: onBack,
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 19),
                        color: AppColors.ink,
                        tooltip: 'Back',
                      ),
                    )
                  : null,
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: const Color(0xFFFFF7F2),
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: const Color(0xFFFFE6D8)),
  boxShadow: const [
    BoxShadow(color: Color(0x0A8A3618), blurRadius: 8, offset: Offset(0, 3)),
  ],
);
