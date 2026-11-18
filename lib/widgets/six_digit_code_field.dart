import 'package:flutter/material.dart';

import 'package:insol8_mobile/widgets/auth/verification_code_input.dart';

/// The sign-up 6-box code input, managing its own boxes: focus moves forward
/// as digits are typed and back on delete. Reports the code as typed, and
/// once more through [onCompleted] when all six digits are in.
class SixDigitCodeField extends StatefulWidget {
  const SixDigitCodeField({
    super.key,
    required this.onChanged,
    this.onCompleted,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<SixDigitCodeField> createState() => _SixDigitCodeFieldState();
}

class _SixDigitCodeFieldState extends State<SixDigitCodeField> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _changed(int index, String value) {
    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    final code = _controllers.map((controller) => controller.text).join();
    widget.onChanged(code);
    if (code.length == 6) widget.onCompleted?.call(code);
  }

  @override
  Widget build(BuildContext context) => VerificationCodeInput(
    controllers: _controllers,
    focusNodes: _focusNodes,
    onChanged: _changed,
  );
}
