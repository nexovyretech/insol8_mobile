import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/legal_document.dart';
import 'package:insol8_mobile/constants/legal_documents.dart';
import 'package:insol8_mobile/pages/home/dashboard_bottom_navigation.dart';
import 'package:insol8_mobile/pages/legal/legal_document_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

enum SettingsContentType {
  billing,
  preferences,
  faqs,
  troubleshooting,
  userGuide,
  reportIssue,
  aboutUs,
}

class SettingsContentPage extends StatefulWidget {
  const SettingsContentPage({
    super.key,
    required this.type,
    required this.authRepository,
    required this.subscriptionRepository,
  });

  final SettingsContentType type;
  final AuthRepository authRepository;
  final SubscriptionRepository subscriptionRepository;

  @override
  State<SettingsContentPage> createState() => _SettingsContentPageState();
}

class _SettingsContentPageState extends State<SettingsContentPage> {
  String? _planId;
  bool _loading = true;
  String _theme = 'Light';
  String? _issueCategory;
  String? _issueArea;
  String? _issueImpact;
  final TextEditingController _issueDescriptionController =
      TextEditingController();
  bool _faqSearchOpen = false;
  String _faqQuery = '';
  final TextEditingController _faqSearchController = TextEditingController();
  final FocusNode _faqSearchFocus = FocusNode();
  final Map<String, bool> _notifications = {
    'Push notifications': true,
    'Drying cycle completion': true,
    'Battery and temperature alerts': true,
    'Branch updates and logs': true,
    'Marketing news and updates': true,
  };

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _faqSearchController.dispose();
    _faqSearchFocus.dispose();
    _issueDescriptionController.dispose();
    super.dispose();
  }

  void _toggleFaqSearch() {
    setState(() {
      _faqSearchOpen = !_faqSearchOpen;
      if (!_faqSearchOpen) {
        _faqQuery = '';
        _faqSearchController.clear();
      }
    });
    if (_faqSearchOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _faqSearchFocus.requestFocus();
      });
    }
  }

  Future<void> _loadAccount() async {
    try {
      final planId =
          await widget.subscriptionRepository.fetchActivePlanId() ??
          SubscriptionPlanIds.basic;
      if (!mounted) return;
      setState(() {
        _planId = planId;
        _loading = false;
      });
    } on Exception {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _title => switch (widget.type) {
    SettingsContentType.billing => 'Billing Information',
    SettingsContentType.preferences => 'Preferences',
    SettingsContentType.faqs => 'FAQs',
    SettingsContentType.troubleshooting => 'Troubleshooting',
    SettingsContentType.userGuide => 'User Guide',
    SettingsContentType.reportIssue => 'Report Issue',
    SettingsContentType.aboutUs => 'About Us',
  };

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _navigate(int index) {
    if (index == 3) {
      Navigator.of(context)
          .popUntil((route) => route.settings.name == AppRoutes.settings);
    } else if (index == 0) {
      Navigator.of(context)
          .popUntil((route) => route.settings.name == AppRoutes.home);
    } else if (index == 1) {
      Navigator.of(context).pushNamed(
        _planId == SubscriptionPlanIds.organization
            ? AppRoutes.branches
            : AppRoutes.devices,
      );
    } else if (index == 2) {
      Navigator.of(context).pushNamed(AppRoutes.analytics);
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _SettingsModal(
        message:
            'Are you sure you want to cancel? If you cancel now, you’ll '
            'still have full access to your Org Tier features until the end '
            'of your billing cycle on October 01, 2026.',
        boldText: 'Are you sure you want to cancel?',
        cancelLabel: 'Cancel',
        confirmLabel: 'OK',
      ),
    );
    if (!mounted || confirmed != true) return;
    _message(
      'Subscription cancellation is not connected yet. Please contact support.',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal,
        ),
        child: Column(
          children: [
            SizedBox(height: AppSpacing.pageHeaderTop),
            AppInnerPageHeader(
              title: _title,
              onBack: () => Navigator.pop(context),
              trailing: widget.type == SettingsContentType.faqs
                  ? IconButton(
                      tooltip: 'Search FAQs',
                      onPressed: _toggleFaqSearch,
                      icon: const Icon(Icons.search),
                    )
                  : widget.type != SettingsContentType.billing &&
                        widget.type != SettingsContentType.preferences &&
                        widget.type != SettingsContentType.reportIssue &&
                        widget.type != SettingsContentType.aboutUs
                  ? IconButton(
                      tooltip: 'Help',
                      onPressed: () => _message('Contact support for help.'),
                      icon: const Icon(Icons.help_outline),
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (_loading && widget.type == SettingsContentType.billing)
                    const LinearProgressIndicator(),
                  _content(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: DashboardBottomNavigation(
      selectedIndex: 3,
      organizationPlan: _planId == SubscriptionPlanIds.organization,
      onSelect: _navigate,
    ),
  );

  Widget _content() => switch (widget.type) {
    SettingsContentType.billing => _billingContent(),
    SettingsContentType.preferences => _preferencesContent(),
    SettingsContentType.faqs => _faqContent(),
    SettingsContentType.troubleshooting => _troubleshootingContent(),
    SettingsContentType.userGuide => _guideContent(),
    SettingsContentType.reportIssue => _reportIssueContent(),
    SettingsContentType.aboutUs => _aboutUsContent(),
  };

  Widget _billingContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SettingsSection('Current Subscription'),
      _SettingsCard(
        children: [
          _SettingsRow(
            'Org Tier',
            _planId == SubscriptionPlanIds.basic ? 'Inactive' : 'Active',
          ),
          const _SettingsRow('Plan pricing', 'Php 250 / month'),
          _SettingsRow(
            'Change plan',
            '›',
            onTap: () async {
              await Navigator.of(context)
                  .pushNamed(AppRoutes.changePlan, arguments: _planId);
              if (mounted) await _loadAccount();
            },
            last: true,
          ),
        ],
      ),
      const SizedBox(height: 18),
      const _SettingsSection('Billing Details'),
      const _SettingsCard(
        children: [
          _SettingsRow('Payment status', 'Paid'),
          _SettingsRow('Next billing date', 'October 01, 2026'),
          _SettingsRow('Subscription started', 'September 01, 2026'),
          _SettingsRow('Payment method', 'e-Wallet', last: true),
        ],
      ),
      const SizedBox(height: 18),
      const _SettingsSection('Invoice & History'),
      _SettingsCard(
        children: [
          _SettingsRow(
            'See history',
            '›',
            onTap: () => _message('Invoice history is not connected yet.'),
            last: true,
          ),
        ],
      ),
      const SizedBox(height: 18),
      const _SettingsSection('Danger Zone'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _planId == SubscriptionPlanIds.organization
                ? _cancelSubscription
                : null,
            child: const Text('Cancel subscription'),
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Canceling will downgrade your organization to the Basic plan at the '
        'end of this billing cycle. Branch pool and multi-location '
        'assignments will be disabled.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.fieldHint, fontSize: 12, height: 1.3),
      ),
    ],
  );

  Widget _preferencesContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SettingsSection('Notification'),
      _SettingsCard(
        children: [
          for (final entry in _notifications.entries)
            _SettingsSwitchRow(
              label: entry.key,
              value: entry.value,
              last: entry.key == _notifications.keys.last,
              onChanged: (value) =>
                  setState(() => _notifications[entry.key] = value),
            ),
        ],
      ),
      const _SettingsSection('Appearance'),
      _SettingsCard(
        children: [
          _SettingsThemeRow(
            value: _theme,
            onSelected: (value) => setState(() => _theme = value),
          ),
        ],
      ),
    ],
  );

  Widget _faqContent() {
    const groups = <String, List<String>>{
      'Hardware & Sensors': [
        'What does the Battery / PCM charge percentage mean?',
        'Why is my dryer showing as “Offline”?',
        'How do I unregister or relocate a device?',
      ],
      'Cycles & Controls': [
        'How does the system select target heat for fabrics?',
        'Can I cancel or pause an active cycle remotely?',
        'What happens if temperatures exceed safe limits?',
      ],
      'Branch Management': [
        'How do I add a new branch to my business account?',
        'Can a single device be assigned to multiple branches?',
        'How do manager permissions work?',
      ],
      'Subscription & Billing': [
        'What is the difference between Basic and Org Tier?',
        'How do I upgrade or cancel my plan?',
      ],
    };
    final query = _faqQuery.trim().toLowerCase();
    final filteredGroups = groups.entries
        .map((entry) {
          final questions = entry.value
              .where(
                (question) =>
                    query.isEmpty ||
                    entry.key.toLowerCase().contains(query) ||
                    question.toLowerCase().contains(query),
              )
              .toList();
          return MapEntry(entry.key, questions);
        })
        .where((entry) => entry.value.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_faqSearchOpen) ...[
          TextField(
            controller: _faqSearchController,
            focusNode: _faqSearchFocus,
            onChanged: (value) => setState(() => _faqQuery = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search questions',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _faqSearchController.clear();
                  setState(() => _faqQuery = '');
                  _faqSearchFocus.requestFocus();
                },
                icon: const Icon(Icons.close),
              ),
              filled: true,
              fillColor: AppColors.dashboardCard,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        for (final group in filteredGroups) ...[
          _SettingsSection(group.key),
          _SettingsCard(
            children: [
              for (var index = 0; index < group.value.length; index++)
                _FaqRow(
                  question: group.value[index],
                  last: index == group.value.length - 1,
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        if (filteredGroups.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No matching questions found.',
                style: TextStyle(color: AppColors.fieldHint, fontSize: 14),
              ),
            ),
          ),
        if (query.isEmpty) ...[
          const _SettingsSection('Still Need Help?'),
          _SettingsCard(
            children: [
              _SettingsRow(
                'Contact Support',
                '›',
                onTap: () =>
                    _message('Contact nexovyre@gmail.com for support.'),
                last: true,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _troubleshootingContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SettingsSection('System Health Scan'),
      const _SettingsCard(
        children: [
          _SettingsRow('Gateway/Cloud Link', 'Online'),
          _SettingsRow('Device heartbeats', '14/14 Active'),
          _SettingsRow('Chamber sensors', 'Optimal 60°C'),
          _SettingsRow('PCM Battery Health', 'Stable 98% health', last: true),
        ],
      ),
      const SizedBox(height: 18),
      const _SettingsSection('Self-Service Solutions'),
      _SettingsCard(
        children: [
          for (var index = 0; index < _troubleshootingTopics.length; index++)
            _SettingsRow(
              _troubleshootingTopics[index],
              '›',
              onTap: () => _showHelp(_troubleshootingTopics[index]),
              last: index == _troubleshootingTopics.length - 1,
            ),
        ],
      ),
    ],
  );

  static const _troubleshootingTopics = [
    'Machine Offline / Reconnecting Wi-Fi',
    'Chamber Heating Slower than Usual',
    'PCM Thermal Battery Not Discharging',
    'Syncing Inconsistent Sensor Readings',
  ];

  Future<void> _showHelp(String topic) => showDialog<void>(
    context: context,
    builder: (context) => _SettingsModal(
      title: topic,
      message:
          'Check that your dryer is powered on and connected to the '
          'network. If the issue continues, contact the InSOL8 support team.',
      confirmLabel: 'OK',
    ),
  );

  Widget _guideContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SettingsSection('Quick Start Tutorials'),
      _SettingsCard(
        children: [
          _GuideRow('Step 1: Hardware Setup & QR Registration'),
          _GuideRow('Step 2: Starting Your First Drying Cycle'),
          _GuideRow('Step 3: Managing Branches & Store Managers', last: true),
        ],
      ),
      const SizedBox(height: 18),
      const _SettingsSection('Documentation'),
      _SettingsCard(
        children: [
          for (var index = 0; index < _documentation.length; index++)
            _GuideRow(
              _documentation[index],
              last: index == _documentation.length - 1,
            ),
        ],
      ),
      const SizedBox(height: 18),
      const _SettingsSection('Offline Resources'),
      const _SettingsCard(
        children: [
          _DownloadRow('InSOL8 System Hardware Manual'),
          _DownloadRow('Quick Maintenance Checklist', last: true),
        ],
      ),
    ],
  );

  static const _documentation = [
    'Understanding PCM Thermal Batteries',
    'Fabric Preset Temperature Ranges',
    'Actuator & Exhaust Valve Operation',
    'Reading Analytics & Sensor Trends',
  ];

  Widget _reportIssueContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SettingsSection('Something not working?'),
      _SettingsCard(
        children: [
          _IssueQuestionRow(
            number: 1,
            label: 'What kind of problem is it?',
            value: _issueCategory,
            options: const [
              'Something isn’t working',
              'A number or amount isn’t working',
              'The app is slow or stuck',
              'I have an idea or request',
              'Something else',
            ],
            onChanged: (value) => setState(() => _issueCategory = value),
          ),
          _IssueQuestionRow(
            number: 2,
            label: 'Where did it happen?',
            value: _issueArea,
            options: const [
              'Dashboard',
              'Devices',
              'Analytics',
              'Settings',
              'Not sure',
            ],
            onChanged: (value) => setState(() => _issueArea = value),
          ),
          _IssueQuestionRow(
            number: 3,
            label: 'How much is this affecting work?',
            value: _issueImpact,
            options: const [
              'It’s an annoyance',
              'It slows me down',
              'I can’t do work',
            ],
            onChanged: (value) => setState(() => _issueImpact = value),
            last: true,
          ),
        ],
      ),
      const SizedBox(height: 14),
      _SettingsCard(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('4. Tell us more', style: TextStyle(fontSize: 14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              controller: _issueDescriptionController,
              onChanged: (_) => setState(() {}),
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Describe what happened',
                hintStyle: const TextStyle(
                  color: AppColors.fieldHint,
                  fontSize: 12,
                ),
                filled: true,
                fillColor: AppColors.dashboardCard,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.dashboardBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.dashboardBorder,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SettingsCard(
        children: [
          _SettingsRow(
            '5. Add a photo or screenshot (optional)',
            '›',
            last: true,
            onTap: () => _message(
              'Photo attachments will be available when report uploads are connected.',
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: _canSubmitIssue ? _submitIssue : null,
          child: const Text('Submit Report'),
        ),
      ),
    ],
  );

  bool get _canSubmitIssue =>
      _issueCategory != null &&
      _issueArea != null &&
      _issueImpact != null &&
      _issueDescriptionController.text.trim().isNotEmpty;

  Future<void> _submitIssue() async {
    await showDialog<void>(
      context: context,
      builder: (context) => const _SettingsModal(
        title: 'Report Submitted',
        message: 'Thank you for helping us improve InSOL8. Report submission will be connected to support.',
        confirmLabel: 'OK',
      ),
    );
  }

  Widget _aboutUsContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SettingsSection('Application Info'),
      const _SettingsCard(
        children: [
          _SettingsRow('App version', 'v1.2.0 (Build 420)'),
          _SettingsRow('Firmware compatibility', 'v2.4.1'),
          _SettingsRow(
            'Check for updates',
            'Up to date',
            showChevron: true,
            last: true,
          ),
        ],
      ),
      const SizedBox(height: 18),
      const _SettingsSection('Developer & Organization'),
      _SettingsCard(
        children: [
          const _SettingsRow('Developed by', 'Nexovyre Technologies'),
          _SettingsRow(
            'Website',
            'nexovyre.technologies.com',
            showChevron: true,
            onTap: () => _message('Website link will be available soon.'),
          ),
          _SettingsRow(
            'Contact email',
            'support.nexovyre@gmail.com',
            showChevron: true,
            onTap: () => _message('Email support.nexovyre@gmail.com.'),
            last: true,
          ),
        ],
      ),
      const SizedBox(height: 18),
      const _SettingsSection('Legal'),
      _SettingsCard(
        children: [
          _SettingsRow(
            'Terms of Service',
            '›',
            onTap: () => _openLegalDocument(LegalDocuments.terms),
          ),
          _SettingsRow(
            'Privacy Policy',
            '›',
            onTap: () => _openLegalDocument(LegalDocuments.privacy),
            last: true,
          ),
        ],
      ),
    ],
  );

  Future<void> _openLegalDocument(LegalDocument document) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LegalDocumentPage(document: document),
        ),
      );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.sectionLabel,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A35170F),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow(
    this.label,
    this.value, {
    this.onTap,
    this.last = false,
    this.showChevron = false,
  });
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool last;
  final bool showChevron;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 14)),
                ),
                if (value == '›' && onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.sectionLabel,
                  )
                else ...[
                  Expanded(
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.fieldHint,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (showChevron) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.sectionLabel,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
      if (!last) const Divider(height: 1, indent: 12, endIndent: 12),
    ],
  );
}

class _SettingsThemeRow extends StatelessWidget {
  const _SettingsThemeRow({required this.value, required this.onSelected});

  final String value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    onSelected: onSelected,
    color: AppColors.dashboardCard,
    elevation: 8,
    constraints: const BoxConstraints(minWidth: 160, maxWidth: 160),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    itemBuilder: (context) => [
      for (final option in ['Light', 'Dark', 'System'])
        PopupMenuItem<String>(
          value: option,
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(
                      color: AppColors.fieldHint,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (option == value)
                  const Icon(Icons.check, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ),
    ],
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Expanded(
              child: Text('Theme', style: TextStyle(fontSize: 14)),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.fieldHint,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.sectionLabel,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.last = false,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 48,
        child: SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Text(label, style: const TextStyle(fontSize: 13)),
          value: value,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.dashboardIconBackground,
          onChanged: onChanged,
        ),
      ),
      if (!last) const Divider(height: 1, indent: 12, endIndent: 12),
    ],
  );
}

class _FaqRow extends StatefulWidget {
  const _FaqRow({required this.question, this.last = false});
  final String question;
  final bool last;

  @override
  State<_FaqRow> createState() => _FaqRowState();
}

class _FaqRowState extends State<_FaqRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '“${widget.question}”',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: AppColors.sectionLabel,
              ),
            ],
          ),
        ),
      ),
      if (_expanded)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Text(
            _faqAnswer(widget.question),
            style: const TextStyle(
              color: AppColors.fieldHint,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      if (!widget.last) const Divider(height: 1, indent: 12, endIndent: 12),
    ],
  );

  String _faqAnswer(String question) {
    if (question.contains('Battery / PCM')) {
      return 'This percentage estimates the thermal energy stored in the PCM battery.';
    }
    if (question.contains('Offline')) {
      return 'Check the dryer power and Wi-Fi connection, then allow the device a moment to reconnect.';
    }
    if (question.contains('difference between Basic')) {
      return 'Basic is for a single laundry shop. Org supports multiple branches and managers.';
    }
    if (question.contains('cancel my plan')) {
      return 'Open Settings, choose Billing Information, then select Cancel subscription.';
    }
    return 'Open the relevant device, cycle, or branch page in InSOL8 to manage this feature. Contact support if you need help.';
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow(this.label, {this.last = false});
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) => _SettingsRow(
    label,
    '›',
    last: last,
    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This guide will be available for download soon.'),
      ),
    ),
  );
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow(this.label, {this.last = false});
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        dense: true,
        leading: const Icon(
          Icons.picture_as_pdf_outlined,
          color: AppColors.sectionLabel,
        ),
        title: Text(label, style: const TextStyle(fontSize: 13)),
        subtitle: const Text('pdf'),
        trailing: const Icon(
          Icons.download_outlined,
          color: AppColors.sectionLabel,
          size: 18,
        ),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This resource will be available soon.'),
          ),
        ),
      ),
      if (!last) const Divider(height: 1, indent: 12, endIndent: 12),
    ],
  );
}

class _IssueQuestionRow extends StatelessWidget {
  const _IssueQuestionRow({
    required this.number,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.last = false,
  });

  final int number;
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$number. $label',
                  style: const TextStyle(fontSize: 13, color: AppColors.ink),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: onChanged,
                color: AppColors.dashboardCard,
                elevation: 6,
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 240),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.dashboardBorder),
                ),
                itemBuilder: (context) => [
                  for (final option in options)
                    PopupMenuItem<String>(
                      value: option,
                      height: 42,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: const TextStyle(
                                color: AppColors.body,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (option == value)
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 116),
                      child: Text(
                        value ?? 'Select',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: value == null
                              ? AppColors.fieldHint
                              : AppColors.body,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.unfold_more,
                      size: 17,
                      color: AppColors.sectionLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (!last) const Divider(height: 1, indent: 12, endIndent: 12),
    ],
  );
}

class _SettingsModal extends StatelessWidget {
  const _SettingsModal({
    this.title,
    required this.message,
    this.boldText,
    this.cancelLabel,
    required this.confirmLabel,
  });
  final String? title;
  final String message;
  final String? boldText;
  final String? cancelLabel;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.sectionLabel,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text.rich(
            _textSpan(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (cancelLabel != null) ...[
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.fieldHint,
                        backgroundColor: AppColors.dashboardCard,
                        side: const BorderSide(
                          color: AppColors.dashboardBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(cancelLabel!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(confirmLabel),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  TextSpan _textSpan() {
    final bold = boldText;
    if (bold == null || !message.contains(bold)) return TextSpan(text: message);
    final start = message.indexOf(bold);
    return TextSpan(
      children: [
        if (start > 0) TextSpan(text: message.substring(0, start)),
        TextSpan(
          text: bold,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (start + bold.length < message.length)
          TextSpan(text: message.substring(start + bold.length)),
      ],
    );
  }
}
