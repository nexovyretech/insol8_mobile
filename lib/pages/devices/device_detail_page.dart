import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/device_detail_data.dart';
import 'package:insol8_mobile/pages/devices/device_cycle_control_panel.dart';
import 'package:insol8_mobile/pages/devices/device_history_section.dart';
import 'package:insol8_mobile/pages/devices/device_summary_card.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/services/live_telemetry.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';

class DeviceDetailPage extends StatefulWidget {
  const DeviceDetailPage({
    super.key,
    required this.device,
    required this.authRepository,
    required this.deviceRepository,
    this.liveTelemetry,
  });

  final DeviceData device;
  final AuthRepository authRepository;
  final DeviceRepository deviceRepository;

  /// Pushes the dryer's readings while the page is open; null shows only the
  /// values loaded from [deviceRepository].
  final LiveTelemetrySource? liveTelemetry;

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  late final String _deviceName = widget.device.name;
  DeviceDetailData? _details;
  DeviceHistoryPeriod _selectedPeriod = DeviceHistoryPeriod.pastMonths;
  String? _fabricType;
  int _runtimeMinutes = 0;
  DeviceOperatingMode _operatingMode = DeviceOperatingMode.automatic;
  String? _errorMessage;
  bool _isLoading = true;
  StreamSubscription<LiveTelemetryBatch>? _liveUpdates;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _liveUpdates?.cancel();
    super.dispose();
  }

  // Live updates are best effort: if the connection fails the page keeps the
  // last loaded values.
  void _watchLiveTelemetry() {
    final live = widget.liveTelemetry;
    if (live == null || _liveUpdates != null) return;
    _liveUpdates = live
        .watch(widget.device.id)
        .listen(_applyLiveBatch, onError: (Object _) {});
  }

  void _applyLiveBatch(LiveTelemetryBatch batch) {
    final details = _details;
    if (!mounted || details == null) return;
    // A cycle started or ended since the page loaded: reload its details.
    if (batch.sessionId != details.sessionId) {
      _loadDetails();
      return;
    }
    final temperature = batch.latestChamberTemperature;
    if (temperature == null) return;
    setState(() => _details = details.withChamberTemperature(temperature));
  }

  Future<void> _loadDetails() async {
    try {
      if (!await widget.authRepository.hasActiveSession()) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      final details = await widget.deviceRepository.fetchDeviceDetails(
        widget.device.id,
      );
      if (!mounted) return;
      setState(() {
        _details = details;
        _fabricType = details.fabricType;
        _runtimeMinutes = details.runtimeMinutes;
        _operatingMode = details.operatingMode;
        _isLoading = false;
      });
      _watchLiveTelemetry();
    } on Exception {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'We couldn’t load this device. Check your connection.';
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateCycleSettings({
    String? fabricType,
    int? runtimeMinutes,
  }) async {
    setState(() {
      if (fabricType != null) _fabricType = fabricType;
      if (runtimeMinutes != null) _runtimeMinutes = runtimeMinutes;
    });
    try {
      await widget.deviceRepository.updateCycleSettings(
        deviceId: widget.device.id,
        settings: DeviceCycleSettings(
          fabricType: _fabricType,
          runtimeMinutes: _runtimeMinutes,
        ),
      );
    } on Exception {
      if (mounted) _showMessage('Couldn’t save the cycle settings. Try again.');
    }
  }

  Future<void> _toggleOperatingMode() async {
    final previousMode = _operatingMode;
    final nextMode = previousMode == DeviceOperatingMode.automatic
        ? DeviceOperatingMode.manual
        : DeviceOperatingMode.automatic;
    setState(() => _operatingMode = nextMode);
    try {
      await widget.deviceRepository.updateOperatingMode(
        deviceId: widget.device.id,
        mode: nextMode,
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _operatingMode = previousMode);
      _showMessage('Couldn’t change the device mode. Try again.');
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
        child: Column(
          children: [
            _DeviceDetailHeader(
              name: _deviceName,
              onBack: () => Navigator.of(context).pop(
                DeviceData(
                  id: widget.device.id,
                  name: _deviceName,
                  status: widget.device.status,
                  temperatureCelsius: widget.device.temperatureCelsius,
                  batteryPercent: widget.device.batteryPercent,
                  cycleDuration: widget.device.cycleDuration,
                  lastUpdated: widget.device.lastUpdated,
                ),
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: _details == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  10,
                  AppSpacing.pageHorizontal,
                  12,
                ),
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _toggleOperatingMode,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Text(
                      _operatingMode == DeviceOperatingMode.automatic
                          ? 'Switch to Manual'
                          : 'Switch to Auto',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    ),
  );

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null || _details == null) {
      return _DeviceDetailError(
        message: _errorMessage ?? 'We couldn’t load this device.',
        onRetry: _loadDetails,
      );
    }

    final details = _details!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        12,
        AppSpacing.pageHorizontal,
        18,
      ),
      children: [
        DeviceSummaryCard(details: details),
        const SizedBox(height: 16),
        DeviceCycleControlPanel(
          fabricType: _fabricType,
          runtimeMinutes: _runtimeMinutes,
          onFabricChanged: (fabricType) =>
              _updateCycleSettings(fabricType: fabricType),
          onRuntimeChanged: (minutes) =>
              _updateCycleSettings(runtimeMinutes: minutes),
        ),
        const SizedBox(height: 16),
        DeviceHistorySection(
          records: details.history,
          selectedPeriod: _selectedPeriod,
          onPeriodSelected: (period) =>
              setState(() => _selectedPeriod = period),
        ),
      ],
    );
  }
}

class _DeviceDetailHeader extends StatelessWidget {
  const _DeviceDetailHeader({required this.name, required this.onBack});

  final String name;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          tooltip: 'Back to devices',
          icon: const Icon(Icons.chevron_left, size: 28),
        ),
        Expanded(
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/device_management_tune.svg',
              width: 18,
              height: 18,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DeviceDetailError extends StatelessWidget {
  const _DeviceDetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
