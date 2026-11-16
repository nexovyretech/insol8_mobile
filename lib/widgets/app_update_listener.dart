import 'package:flutter/material.dart';

import 'package:insol8_mobile/services/app_update_service.dart';
import 'package:insol8_mobile/theme/app_colors.dart';

/// Checks for a newer Android build when the app starts and whenever it
/// returns to the foreground, and shows [AppUpdateDialog] when one exists.
/// Does nothing off Android or in debug builds.
///
/// Sits above every route (MaterialApp.builder), so it also runs on Get
/// Started, login and sign-up: a user who never signs up still gets updates.
/// Optional updates are offered at most every [interval]; a required one is
/// shown again whenever it is closed (for example when the screen behind it
/// changes) and on every return to the app, until the user installs it.
class AppUpdateListener extends StatefulWidget {
  const AppUpdateListener({
    super.key,
    required this.child,
    this.service,
    this.navigatorKey,
    this.interval = const Duration(hours: 6),
  });

  final Widget child;

  /// Defaults to a real [AppUpdateService]; a fake in tests.
  final AppUpdateService? service;

  /// The app's navigator. Required when this widget sits above it (in
  /// MaterialApp.builder), since dialogs need a context below a Navigator.
  final GlobalKey<NavigatorState>? navigatorKey;
  final Duration interval;

  @override
  State<AppUpdateListener> createState() => _AppUpdateListenerState();
}

class _AppUpdateListenerState extends State<AppUpdateListener>
    with WidgetsBindingObserver {
  late final AppUpdateService _service = widget.service ?? AppUpdateService();

  DateTime? _lastCheck;
  bool _dialogOpen = false;

  /// A required update found earlier; checked again on every resume.
  bool _requiredPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  BuildContext? get _dialogContext => widget.navigatorKey == null
      ? context
      : widget.navigatorKey!.currentContext;

  Future<void> _check() async {
    final last = _lastCheck;
    if (_dialogOpen) return;
    if (!_requiredPending &&
        last != null &&
        DateTime.now().difference(last) < widget.interval) {
      return;
    }
    _lastCheck = DateTime.now();
    final AppUpdate? update;
    try {
      update = await _service.check();
    } on Exception {
      // Offline or the API is down: try again on the next check.
      _lastCheck = null;
      return;
    }
    _requiredPending = update?.forced ?? false;
    if (update == null || !mounted) return;
    await _show(update);
  }

  Future<void> _show(AppUpdate update) async {
    _dialogOpen = true;
    try {
      // A required update has no "Later", but the dialog can still be closed
      // underneath it (a screen replacing the route), so show it again.
      for (var attempt = 0; mounted && attempt < 50; attempt++) {
        final dialogContext = _dialogContext;
        if (dialogContext != null && dialogContext.mounted) {
          await showAppUpdateDialog(dialogContext, update, _service);
          if (!update.forced) return;
        }
        // Let the navigation that closed it (or the first frame) finish.
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Shows [AppUpdateDialog]; a forced update cannot be dismissed by tapping
/// outside it. Used by [AppUpdateListener] and Settings > Check for updates.
Future<void> showAppUpdateDialog(
  BuildContext context,
  AppUpdate update,
  AppUpdateService service,
) => showDialog<void>(
  context: context,
  barrierDismissible: !update.forced,
  builder: (_) => AppUpdateDialog(update: update, service: service),
);

enum _Step { ready, needsPermission, downloading, installerOpened }

/// Offers the update; downloads it with progress and opens the installer.
/// A forced update cannot be dismissed.
class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({
    super.key,
    required this.update,
    required this.service,
  });

  final AppUpdate update;
  final AppUpdateService service;

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  _Step _step = _Step.ready;
  double? _progress;
  String? _error;
  String? _apkPath;

  AppUpdate get _update => widget.update;

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      if (!await widget.service.canInstallPackages()) {
        setState(() => _step = _Step.needsPermission);
        return;
      }
      if (_apkPath == null) {
        setState(() {
          _step = _Step.downloading;
          _progress = null;
        });
        _apkPath = await widget.service.download(
          _update,
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
        );
      }
      await widget.service.install(_apkPath!);
      if (mounted) setState(() => _step = _Step.installerOpened);
    } on AppUpdateException catch (error) {
      if (mounted) {
        setState(() {
          _step = _Step.ready;
          _error = error.message;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _step = _Step.ready;
          _error = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final forced = _update.forced;
    final busy = _step == _Step.downloading;
    return PopScope(
      canPop: !forced && !busy,
      child: AlertDialog(
        title: Text(forced ? 'Update required' : 'Update available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _content(forced),
        ),
        actions: _actions(forced, busy),
      ),
    );
  }

  List<Widget> _content(bool forced) {
    final size = _update.sizeBytes;
    final sizeText = size == null
        ? ''
        : ' (${(size / (1024 * 1024)).toStringAsFixed(0)} MB)';
    return switch (_step) {
      _Step.ready => [
        Text(
          forced
              ? 'This version of inSOL8 is no longer supported. Install the latest version$sizeText to keep using the app.'
              : 'A new version of inSOL8 is ready to install$sizeText.',
        ),
        if (_update.notes case final notes? when notes.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('What’s new: $notes'),
        ],
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Text(error, style: const TextStyle(color: AppColors.error)),
        ],
      ],
      _Step.needsPermission => const [
        Text(
          'To install updates, allow inSOL8 to install apps. Tap “Open settings”, turn on “Allow from this source”, then come back and tap “Update”.',
        ),
      ],
      _Step.downloading => [
        Text(
          _progress == null
              ? 'Downloading…'
              : 'Downloading… ${(_progress! * 100).toStringAsFixed(0)}%',
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: _progress),
      ],
      _Step.installerOpened => const [
        Text(
          'Follow the prompts to finish installing. If you closed the installer, tap “Install” to open it again.',
        ),
      ],
    };
  }

  List<Widget> _actions(bool forced, bool busy) {
    final later = forced
        ? null
        : TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Later'),
          );
    return switch (_step) {
      _Step.ready => [
        ?later,
        FilledButton(onPressed: _start, child: const Text('Update')),
      ],
      _Step.needsPermission => [
        ?later,
        TextButton(
          onPressed: widget.service.openInstallPermissionSettings,
          child: const Text('Open settings'),
        ),
        FilledButton(onPressed: _start, child: const Text('Update')),
      ],
      _Step.downloading => [?later],
      _Step.installerOpened => [
        ?later,
        FilledButton(onPressed: _start, child: const Text('Install')),
      ],
    };
  }
}
