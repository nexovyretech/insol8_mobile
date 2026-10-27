import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/models/device_setup_data.dart';
import 'package:insol8_mobile/models/subscription_plan.dart';
import 'package:insol8_mobile/pages/onboarding/branch_setup_step.dart';
import 'package:insol8_mobile/pages/onboarding/device_setup_steps.dart';
import 'package:insol8_mobile/pages/onboarding/payment_steps.dart';
import 'package:insol8_mobile/pages/onboarding/subscription_steps.dart';
import 'package:insol8_mobile/pages/onboarding/welcome_step.dart';
import 'package:insol8_mobile/pages/device/qr_scanner_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';

/// Opens the same device-only registration flow from onboarding or dashboard
/// actions and returns devices configured during that visit.
Future<List<DeviceSetupData>?> openDeviceRegistrationFlow(
  BuildContext context, {
  required OnboardingRepository repository,
}) => Navigator.of(context).push<List<DeviceSetupData>>(
  MaterialPageRoute<List<DeviceSetupData>>(
    builder: (_) => OnboardingPage(repository: repository, deviceOnly: true),
  ),
);

/// Post-registration onboarding screens. Payment is intentionally a UI preview
/// until the team's subscription API and payment gateway are available.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.repository,
    this.deviceOnly = false,
  });

  final OnboardingRepository repository;
  final bool deviceOnly;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late int _page;
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
  final List<DeviceSetupData> _configuredDevices = [];
  bool _isQrScanning = false;
  BranchManagerOption? _managerOption;
  bool _isSavingBranch = false;
  String? _deviceError;

  @override
  void initState() {
    super.initState();
    _page = widget.deviceOnly ? 7 : 0;
    if (!widget.deviceOnly) _loadPlans();
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
      if (widget.deviceOnly) {
        _configuredDevices.add(
          DeviceSetupData(
            deviceCode: _deviceCodeController.text.trim(),
            deviceName: _deviceNameController.text.trim(),
            branchName: _branchNameController.text.trim(),
          ),
        );
        Navigator.of(context)
            .pop(List<DeviceSetupData>.unmodifiable(_configuredDevices));
        return;
      }
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
      _configuredDevices.add(
        DeviceSetupData(
          deviceCode: _deviceCodeController.text.trim(),
          deviceName: _deviceNameController.text.trim(),
          branchName: _branchNameController.text.trim(),
        ),
      );
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
            0 => OnboardingWelcomeStep(
              key: const ValueKey('welcome'),
              title: 'Welcome to\ninSOL8!',
              description:
                  "Your account is ready. Let's take a few steps to set up "
                  'your smart drying system and get everything ready for your business.',
              pageIndex: 0,
              buttonLabel: 'Continue',
              onContinue: _next,
            ),
            1 => OnboardingWelcomeStep(
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
                  ? OnboardingSubscriptionPlanLoading(
                      key: const ValueKey('subscription-loading'),
                      isLoading: _isLoadingPlans,
                      error: _planError,
                      onRetry: _loadPlans,
                      onBack: () => setState(() => _page = 1),
                    )
                  : OnboardingSubscriptionStep(
                      key: const ValueKey('subscription'),
                      plans: _plans,
                      selectedPlan: _plan,
                      onPlanSelected: (value) => setState(() => _plan = value),
                      onBack: () => setState(() => _page = 1),
                      onContinue: _next,
                    ),
            3 => OnboardingPaymentStep(
              key: const ValueKey('payment'),
              plan: _plans[_plan],
              paymentMethod: _paymentMethod,
              onPaymentMethodChanged: (value) =>
                  setState(() => _paymentMethod = value),
              onBack: () => setState(() => _page = 2),
              onContinue: _startPayment,
            ),
            4 => OnboardingPaymentLoadingStep(
              key: const ValueKey('payment-loading'),
            ),
            5 => OnboardingPaymentSuccessStep(
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
            6 => OnboardingBranchSetupStep(
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
            7 => OnboardingConnectDeviceStep(
              key: const ValueKey('connect-device'),
              deviceCodeController: _deviceCodeController,
              error: _deviceError,
              onChanged: () => setState(() {
                _deviceError = null;
                _isQrScanning = false;
              }),
              onBack: () {
                if (widget.deviceOnly) {
                  Navigator.of(context).pop();
                } else {
                  setState(
                    () => _page = _plans[_plan].id == 'monthly-basic' ? 5 : 6,
                  );
                }
              },
              onSkip: () {
                if (widget.deviceOnly) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
                }
              },
              onConnect: _pairDevice,
              onScan: _scanQrCode,
              showSkip: !widget.deviceOnly,
            ),
            8 => OnboardingDevicePairingLoadingStep(
              key: const ValueKey('device-loading'),
              isQrScan: _isQrScanning,
            ),
            9 => OnboardingVerifyDeviceStep(
              key: const ValueKey('verify-device'),
              deviceCode: _deviceCodeController.text.trim(),
              error: _deviceError,
              onBack: () => setState(() => _page = 7),
              onSkip: () {
                if (widget.deviceOnly) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
                }
              },
              onVerify: _verifyDevice,
              showSkip: !widget.deviceOnly,
            ),
            10 => OnboardingDeviceSetupStep(
              key: const ValueKey('device-setup'),
              deviceNameController: _deviceNameController,
              deviceCode: _deviceCodeController.text.trim(),
              error: _deviceError,
              onChanged: () => setState(() => _deviceError = null),
              onBack: () => setState(() => _page = 9),
              onSkip: () {
                if (widget.deviceOnly) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
                }
              },
              onFinish: _finishDeviceSetup,
              onAddAnother: _addAnotherDevice,
              showSkip: !widget.deviceOnly,
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}
