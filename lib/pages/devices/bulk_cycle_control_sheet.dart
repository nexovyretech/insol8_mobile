import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/device_detail_data.dart';
import 'package:insol8_mobile/pages/auth/login_widgets.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';

/// Opens shared multi-device cycle controls for Basic and Organization plans.
Future<BulkCycleResult?> showBulkCycleControlSheet({
  required BuildContext context,
  required List<DeviceData> devices,
  required DeviceRepository repository,
}) => showModalBottomSheet<BulkCycleResult>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) =>
      _BulkCycleControlSheet(devices: devices, repository: repository),
);

class BulkCycleResult {
  const BulkCycleResult({
    required this.started,
    required this.stopped,
    required this.failed,
  });

  final int started;
  final int stopped;
  final int failed;
}

class _BulkCycleControlSheet extends StatefulWidget {
  const _BulkCycleControlSheet({
    required this.devices,
    required this.repository,
  });

  final List<DeviceData> devices;
  final DeviceRepository repository;

  @override
  State<_BulkCycleControlSheet> createState() => _BulkCycleControlSheetState();
}

class _BulkCycleControlSheetState extends State<_BulkCycleControlSheet> {
  static const _fabricTypes = ['Cotton', 'Delicates', 'Synthetics', 'Heavy'];
  final Set<String> _selectedIds = {};
  String _fabricType = _fabricTypes.first;
  int _runtimeMinutes = 30;
  final _loadController = TextEditingController();
  bool _isWorking = false;

  @override
  void dispose() {
    _loadController.dispose();
    super.dispose();
  }

  /// The load entered in kg; null while empty, zero or unreadable.
  double? get _loadKg {
    final value = double.tryParse(_loadController.text);
    return value == null || value <= 0 ? null : value;
  }

  // The load is checked against the dryers that will start; before any are
  // selected, against every dryer, so the note shows the smallest limit.
  List<DeviceData> get _loadDevices {
    final starting = _selectedDevices
        .where((device) => device.status == DeviceStatus.idle)
        .toList(growable: false);
    return starting.isNotEmpty ? starting : widget.devices;
  }

  double get _loadLimitKg => _loadDevices.isEmpty
      ? DeviceData.defaultMaxLoadKg
      : _loadDevices
            .map((device) => device.maxLoadKg)
            .reduce((a, b) => a < b ? a : b);

  bool get _loadOverLimit {
    final load = _loadKg;
    return load != null && load > _loadLimitKg;
  }

  /// Selected dryers that cannot hold the entered load.
  List<String> get _overloadedNames {
    final load = _loadKg;
    if (load == null) return const [];
    return [
      for (final device in _selectedDevices)
        if (device.status == DeviceStatus.idle && load > device.maxLoadKg)
          device.name,
    ];
  }

  List<DeviceData> get _selectedDevices => widget.devices
      .where((device) => _selectedIds.contains(device.id))
      .toList(growable: false);

  Set<String> get _selectableIds => widget.devices
      .where((device) => device.status != DeviceStatus.offline)
      .map((device) => device.id)
      .toSet();

  int get _startCount => _selectedDevices
      .where((device) => device.status == DeviceStatus.idle)
      .length;

  int get _stopCount => _selectedDevices
      .where((device) => device.status == DeviceStatus.active)
      .length;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FractionallySizedBox(
          heightFactor: .88,
          child: Material(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.disabled,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // The settings scroll with the dryer list so the sheet still
                // fits when the keyboard shrinks it.
                Expanded(
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageHorizontal,
                          18,
                          AppSpacing.pageHorizontal,
                          8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Drying Jobs',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose a fabric, runtime and load weight, select dryers, then start or stop jobs together.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.fieldHint,
                                      height: 1.35,
                                    ),
                              ),
                              const SizedBox(height: 14),
                              _CycleSettings(
                                fabricType: _fabricType,
                                runtimeMinutes: _runtimeMinutes,
                                onFabricChanged: (value) =>
                                    setState(() => _fabricType = value),
                                onRuntimeChanged: (value) =>
                                    setState(() => _runtimeMinutes = value),
                              ),
                              const SizedBox(height: 14),
                              _LoadWeightField(
                                controller: _loadController,
                                overLimit: _loadOverLimit,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 8),
                              _LoadLimitNote(
                                limitKg: _loadLimitKg,
                                overLimit: _loadOverLimit,
                                overloadedNames: _overloadedNames,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Select devices',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: AppColors.sectionLabel,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        _isWorking || _selectableIds.isEmpty
                                        ? null
                                        : _toggleAll,
                                    child: Text(
                                      _selectableIds.isNotEmpty &&
                                              _selectableIds.every(
                                                _selectedIds.contains,
                                              )
                                          ? 'Clear'
                                          : 'Select all',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.devices.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.devices_other_outlined,
                                    color: AppColors.sectionLabel,
                                    size: 42,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No dryers connected yet',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Add a dryer first. Once it appears online, '
                                    'you can select it here to set its fabric '
                                    'and runtime, then start or stop jobs.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.fieldHint,
                                          height: 1.4,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pageHorizontal,
                            0,
                            AppSpacing.pageHorizontal,
                            12,
                          ),
                          sliver: SliverList.separated(
                            itemCount: widget.devices.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 7),
                            itemBuilder: (context, index) =>
                                _DeviceSelectionTile(
                                  device: widget.devices[index],
                                  selected: _selectedIds.contains(
                                    widget.devices[index].id,
                                  ),
                                  enabled:
                                      !_isWorking &&
                                      widget.devices[index].status !=
                                          DeviceStatus.offline,
                                  onChanged: (selected) => setState(() {
                                    if (selected) {
                                      _selectedIds.add(
                                        widget.devices[index].id,
                                      );
                                    } else {
                                      _selectedIds.remove(
                                        widget.devices[index].id,
                                      );
                                    }
                                  }),
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    10,
                    AppSpacing.pageHorizontal,
                    16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: _isWorking
                              ? 'Working…'
                              : 'Start ($_startCount)',
                          icon: Icons.play_arrow_rounded,
                          // A job needs a load weight within every
                          // starting dryer's limit.
                          enabled:
                              !_isWorking &&
                              _startCount > 0 &&
                              _runtimeMinutes > 0 &&
                              _loadKg != null &&
                              !_loadOverLimit,
                          onPressed: () => _run(start: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          label: _isWorking ? 'Working…' : 'Stop ($_stopCount)',
                          icon: Icons.stop_rounded,
                          enabled: !_isWorking && _stopCount > 0,
                          onPressed: () => _run(start: false),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleAll() {
    setState(() {
      final selectable = _selectableIds;
      if (_selectedIds.containsAll(selectable)) {
        _selectedIds.removeAll(selectable);
      } else {
        _selectedIds.addAll(selectable);
      }
    });
  }

  Future<void> _run({required bool start}) async {
    final targets = _selectedDevices
        .where(
          (device) => start
              ? device.status == DeviceStatus.idle
              : device.status == DeviceStatus.active,
        )
        .toList(growable: false);
    if (targets.isEmpty) return;

    setState(() => _isWorking = true);
    final outcomes = await Future.wait(
      targets.map((device) async {
        try {
          if (start) {
            await widget.repository.startDryingCycle(
              deviceId: device.id,
              settings: DeviceCycleSettings(
                fabricType: _fabricType,
                runtimeMinutes: _runtimeMinutes,
                loadKg: _loadKg,
              ),
            );
          } else {
            await widget.repository.stopDryingCycle(deviceId: device.id);
          }
          return true;
        } on Exception {
          return false;
        }
      }),
    );
    if (!mounted) return;
    final succeeded = outcomes.where((success) => success).length;
    final failed = outcomes.length - succeeded;
    Navigator.of(context).pop(
      BulkCycleResult(
        started: start ? succeeded : 0,
        stopped: start ? 0 : succeeded,
        failed: failed,
      ),
    );
  }
}

class _CycleSettings extends StatelessWidget {
  const _CycleSettings({
    required this.fabricType,
    required this.runtimeMinutes,
    required this.onFabricChanged,
    required this.onRuntimeChanged,
  });

  final String fabricType;
  final int runtimeMinutes;
  final ValueChanged<String> onFabricChanged;
  final ValueChanged<int> onRuntimeChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.dashboardCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.dashboardBorder),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Fabric Type',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.ink, fontSize: 13),
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: fabricType,
                  alignment: AlignmentDirectional.centerEnd,
                  dropdownColor: AppColors.dashboardCard,
                  borderRadius: BorderRadius.circular(18),
                  icon: const Icon(
                    Icons.unfold_more,
                    color: AppColors.sectionLabel,
                    size: 18,
                  ),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.fieldHint, fontSize: 13),
                  items: [
                    for (final value
                        in _BulkCycleControlSheetState._fabricTypes)
                      DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) {
                    if (value != null) onFabricChanged(value);
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 14, endIndent: 14),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Runtime Selector',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.ink, fontSize: 13),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: runtimeMinutes <= 5
                    ? null
                    : () => onRuntimeChanged(runtimeMinutes - 5),
                icon: const Icon(Icons.remove, size: 17),
                color: AppColors.sectionLabel,
                disabledColor: AppColors.disabled,
              ),
              Text(
                '${runtimeMinutes.toString().padLeft(2, '0')} mins',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.fieldHint, fontSize: 12),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: runtimeMinutes >= 240
                    ? null
                    : () => onRuntimeChanged(runtimeMinutes + 5),
                icon: const Icon(Icons.add, size: 17),
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Load weight entry styled like the login fields: label above, filled
/// rounded field with a kg unit on the right.
class _LoadWeightField extends StatelessWidget {
  const _LoadWeightField({
    required this.controller,
    required this.overLimit,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool overLimit;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.error),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LoginFieldLabel('Load Weight'),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('load-weight'),
          controller: controller,
          onChanged: onChanged,
          // Kilograms only: digits with up to two decimals.
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?')),
          ],
          style: overLimit ? const TextStyle(color: AppColors.error) : null,
          decoration: InputDecoration(
            hintText: 'Enter load weight e.g. 3.4',
            suffixText: 'kg',
            suffixStyle: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.fieldHint),
            enabledBorder: overLimit ? errorBorder : null,
            focusedBorder: overLimit
                ? errorBorder.copyWith(
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 1.5,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// The dryers' load limit, in red when the entered load exceeds it.
class _LoadLimitNote extends StatelessWidget {
  const _LoadLimitNote({
    required this.limitKg,
    required this.overLimit,
    required this.overloadedNames,
  });

  final double limitKg;
  final bool overLimit;
  final List<String> overloadedNames;

  @override
  Widget build(BuildContext context) {
    final limit = '${_kg(limitKg)} kg';
    final message = !overLimit
        ? 'Up to $limit per dryer.'
        : overloadedNames.isEmpty
        ? 'Over the $limit limit. Reduce the load to start.'
        : 'Over the $limit limit of ${overloadedNames.join(', ')}. '
              'Reduce the load to start.';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          overLimit ? Icons.error_outline : Icons.info_outline,
          size: 15,
          color: overLimit ? AppColors.error : AppColors.fieldHint,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: overLimit ? AppColors.error : AppColors.fieldHint,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  static String _kg(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

class _DeviceSelectionTile extends StatelessWidget {
  const _DeviceSelectionTile({
    required this.device,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final DeviceData device;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (device.status) {
      DeviceStatus.active => AppColors.primary,
      DeviceStatus.idle => AppColors.sectionLabel,
      DeviceStatus.offline => AppColors.disabled,
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onChanged(!selected) : null,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.dashboardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: enabled
                            ? AppColors.primary
                            : AppColors.fieldHint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      device.status == DeviceStatus.active
                          ? 'Running · ${device.cycleDuration}'
                          : device.status == DeviceStatus.idle
                          ? 'Ready to start'
                          : 'Offline',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.fieldHint, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.circle, size: 8, color: statusColor),
              Checkbox(
                value: selected,
                onChanged: enabled
                    ? (value) => onChanged(value ?? false)
                    : null,
                activeColor: AppColors.primary,
                side: const BorderSide(color: AppColors.sectionLabel),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 19),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.disabled,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}
