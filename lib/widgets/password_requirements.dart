import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/utils/password_rules.dart';

/// The live checklist under a new-password field. Each requirement turns
/// green with a check as soon as the password meets it, and red while it
/// doesn't; before anything is typed every line is a neutral grey.
///
/// With [confirmController], a last line checks that both fields match.
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({
    super.key,
    required this.controller,
    this.confirmController,
  });

  final TextEditingController controller;
  final TextEditingController? confirmController;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller, ?confirmController]),
    builder: (context, _) {
      final password = controller.text;
      final confirm = confirmController?.text ?? '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final rule in passwordRules)
            _RequirementLine(
              label: rule.label,
              state: password.isEmpty
                  ? _LineState.pending
                  : rule.isMet(password)
                  ? _LineState.met
                  : _LineState.unmet,
            ),
          if (confirmController != null)
            _RequirementLine(
              label: 'Passwords match',
              state: confirm.isEmpty
                  ? _LineState.pending
                  : confirm == password
                  ? _LineState.met
                  : _LineState.unmet,
            ),
        ],
      );
    },
  );
}

enum _LineState { pending, met, unmet }

class _RequirementLine extends StatelessWidget {
  const _RequirementLine({required this.label, required this.state});

  final String label;
  final _LineState state;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (state) {
      _LineState.pending => (
        Icons.radio_button_unchecked_rounded,
        AppColors.fieldHint,
      ),
      _LineState.met => (Icons.check_circle_rounded, AppColors.success),
      _LineState.unmet => (Icons.cancel_rounded, AppColors.error),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(icon, key: ValueKey(state), size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style:
                  Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontSize: 12, height: 1.3, color: color) ??
                  TextStyle(fontSize: 12, color: color),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
