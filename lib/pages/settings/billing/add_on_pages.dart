import 'package:flutter/material.dart';

import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/branch_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

/// The add-on purchase and success frames that follow Subscription & Usage.
///
/// The backend has no add-on checkout endpoint, so these frames reproduce the
/// Figma flow: plan-specific prices, the light-orange detail frame, payment
/// method selection, and the success receipt. Every arrow/button navigates.
enum AddOnKind { branch, device }

class AddOnFlowArgs {
  const AddOnFlowArgs({
    required this.kind,
    required this.planId,
    this.branchName,
  });

  final AddOnKind kind;
  final String planId;
  final String? branchName;

  static AddOnFlowArgs from(Object? arguments) {
    // The caller may pass a Map<String, String> literal; match any Map so the
    // runtime generic type never breaks navigation.
    if (arguments is Map) {
      return AddOnFlowArgs(
        kind: arguments['kind'] == 'branch'
            ? AddOnKind.branch
            : AddOnKind.device,
        planId: arguments['planId'] as String? ?? SubscriptionPlanIds.basic,
        branchName: arguments['branchName'] as String?,
      );
    }
    final planId = arguments as String? ?? SubscriptionPlanIds.basic;
    return AddOnFlowArgs(
      kind: planId == SubscriptionPlanIds.organization
          ? AddOnKind.branch
          : AddOnKind.device,
      planId: planId,
    );
  }

  Map<String, dynamic> toMap() => {
    'kind': kind.name,
    'planId': planId,
    'branchName': ?branchName,
  };
}

class AddOnPurchasePage extends StatefulWidget {
  const AddOnPurchasePage({
    super.key,
    required this.kind,
    required this.planId,
    this.branchRepository,
  });

  final AddOnKind kind;
  final String planId;
  final BranchRepository? branchRepository;

  @override
  State<AddOnPurchasePage> createState() => _AddOnPurchasePageState();
}

class _AddOnPurchasePageState extends State<AddOnPurchasePage> {
  static const _fallbackBranches = [
    'Caloocan Branch',
    'Manila Branch',
    'Quezon City Branch',
  ];

  late String _selectedMethod;
  List<String> _branches = _fallbackBranches;
  String? _selectedBranch;

  bool get _organization => widget.planId == SubscriptionPlanIds.organization;

  @override
  void initState() {
    super.initState();
    _selectedMethod = 'GCash';
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final repository = widget.branchRepository;
    if (repository == null) return;
    try {
      final branches = await repository.fetchBranches();
      if (!mounted || branches.isEmpty) return;
      setState(() {
        _branches = [
          for (final branch in branches)
            if (branch.name.isNotEmpty) branch.name,
        ];
        if (_branches.isEmpty) _branches = _fallbackBranches;
      });
    } on Exception {
      // Keep the screenshot branch names when the backend is unavailable.
    }
  }

  String get _title => switch (widget.kind) {
    AddOnKind.branch => 'Expand your organization',
    AddOnKind.device => 'Add Additional Devices',
  };

  String get _description => switch (widget.kind) {
    AddOnKind.branch =>
      "You've reached your free branch limit. Add another branch to manage "
          'more locations under your organization.',
    AddOnKind.device =>
      "Expand your branch's device capacity by purchasing additional "
          'device slots.',
  };

  String get _sectionLabel => switch (widget.kind) {
    AddOnKind.branch => 'Additional Branch',
    AddOnKind.device => 'Additional Device Slots',
  };

  String get _itemTitle => switch (widget.kind) {
    AddOnKind.branch => 'ADDITIONAL BRANCH',
    AddOnKind.device => 'ADDITIONAL DEVICE',
  };

  String get _price => switch (widget.kind) {
    AddOnKind.branch => '₱250.00',
    AddOnKind.device => _organization ? '₱55.00' : '₱35.00',
  };

  String get _payAmount => switch (widget.kind) {
    AddOnKind.branch => '₱265.00',
    AddOnKind.device => '₱55.00',
  };

  List<String> get _features => switch (widget.kind) {
    AddOnKind.branch => const [
      'Up to 5 devices included',
      'Dedicated branch management',
      'Branch manager assignment',
      'Device monitoring',
    ],
    AddOnKind.device => const [
      'Additional device registration',
      'Device monitoring',
      'Energy analytics',
      'Profit analytics',
    ],
  };

  String get _successRoute => switch (widget.kind) {
    AddOnKind.branch => AppRoutes.additionalBranchSuccess,
    AddOnKind.device => AppRoutes.additionalDeviceSuccess,
  };

  Future<void> _showBranchPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, 10),
              child: Text(
                'Select',
                style: TextStyle(
                  color: _orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final branch in _branches)
              ListTile(
                title: Text(branch, style: const TextStyle(fontSize: 14)),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: _muted,
                  size: 20,
                ),
                onTap: () => Navigator.of(context).pop(branch),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _selectedBranch = selected);
  }

  void _pay() => Navigator.of(context).pushNamed(
    _successRoute,
    arguments: AddOnFlowArgs(
      kind: widget.kind,
      planId: widget.planId,
      branchName: _selectedBranch,
    ).toMap(),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _surface,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ListView(
          padding: const EdgeInsets.only(top: 18, bottom: 20),
          children: [
            AppInnerPageHeader(
              title: 'Subscription & Usage',
              onBack: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 26),
            Text(
              _title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _heading,
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  _sectionLabel,
                  style: const TextStyle(
                    color: _section,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _showBranchPicker,
                  child: Row(
                    children: [
                      Text(
                        _selectedBranch ??
                            (widget.kind == AddOnKind.branch
                                ? 'Select'
                                : 'Select Branch'),
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: _muted, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: _frame,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _frameBorder),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _itemTitle,
                          style: const TextStyle(
                            color: _orange,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _price,
                        style: const TextStyle(
                          color: _orange,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        widget.kind == AddOnKind.branch
                            ? 'Per additional branch'
                            : 'Per additional device slot',
                        style: const TextStyle(color: _orange, fontSize: 11),
                      ),
                      const Spacer(),
                      const Text(
                        '/ month',
                        style: TextStyle(color: _orange, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  for (final feature in _features) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 7),
                            child: SizedBox(
                              width: 6,
                              height: 6,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                color: _body,
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Divider(color: _frameBorder, height: 1),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Text(
                        'Next Billing Date:',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'October 01, 2026',
                        style: TextStyle(
                          color: _body,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'Cancel anytime. No commitments.',
                      style: TextStyle(color: _orange, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Method',
              style: TextStyle(
                color: _section,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final method in const ['GCash', 'Maya'])
              InkWell(
                onTap: () => setState(() => _selectedMethod = method),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _selectedMethod == method
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _orange,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        method,
                        style: const TextStyle(color: _body, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _pay,
                child: Text(
                  'Pay $_payAmount via $_selectedMethod',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Column(
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: _muted),
                    SizedBox(height: 2),
                    Text(
                      'Secure payment',
                      style: TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.privacy_tip_outlined, size: 14, color: _muted),
                    SizedBox(height: 2),
                    Text(
                      '& Privacy first',
                      style: TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class AddOnSuccessPage extends StatelessWidget {
  const AddOnSuccessPage({
    super.key,
    required this.kind,
    required this.planId,
    this.branchName,
  });

  final AddOnKind kind;
  final String planId;
  final String? branchName;

  bool get _organization => planId == SubscriptionPlanIds.organization;

  String get _amount => switch (kind) {
    AddOnKind.branch => '₱250.00',
    AddOnKind.device => _organization ? '₱55.00' : '₱35.00',
  };

  String get _payee => switch (kind) {
    AddOnKind.branch => 'InSOL8 Additional Branch',
    AddOnKind.device => 'InSOL8 Additional Devices',
  };

  String get _transactionTitle => switch (kind) {
    AddOnKind.branch => 'ADDITIONAL BRANCH',
    AddOnKind.device => 'ADDITIONAL DEVICES',
  };

  void _goToBranches(BuildContext context) =>
      Navigator.of(context).pushNamed(AppRoutes.branches);

  void _goToDashboard(BuildContext context) =>
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _surface,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ListView(
          padding: const EdgeInsets.only(top: 32, bottom: 20),
          children: [
            const Icon(Icons.check_circle_outline, color: _orange, size: 92),
            const SizedBox(height: 18),
            const Text(
              'Your payment has been\nsuccessful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _heading,
                fontSize: 22,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 72),
            Text(
              'You paid $_amount to',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _orange,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _payee,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _body,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (kind == AddOnKind.device && branchName != null) ...[
              const SizedBox(height: 2),
              Text(
                'to $branchName',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _body, fontSize: 13),
              ),
            ],
            const SizedBox(height: 28),
            const Text(
              'Transaction Details',
              style: TextStyle(
                color: _section,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: _frame,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _frameBorder),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    _transactionTitle,
                    style: const TextStyle(
                      color: _orange,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: _frameBorder, height: 1),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Text(
                        'Transaction ID:',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                      Spacer(),
                      Text(
                        'TXN-10012026',
                        style: TextStyle(
                          color: _body,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Text(
                        'Next Billing Date:',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                      Spacer(),
                      Text(
                        'October 01, 2026',
                        style: TextStyle(
                          color: _body,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your plan is now active. Official receipt sent to your email.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 48),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _goToBranches(context),
                child: const Text(
                  'Set Up Branch',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _goToDashboard(context),
              child: const Text(
                'Skip to Dashboard for now',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

const Color _surface = Color(0xFFFDFDFD);
const Color _frame = Color(0xFFFDF6F1);
const Color _frameBorder = Color(0xFFFBE9DA);
const Color _section = Color(0xFFEEB490);
const Color _orange = Color(0xFFD97247);
const Color _heading = Color(0xFF3D170E);
const Color _body = Color(0xFF161310);
const Color _muted = Color(0xFF8C7F78);
