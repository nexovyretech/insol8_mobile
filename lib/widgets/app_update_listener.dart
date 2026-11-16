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
/// Styled like the app's other modals (settings): white card, rounded
/// corners, orange accents, and side-by-side buttons. A forced update cannot
/// be dismissed.
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

class _AppUpdateDialogState extends State<AppUpdateDialog>
    with WidgetsBindingObserver {
  _Step _step = _Step.ready;
  double? _progress;
  String? _error;
  String? _apkPath;

  AppUpdate get _update => widget.update;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from Android's "Install unknown apps" screen: carry on by itself
  /// once the permission is on.
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state != AppLifecycleState.resumed || _step != _Step.needsPermission) {
      return;
    }
    if (await widget.service.canInstallPackages() && mounted) await _start();
  }

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
      _fail(error.message);
    } on Exception {
      _fail('Something went wrong. Please try again.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _step = _step == _Step.needsPermission ? _step : _Step.ready;
      _error = message;
    });
  }

  void _later() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    final forced = _update.forced;
    final busy = _step == _Step.downloading;
    return PopScope(
      canPop: !forced && !busy,
      child: Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._header(forced),
                const SizedBox(height: 18),
                // Flexible: a long feature list scrolls instead of pushing the
                // buttons off screen.
                Flexible(child: _body(forced)),
                if (_error case final error?) ...[
                  const SizedBox(height: 12),
                  _ErrorBox(error),
                ],
                if (_buttons(forced) case final buttons?) ...[
                  const SizedBox(height: 20),
                  buttons,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _header(bool forced) {
    final (icon, title) = switch (_step) {
      _Step.ready => (
        forced ? Icons.system_update_rounded : Icons.rocket_launch_rounded,
        forced ? 'Update required' : 'Update available',
      ),
      _Step.needsPermission => (
        Icons.admin_panel_settings_rounded,
        'Allow app installs',
      ),
      _Step.downloading => (Icons.downloading_rounded, 'Downloading update'),
      _Step.installerOpened => (
        Icons.install_mobile_rounded,
        'Ready to install',
      ),
    };
    final tag = [
      ?_update.displayVersion,
      'Build ${_update.build}',
      if (_update.sizeBytes case final size? when size > 0) _megabytes(size),
    ].join('  ·  ');
    return [
      Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.dashboardIconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 32),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 19,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _body(bool forced) => switch (_step) {
    _Step.ready => _Message(
      forced
          ? 'This version of inSOL8 is no longer supported. Update to keep using the app.'
          : 'A new version of inSOL8 is ready with the latest fixes and improvements.',
    ),
    _Step.needsPermission => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Message(
          'Android needs your permission before inSOL8 can install its own updates. You only do this once.',
        ),
        const SizedBox(height: 16),
        Flexible(
          child: _Card(
            scrollable: true,
            children: [
              for (final (index, text) in const [
                'Tap “Open settings”.',
                'Turn on “Allow from this source”.',
                'Come back here. The update continues by itself.',
              ].indexed)
                _ListRow(leading: _StepNumber(index + 1), text: text),
            ],
          ),
        ),
      ],
    ),
    _Step.downloading => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Message('Keep inSOL8 open until the download finishes.'),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
            color: AppColors.primary,
            backgroundColor: AppColors.field,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              _progress == null
                  ? 'Starting…'
                  : '${(_progress! * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_downloadedText case final text?)
              Text(
                text,
                style: const TextStyle(color: AppColors.body, fontSize: 12),
              ),
          ],
        ),
      ],
    ),
    _Step.installerOpened => const _Message(
      'Follow Android’s prompts to finish installing. If you closed the installer, tap “Install” to open it again.',
    ),
  };

  /// "5.4 of 12 MB" while downloading, when the size is known.
  String? get _downloadedText {
    final size = _update.sizeBytes;
    final progress = _progress;
    if (size == null || size <= 0 || progress == null) return null;
    final total = size / (1024 * 1024);
    return '${(total * progress).toStringAsFixed(1)} of ${total.toStringAsFixed(1)} MB';
  }

  /// At most two buttons, side by side: the secondary on the left and the
  /// main action on the right. A forced update has no "Later".
  Widget? _buttons(bool forced) => switch (_step) {
    _Step.ready => _ButtonRow(
      secondary: forced ? null : _Action('Later', _later, quiet: true),
      primary: _Action('Update', _start),
    ),
    _Step.needsPermission => _ButtonRow(
      secondary: _Action(
        'Open settings',
        widget.service.openInstallPermissionSettings,
      ),
      primary: _Action('Continue', _start),
    ),
    _Step.downloading => null,
    _Step.installerOpened => _ButtonRow(
      secondary: forced ? null : _Action('Later', _later, quiet: true),
      primary: _Action('Install', _start),
    ),
  };
}

String _megabytes(int bytes) {
  final mb = bytes / (1024 * 1024);
  return '${mb < 10 ? mb.toStringAsFixed(1) : mb.toStringAsFixed(0)} MB';
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(color: AppColors.body, fontSize: 14, height: 1.4),
  );
}

/// The soft orange card used across the app; scrolls when its content is
/// taller than the space the dialog has left.
class _Card extends StatefulWidget {
  const _Card({required this.children, this.scrollable = false});
  final List<Widget> children;
  final bool scrollable;

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, child) in widget.children.indexed) ...[
            if (index > 0) const SizedBox(height: 10),
            child,
          ],
        ],
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dashboardCard,
        border: Border.all(color: AppColors.dashboardBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.scrollable
          ? ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: content,
                ),
              ),
            )
          : content,
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.leading, required this.text});
  final Widget leading;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.only(top: 1), child: leading),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}

class _StepNumber extends StatelessWidget {
  const _StepNumber(this.number);
  final int number;

  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: 18,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: AppColors.primary,
      shape: BoxShape.circle,
    ),
    child: Text(
      '$number',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.errorSurface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: AppColors.error,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _Action {
  const _Action(this.label, this.onPressed, {this.quiet = false});
  final String label;
  final VoidCallback onPressed;

  /// A dismiss button ("Later"): muted text instead of orange.
  final bool quiet;
}

/// Secondary on the left, primary on the right, equal widths; the primary
/// alone takes the full width.
class _ButtonRow extends StatelessWidget {
  const _ButtonRow({required this.primary, this.secondary});
  final _Action primary;
  final _Action? secondary;

  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (secondary case final secondary?) ...[
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: secondary.onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: secondary.quiet
                    ? AppColors.body
                    : AppColors.primaryDark,
                backgroundColor: AppColors.dashboardCard,
                side: const BorderSide(color: AppColors.dashboardBorder),
                shape: _shape,
              ),
              child: Text(secondary.label),
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
      Expanded(
        child: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: primary.onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: _shape,
            ),
            child: Text(primary.label),
          ),
        ),
      ),
    ],
  );
}
