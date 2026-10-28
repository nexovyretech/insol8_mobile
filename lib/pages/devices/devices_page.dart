import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/pages/devices/device_card.dart';
import 'package:insol8_mobile/pages/devices/device_filter_bar.dart';
import 'package:insol8_mobile/pages/home/dashboard_bottom_navigation.dart';
import 'package:insol8_mobile/pages/onboarding/onboarding_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

/// Displays the signed-in user's dryers and their latest reported status.
class DevicesPage extends StatefulWidget {
  const DevicesPage({
    super.key,
    required this.authRepository,
    required this.deviceRepository,
    required this.onboardingRepository,
    required this.subscriptionRepository,
  });

  final AuthRepository authRepository;
  final DeviceRepository deviceRepository;
  final OnboardingRepository onboardingRepository;
  final SubscriptionRepository subscriptionRepository;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<DeviceData> _devices = const [];
  final List<DeviceData> _registeredDevices = [];
  DeviceFilter _selectedFilter = DeviceFilter.all;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadDevices({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      if (!await widget.authRepository.hasActiveSession()) {
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.getStarted, (_) => false);
        }
        return;
      }
      final planId = await widget.subscriptionRepository.fetchActivePlanId();
      if (planId == SubscriptionPlanIds.organization) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.branches);
        }
        return;
      }
      final devices = await widget.deviceRepository.fetchDevices();
      if (!mounted) return;
      final fetchedIds = devices.map((device) => device.id).toSet();
      final combinedDevices = [
        ...devices,
        ..._registeredDevices.where(
          (device) => !fetchedIds.contains(device.id),
        ),
      ];
      setState(() {
        _devices = combinedDevices;
        _errorMessage = null;
        _isLoading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'We couldn’t load your devices. Check your connection.';
        _isLoading = false;
      });
    }
  }

  Map<DeviceFilter, int> get _filterCounts => {
    DeviceFilter.all: _devices.length,
    DeviceFilter.active: _countFor(DeviceStatus.active),
    DeviceFilter.idle: _countFor(DeviceStatus.idle),
    DeviceFilter.offline: _countFor(DeviceStatus.offline),
  };

  int _countFor(DeviceStatus status) =>
      _devices.where((device) => device.status == status).length;

  List<DeviceData> get _visibleDevices {
    return _devices
        .where((device) {
          final matchesFilter =
              _selectedFilter == DeviceFilter.all ||
              device.status.name == _selectedFilter.name;
          return matchesFilter;
        })
        .toList(growable: false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onNavigationSelected(int index) {
    if (index == 1) return;
    if (index == 0) {
      Navigator.of(context)
          .popUntil((route) => route.settings.name == AppRoutes.home);
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushNamed(AppRoutes.analytics);
      return;
    }
    if (index == 3) {
      Navigator.of(context).pushNamed(AppRoutes.settings);
      return;
    }
    _showMessage('This section will be available when its data is connected.');
  }

  void _openSearch() => Navigator.of(context).pushNamed(AppRoutes.deviceSearch);

  Future<void> _addDevice() async {
    final setups = await openDeviceRegistrationFlow(
      context,
      repository: widget.onboardingRepository,
    );
    if (setups != null && setups.isNotEmpty && mounted) {
      setState(() {
        for (final setup in setups) {
          if (_registeredDevices.any(
            (device) => device.id == setup.deviceCode,
          )) {
            continue;
          }
          _registeredDevices.add(
            DeviceData(
              id: setup.deviceCode,
              name: setup.deviceName,
              status: DeviceStatus.offline,
              temperatureCelsius: null,
              batteryPercent: null,
              cycleDuration: '—',
              lastUpdated: 'Just now',
            ),
          );
        }
      });
      await _loadDevices(showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.pageHeaderTop),
              _DevicesHeader(
                onAddDevice: _addDevice,
                onSearchDevices: _openSearch,
              ),
              const SizedBox(height: AppSpacing.contentGap),
              DeviceFilterBar(
                selectedFilter: _selectedFilter,
                counts: _filterCounts,
                onSelected: (filter) =>
                    setState(() => _selectedFilter = filter),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildDeviceContent()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNavigation(
        selectedIndex: 1,
        organizationPlan: false,
        onSelect: _onNavigationSelected,
      ),
    ),
  );

  Widget _buildDeviceContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return _DeviceLoadError(message: _errorMessage!, onRetry: _loadDevices);
    }

    final devices = _visibleDevices;
    if (devices.isEmpty) {
      return _EmptyDevicesState(filter: _selectedFilter, isSearching: false);
    }

    return RefreshIndicator(
      onRefresh: () => _loadDevices(showLoading: false),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 18),
        itemCount: devices.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => DeviceCard(
          device: devices[index],
          onTap: () => _openDeviceDetails(devices[index]),
        ),
      ),
    );
  }

  Future<void> _openDeviceDetails(DeviceData device) async {
    final result = await Navigator.of(context)
        .pushNamed<Object?>(AppRoutes.deviceDetails, arguments: device);
    if (result == true && mounted) {
      setState(() {
        _devices = _devices.where((item) => item.id != device.id).toList();
        _registeredDevices.removeWhere((item) => item.id == device.id);
      });
    } else if (result is DeviceData && mounted) {
      setState(() {
        _devices = _devices
            .map((item) => item.id == result.id ? result : item)
            .toList(growable: false);
        for (var index = 0; index < _registeredDevices.length; index++) {
          if (_registeredDevices[index].id == result.id) {
            _registeredDevices[index] = result;
          }
        }
      });
    }
  }
}

class _DevicesHeader extends StatelessWidget {
  const _DevicesHeader({
    required this.onAddDevice,
    required this.onSearchDevices,
  });

  final VoidCallback onAddDevice;
  final VoidCallback onSearchDevices;

  @override
  Widget build(BuildContext context) => AppPageHeader(
    title: 'Devices',
    actions: [
      IconButton(
        onPressed: onAddDevice,
        tooltip: 'Add device',
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.add_circle_outline),
      ),
      IconButton(
        onPressed: onSearchDevices,
        tooltip: 'Search devices',
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.search),
      ),
    ],
  );
}

class _EmptyDevicesState extends StatelessWidget {
  const _EmptyDevicesState({required this.filter, required this.isSearching});

  final DeviceFilter filter;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final isOfflineFilter = filter == DeviceFilter.offline && !isSearching;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOfflineFilter
                  ? Icons.cloud_off_outlined
                  : Icons.devices_other_outlined,
              color: AppColors.sectionLabel,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              isOfflineFilter ? 'No offline devices.' : 'No devices found.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isOfflineFilter
                  ? "When you have offline devices, you'll see it here."
                  : 'Try changing your filter or search.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.fieldHint, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceLoadError extends StatelessWidget {
  const _DeviceLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
