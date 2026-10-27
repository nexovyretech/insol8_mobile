import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:insol8_mobile/models/dashboard_data.dart';
import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/device_management_data.dart';
import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/pages/home/dashboard_widgets.dart';
import 'package:insol8_mobile/pages/devices/device_management_page.dart';
import 'package:insol8_mobile/pages/onboarding/onboarding_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/dashboard_repository.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';

/// Signed-in landing screen; dashboard metrics are loaded through a repository
/// so the UI does not depend on a particular API response or transport.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.authRepository,
    required this.dashboardRepository,
    required this.deviceRepository,
    required this.onboardingRepository,
  });

  final AuthRepository authRepository;
  final DashboardRepository dashboardRepository;
  final DeviceRepository deviceRepository;
  final OnboardingRepository onboardingRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserProfile? _profile;
  DashboardData? _dashboard;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    setState(() {
      if (showLoading) _isLoading = true;
      _errorMessage = null;
    });
    if (!await widget.authRepository.hasActiveSession()) {
      _leave();
      return;
    }
    try {
      final profile = await widget.authRepository.loadProfile();
      final dashboard = await widget.dashboardRepository.fetchDashboard();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _dashboard = dashboard;
        _isLoading = false;
      });
    } on AuthFailure catch (error) {
      _showLoadError(error.message);
    } on Exception {
      _showLoadError('We couldn’t load your dashboard. Check your connection.');
    }
  }

  void _showLoadError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    await widget.authRepository.signOut();
    _leave();
  }

  void _leave() {
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.getStarted, (_) => false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openAttentionDevice(DashboardAttentionItem item) async {
    try {
      final devices = await widget.deviceRepository.fetchDevices();
      if (!mounted) return;
      DeviceData? device;
      for (final candidate in devices) {
        if (candidate.id == item.deviceId) {
          device = candidate;
          break;
        }
      }
      if (device == null) {
        _showMessage('${item.deviceName} is not available right now.');
        return;
      }
      final result = await Navigator.of(context).push<DeviceManagementResult>(
        MaterialPageRoute<DeviceManagementResult>(
          builder: (_) => DeviceManagementPage(
            device: device!,
            deviceRepository: widget.deviceRepository,
          ),
        ),
      );
      if (result?.unregistered == true && mounted) {
        await _load(showLoading: false);
      }
    } on Exception {
      if (mounted) {
        _showMessage('Could not open ${item.deviceName}. Try again.');
      }
    }
  }

  Future<void> _addDevice() async {
    final setups = await openDeviceRegistrationFlow(
      context,
      repository: widget.onboardingRepository,
    );
    if (!mounted || setups == null || setups.isEmpty) return;
    await _load(showLoading: false);
    if (mounted) {
      _showMessage(
        setups.length == 1
            ? 'Device added successfully.'
            : '${setups.length} devices added successfully.',
      );
    }
  }

  Future<void> _showSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.logout, color: AppColors.primary),
          title: const Text('Sign out'),
          onTap: () {
            Navigator.pop(context);
            _signOut();
          },
        ),
      ),
    );
  }

  void _onNavigationSelected(int index) {
    if (index == 0) return;
    if (index == 1) {
      Navigator.of(context).pushNamed(AppRoutes.devices);
      return;
    }
    if (index == 3) {
      _showSettings();
      return;
    }
    _showMessage('This section will be available when its data is connected.');
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final dashboard = _dashboard;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            child: Column(
              children: [
                const SizedBox(height: 18),
                DashboardHeader(
                  firstName: profile?.firstName ?? 'there',
                  onNotifications: () => _showMessage(
                    'Notifications will appear here when connected.',
                  ),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null ||
                            profile == null ||
                            dashboard == null
                      ? _DashboardError(
                          message:
                              _errorMessage ??
                              'We couldn’t load your dashboard.',
                          onRetry: _load,
                        )
                      : RefreshIndicator(
                          onRefresh: () => _load(showLoading: false),
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 20),
                            children: [
                              DashboardMetricGrid(data: dashboard),
                              const SizedBox(height: 24),
                              const DashboardSectionTitle('Needs Attention'),
                              DashboardAttentionList(
                                items: dashboard.attentionItems,
                                onTapItem: _openAttentionDevice,
                              ),
                              const SizedBox(height: 22),
                              const DashboardSectionTitle('Quick Buttons'),
                              DashboardQuickActions(
                                onAddDevice: _addDevice,
                                onReportIssue: () => _showMessage(
                                  'Issue reporting will be connected to the support service.',
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _isLoading || _errorMessage != null
            ? null
            : DashboardBottomNavigation(onSelect: _onNavigationSelected),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.error),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
