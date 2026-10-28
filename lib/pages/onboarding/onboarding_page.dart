import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/models/device_setup_data.dart';
import 'package:insol8_mobile/models/onboarding_status.dart';
import 'package:insol8_mobile/models/subscription_plan.dart';
import 'package:insol8_mobile/pages/onboarding/branch_setup_step.dart';
import 'package:insol8_mobile/pages/onboarding/device_setup_steps.dart';
import 'package:insol8_mobile/pages/onboarding/payment_steps.dart';
import 'package:insol8_mobile/pages/onboarding/subscription_steps.dart';
import 'package:insol8_mobile/pages/onboarding/welcome_step.dart';
import 'package:insol8_mobile/pages/devices/qr_scanner_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';

/// Opens the payment provider's checkout page; returns false if it could not.
typedef CheckoutOpener = Future<bool> Function(Uri checkoutUrl);

// PayMongo's hosted page runs in the browser; when it finishes it returns to
// com.insol8.mobile://payment/..., which brings the app back to the front.
// Coming back triggers a check in which the backend asks PayMongo for the
// payment, so the app moves on to the success page by itself.
Future<bool> _openInBrowser(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

/// Opens the same device-only registration flow from onboarding or dashboard
/// actions and returns devices configured during that visit.
Future<List<DeviceSetupData>?> openDeviceRegistrationFlow(
  BuildContext context, {
  required OnboardingRepository repository,
  String? initialBranchName,
}) => Navigator.of(context).push<List<DeviceSetupData>>(
  MaterialPageRoute<List<DeviceSetupData>>(
    builder: (_) => OnboardingPage(
      repository: repository,
      deviceOnly: true,
      initialBranchName: initialBranchName,
    ),
  ),
);

/// Post-registration onboarding: plan, payment, branch, then devices.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.repository,
    this.deviceOnly = false,
    this.pricingOnly = false,
    this.initialPlanId,
    this.initialBranchName,
    this.openCheckout = _openInBrowser,
    this.paymentPollInterval = const Duration(seconds: 4),
    this.paymentTimeout = const Duration(minutes: 15),
  });

  final OnboardingRepository repository;
  final bool deviceOnly;
  final bool pricingOnly;
  final String? initialPlanId;
  final String? initialBranchName;
  final CheckoutOpener openCheckout;
  final Duration paymentPollInterval;
  final Duration paymentTimeout;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with WidgetsBindingObserver {
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

  OnboardingStatus? _status;
  String? _branchId;

  // Payment confirmation: the reference being waited on and its poll timer.
  String? _pendingReference;
  Timer? _paymentPoll;
  DateTime? _paymentDeadline;
  bool _isCheckingPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _page = widget.deviceOnly ? 7 : (widget.pricingOnly ? 2 : 0);
    _branchNameController.text = widget.initialBranchName ?? '';
    if (!widget.deviceOnly) _loadPlans();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _paymentPoll?.cancel();
    _branchNameController.dispose();
    _branchAddressController.dispose();
    _managerFirstNameController.dispose();
    _managerLastNameController.dispose();
    _deviceCodeController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  // Returning from the browser is the most likely moment the payment landed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingReference != null) {
      _checkPayment();
    }
  }

  /// The plan whose features apply: the paid one if any, else the selection.
  SubscriptionPlan get _activePlan {
    final paidId = _status?.activePlanId;
    if (paidId != null) {
      for (final plan in _plans) {
        if (plan.id == paidId) return plan;
      }
    }
    return _plans[_plan];
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _planError = null;
    });
    final status = _fetchStatusOrNull();
    try {
      final plans = await widget.repository.fetchSubscriptionPlans();
      final current = await status;
      if (!mounted) return;
      setState(() {
        _plans = plans;
        final preferredPlanId =
            widget.initialPlanId ?? current?.activePlanId ?? 'monthly-basic';
        final preferredPlanIndex = plans.indexWhere(
          (plan) => plan.id == preferredPlanId,
        );
        final basicPlanIndex = plans.indexWhere(
          (plan) => plan.id == 'monthly-basic' || plan.id == 'basic',
        );
        _plan = preferredPlanIndex >= 0
            ? preferredPlanIndex
            : (basicPlanIndex < 0 ? 0 : basicPlanIndex);
        _isLoadingPlans = false;
        _status = current;
        _branchId = current?.primaryBranchId;
      });
      if (current != null) _resume(current);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingPlans = false;
        _planError = 'We could not load subscription plans. Please try again.';
      });
    }
  }

  Future<OnboardingStatus?> _fetchStatusOrNull() async {
    try {
      return await widget.repository.fetchOnboardingStatus();
    } on Exception {
      return null;
    }
  }

  // A user who already paid continues where they left off instead of being
  // asked to pay again. Only applied while still on the welcome screens.
  void _resume(OnboardingStatus status) {
    if (_page > 1 || !status.isSubscriptionActive) return;
    if (status.complete) {
      _goHome();
    } else if (status.primaryBranchId == null) {
      setState(() => _page = 6);
    } else if (status.deviceId == null) {
      setState(() => _page = 7);
    }
  }

  void _next() {
    FocusScope.of(context).unfocus();
    setState(() => _page++);
  }

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  /// Turns a backend error code into something the user can act on.
  String _messageFor(Object error, String fallback) {
    if (error is! ApiException) return fallback;
    return switch (error.code) {
      'NETWORK' || 'TIMEOUT' => error.message,
      'DEVICE_NOT_FOUND' =>
        'We could not find that device ID. Check the code and try again.',
      'DEVICE_UNAVAILABLE' =>
        'This device is already linked to another account.',
      'BRANCH_LIMIT_REACHED' => _branchLimitMessage(),
      'PLAN_FEATURE_REQUIRED' => error.message,
      'SUBSCRIPTION_REQUIRED' =>
        'Your subscription is not active yet. Complete the payment first.',
      'BRANCH_NOT_FOUND' =>
        'That branch could not be found. Set up your branch again.',
      'PAYMENTS_NOT_CONFIGURED' =>
        'Payments are not available right now. Please try again later.',
      'UNAUTHORIZED' => 'Your session has expired. Please sign in again.',
      _ => fallback,
    };
  }

  // Names the paid plan's limit and the plan that lifts it, from the catalog.
  String _branchLimitMessage() {
    final plan = _activePlan;
    final max = plan.maxBranches;
    final limit = max == null
        ? 'Your plan has reached its branch limit.'
        : '${plan.name} includes $max ${max == 1 ? 'branch' : 'branches'}.';
    final upgrade = _plans
        .where((other) {
          final otherMax = other.maxBranches;
          return otherMax == null || (max != null && otherMax > max);
        })
        .map((other) => other.name)
        .firstOrNull;
    return upgrade == null ? limit : '$limit Upgrade to $upgrade to add more.';
  }

  void _backFromSubscription() {
    if (widget.pricingOnly) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _page = 1);
  }

  Future<void> _startPayment() async {
    setState(() => _page = 4);
    try {
      final session = await widget.repository.createCheckoutSession(
        planId: _plans[_plan].id,
        paymentMethod: _paymentMethod,
      );
      final reference = session.reference;
      if (reference == null) throw const FormatException('No reference');
      final url = session.checkoutUrl;
      if (url != null && !await widget.openCheckout(url)) {
        throw const FormatException('Checkout page did not open');
      }
      if (!mounted) return;
      _awaitPayment(reference);
    } catch (error) {
      if (!mounted) return;
      setState(() => _page = 3);
      _showMessage(
        _messageFor(error, 'Could not start checkout. Please try again.'),
      );
    }
  }

  void _awaitPayment(String reference) {
    _paymentPoll?.cancel();
    setState(() {
      _pendingReference = reference;
      _paymentDeadline = DateTime.now().add(widget.paymentTimeout);
    });
    _paymentPoll = Timer.periodic(
      widget.paymentPollInterval,
      (_) => _checkPayment(),
    );
    _checkPayment();
  }

  Future<void> _checkPayment({bool userRequested = false}) async {
    final reference = _pendingReference;
    if (reference == null || _isCheckingPayment) return;
    _isCheckingPayment = true;
    try {
      // Has the backend check with PayMongo directly, so the payment is
      // recorded even when the webhook is late. If that check fails, the
      // status below still reports a payment the webhook already recorded.
      var paymentConfirmed = false;
      try {
        paymentConfirmed = await widget.repository.confirmPayment(reference);
      } on Exception {
        // Fall through to the status check.
      }
      final status = await widget.repository.fetchOnboardingStatus();
      if (!mounted || _pendingReference != reference) return;
      if (paymentConfirmed || status.isPaid(reference)) {
        _stopWaitingForPayment();
        setState(() {
          _status = status;
          _page = 5;
        });
        return;
      }
      if (DateTime.now().isAfter(_paymentDeadline!)) {
        _stopWaitingForPayment();
        setState(() => _page = 3);
        _showMessage(
          'We have not received your payment yet. If you paid, it may take a '
          'few minutes; try again shortly.',
        );
      } else if (userRequested) {
        _showMessage(
          'Payment not confirmed yet. It can take a moment after you pay.',
        );
      }
    } catch (error) {
      if (userRequested && mounted) {
        _showMessage(_messageFor(error, 'Could not check your payment.'));
      }
    } finally {
      _isCheckingPayment = false;
    }
  }

  void _stopWaitingForPayment() {
    _paymentPoll?.cancel();
    _paymentPoll = null;
    _pendingReference = null;
  }

  void _cancelPayment() {
    _stopWaitingForPayment();
    setState(() => _page = 3);
  }

  Future<void> _saveBranch() async {
    if (!(_branchFormKey.currentState?.validate() ?? false) ||
        _managerOption == null) {
      return;
    }

    setState(() => _isSavingBranch = true);
    try {
      final branchId = await widget.repository.createBranch(
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
      setState(() {
        _branchId = branchId;
        _deviceCodeController.clear();
        _deviceError = null;
        _isQrScanning = false;
        _page = 7;
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        _messageFor(error, 'Could not save this branch. Please retry.'),
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
        DevicePairingRequest(deviceCode: deviceCode),
      );
      if (!mounted) return;
      setState(() => _page = 9);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deviceError = _messageFor(
          error,
          'We could not connect this device. Check the ID and retry.',
        );
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
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deviceError = _messageFor(
          error,
          'That device ID could not be verified. Please try again.',
        );
        _page = 9;
      });
    }
  }

  void _goHome() {
    if (widget.deviceOnly) {
      Navigator.of(context)
          .pop(List<DeviceSetupData>.unmodifiable(_configuredDevices));
    } else {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    }
  }

  Future<bool> _registerDevice() async {
    if (_deviceNameController.text.trim().isEmpty) {
      setState(() => _deviceError = 'Enter a name for this device.');
      return false;
    }
    setState(() => _deviceError = null);
    try {
      final device = DeviceSetupData(
        deviceCode: _deviceCodeController.text.trim(),
        deviceName: _deviceNameController.text.trim(),
        branchId: _branchId,
      );
      await widget.repository.configureDevice(device);
      if (widget.deviceOnly) _configuredDevices.add(device);
      return true;
    } catch (error) {
      if (mounted) {
        setState(() {
          _deviceError = _messageFor(
            error,
            'Could not save device settings. Please retry.',
          );
          _page = 10;
        });
      }
      return false;
    }
  }

  Future<void> _finishDeviceSetup() async {
    if (await _registerDevice() && mounted) _goHome();
  }

  Future<void> _addAnotherDevice() async {
    if (!await _registerDevice() || !mounted) return;
    _deviceCodeController.clear();
    _deviceNameController.clear();
    setState(() {
      _deviceError = null;
      _isQrScanning = false;
      _page = 7;
    });
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
                      onBack: _backFromSubscription,
                    )
                  : OnboardingSubscriptionStep(
                      key: const ValueKey('subscription'),
                      plans: _plans,
                      selectedPlan: _plan,
                      onPlanSelected: (value) => setState(() => _plan = value),
                      onBack: _backFromSubscription,
                      onContinue: _next,
                    ),
            3 => OnboardingPaymentStep(
              key: const ValueKey('payment'),
              plan: _plans[_plan],
              nextBillingDate: (_status ?? const OnboardingStatus())
                  .nextBillingDateFor(_plans[_plan].id),
              paymentMethod: _paymentMethod,
              onPaymentMethodChanged: (value) =>
                  setState(() => _paymentMethod = value),
              onBack: () => setState(() => _page = 2),
              onContinue: _startPayment,
            ),
            4 =>
              _pendingReference == null
                  ? const OnboardingPaymentLoadingStep(
                      key: ValueKey('payment-loading'),
                    )
                  : OnboardingPaymentLoadingStep(
                      key: const ValueKey('payment-waiting'),
                      title: 'Waiting for your payment',
                      message:
                          'Complete the payment in your browser. This screen '
                          'continues automatically once it is confirmed.',
                      onCheckAgain: () => _checkPayment(userRequested: true),
                      onCancel: _cancelPayment,
                    ),
            5 => OnboardingPaymentSuccessStep(
              key: const ValueKey('payment-success'),
              plan: _activePlan,
              reference: _status?.lastPaidReference,
              nextBillingDate: _status?.currentPeriodEnd,
              buttonLabel:
                  _activePlan.id == 'monthly-basic' || _activePlan.id == 'basic'
                  ? (widget.pricingOnly ? 'Return to Billing' : 'Connect Dryer')
                  : (widget.pricingOnly
                        ? 'Return to Billing'
                        : 'Set Up Branch'),
              onContinue: () {
                if (widget.pricingOnly) {
                  Navigator.of(context).pop();
                  return;
                }
                final isBasicPlan =
                    _activePlan.id == 'monthly-basic' ||
                    _activePlan.id == 'basic';
                if (isBasicPlan) {
                  // Start device pairing with an empty serial field each time.
                  _deviceCodeController.clear();
                  _deviceError = null;
                  _isQrScanning = false;
                }
                setState(() => _page = isBasicPlan ? 7 : 6);
              },
              onSkip: widget.pricingOnly
                  ? () => Navigator.of(context).pop()
                  : () => Navigator.of(context)
                        .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
              skipLabel: widget.pricingOnly
                  ? null
                  : 'Skip to Dashboard for now',
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
              canAssignManagers: _activePlan.canAssignManagers,
              onManagerOptionChanged: (value) =>
                  setState(() => _managerOption = value),
              onFieldChanged: () => setState(() {}),
              onSkip: _goHome,
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
                  setState(() => _page = 6);
                }
              },
              onSkip: _goHome,
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
              onSkip: _goHome,
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
              onSkip: _goHome,
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
