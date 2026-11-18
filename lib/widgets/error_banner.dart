import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';

/// The one style for error and notice messages across the app: a soft red
/// rounded box, full width, with small red text. Used under form fields (see
/// [FieldWithErrorBanner]), in dialogs, and for page-level messages.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: AppColors.errorSurface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: const TextStyle(fontSize: 12, height: 1.3, color: AppColors.error),
    ),
  );
}

/// Hides a field's built-in error line (the box still turns red) and shows
/// the message in an [ErrorBanner] under the field instead.
///
/// [builder] receives the validator to give the TextFormField; the field's
/// decoration should use [hiddenErrorStyle]. [message] is an extra error the
/// page knows about (for example a live notice); it wins over validation.
/// Typing clears the last validation message until the next check.
class FieldWithErrorBanner extends StatefulWidget {
  const FieldWithErrorBanner({
    super.key,
    required this.controller,
    required this.builder,
    this.validator,
    this.message,
  });

  /// For the field's decoration: keeps the red outline, drops the inline text.
  static const hiddenErrorStyle = TextStyle(fontSize: 0, height: 0);

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? message;
  final Widget Function(
    BuildContext context,
    String? Function(String?)? validator,
  )
  builder;

  @override
  State<FieldWithErrorBanner> createState() => _FieldWithErrorBannerState();
}

class _FieldWithErrorBannerState extends State<FieldWithErrorBanner> {
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(FieldWithErrorBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted && _error != null) setState(() => _error = null);
  }

  String? _validate(String? value) {
    final error = widget.validator?.call(value);
    if (error != _error) {
      // Validation runs during a build; show the result on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _error = error);
      });
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.message ?? _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.builder(context, widget.validator == null ? null : _validate),
        if (shown != null) ...[const SizedBox(height: 8), ErrorBanner(shown)],
      ],
    );
  }
}
