import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/device_management_data.dart';
import 'package:insol8_mobile/pages/devices/branch_search_page.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({
    super.key,
    required this.device,
    required this.deviceRepository,
  });

  final DeviceData device;
  final DeviceRepository deviceRepository;

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  DeviceManagementData? _details;
  late String _deviceName = widget.device.name;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final details = await widget.deviceRepository.fetchManagementDetails(
        widget.device,
      );
      if (!mounted) return;
      setState(() {
        _details = details;
        _deviceName = details.device.name;
        _isLoading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'We couldn’t load device management details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _renameDevice() async {
    final controller = TextEditingController(text: _deviceName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Update Device Name',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.sectionLabel,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Property update description',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.body, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Device name'),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.fieldHint,
                    side: const BorderSide(color: AppColors.dashboardBorder),
                    backgroundColor: AppColors.dashboardCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isNotEmpty) Navigator.pop(dialogContext, value);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;

    try {
      await widget.deviceRepository.updateDeviceName(
        deviceId: widget.device.id,
        name: name,
      );
      if (!mounted) return;
      setState(() => _deviceName = name);
      _showMessage('Device name updated.');
    } on Exception {
      if (mounted) _showMessage('Couldn’t update the device name. Try again.');
    }
  }

  Future<void> _changeBranch() async {
    final details = _details;
    if (details == null) return;
    final branch = await Navigator.of(context).push<String>(
      PageRouteBuilder<String>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => BranchSearchPage(
          branches: details.availableBranches,
        ),
      ),
    );
    if (branch == null || !mounted) return;
    try {
      await widget.deviceRepository.updateDeviceBranch(
        deviceId: widget.device.id,
        branchName: branch,
      );
      if (!mounted) return;
      setState(() {
        _details = DeviceManagementData(
          device: _details!.device,
          serialId: _details!.serialId,
          modelType: _details!.modelType,
          firmwareVersion: _details!.firmwareVersion,
          status: _details!.status,
          pcmReservePercent: _details!.pcmReservePercent,
          currentBranch: branch,
          availableBranches: _details!.availableBranches,
        );
      });
    } on Exception {
      if (mounted) _showMessage('Couldn’t update the branch. Try again.');
    }
  }

  Future<void> _unregisterDevice() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            title: const Text('Unregister Device?'),
            content: Text(
              'This disconnects $_deviceName from your laundry system. Active cycles will stop, and device logs will be archived.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Unregister Device'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    try {
      await widget.deviceRepository.unregisterDevice(widget.device.id);
      if (!mounted) return;
      Navigator.pop(
        context,
        DeviceManagementResult(deviceName: _deviceName, unregistered: true),
      );
    } on Exception {
      if (mounted) _showMessage('Couldn’t unregister this device. Try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
            _ManagementHeader(
              onBack: () =>
                  Navigator.of(context)
                      .pop(DeviceManagementResult(deviceName: _deviceName)),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    ),
  );

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null || _details == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage ?? 'Couldn’t load this device.'),
            TextButton(onPressed: _loadDetails, child: const Text('Try again')),
          ],
        ),
      );
    }

    final details = _details!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        12,
        AppSpacing.pageHorizontal,
        28,
      ),
      children: [
        _ManagementSection(
          title: 'Device Details',
          children: [
            _ManagementRow(
              label: 'Device Name',
              value: _deviceName,
              onTap: _renameDevice,
            ),
            _ManagementRow(
              label: 'Device Serial / ID',
              value: details.serialId,
            ),
            _ManagementRow(label: 'Model Type', value: details.modelType),
            _ManagementRow(
              label: 'Firmware',
              value: details.firmwareVersion,
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ManagementSection(
          title: 'Device Health',
          children: [
            _ManagementRow(
              label: 'Status',
              value: _statusLabel(details.status),
              valueColor: details.status == DeviceStatus.active
                  ? AppColors.primary
                  : AppColors.fieldHint,
            ),
            _ManagementRow(
              label: 'PCM Reserve',
              value: '${details.pcmReservePercent}% Charged',
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ManagementSection(
          title: 'Branch Assignment',
          children: [
            _ManagementRow(
              label: 'Current Branch',
              value: details.currentBranch,
              onTap: _changeBranch,
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Danger Zone'),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _unregisterDevice,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Unregister Device',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Disconnects this dryer from your laundry system. Active cycles will stop, and device logs will be archived.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.fieldHint, fontSize: 11),
        ),
      ],
    );
  }

  String _statusLabel(DeviceStatus status) => switch (status) {
    DeviceStatus.active => 'Active',
    DeviceStatus.idle => 'Idle',
    DeviceStatus.offline => 'Offline',
  };
}

class _ManagementHeader extends StatelessWidget {
  const _ManagementHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          tooltip: 'Back',
          icon: const Icon(Icons.chevron_left, size: 28),
        ),
        Expanded(
          child: Text(
            'Device Management',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    ),
  );
}

class _ManagementSection extends StatelessWidget {
  const _ManagementSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionLabel(title),
      Container(
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
        child: Column(children: children),
      ),
    ],
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.sectionLabel,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ManagementRow extends StatelessWidget {
  const _ManagementRow({
    required this.label,
    required this.value,
    this.onTap,
    this.valueColor = AppColors.fieldHint,
    this.isLast = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color valueColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.ink, fontSize: 13),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: valueColor, fontSize: 11),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.sectionLabel,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return Column(
      children: [
        if (onTap == null)
          row
        else
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: row,
          ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: Color(0xFFF7F0EC),
          ),
      ],
    );
  }
}
