import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:insol8_mobile/pages/onboarding/branch_setup_style.dart';
import 'package:insol8_mobile/widgets/error_banner.dart';

/// Text field used by both branch setup and the new manager account screen.
/// Matches the Figma fill, border, hint and error treatment exactly.
class BranchSetupTextField extends StatelessWidget {
  const BranchSetupTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.validator,
    this.capitalization = TextCapitalization.none,
    this.keyboardType,
    this.inputFormatters = const [],
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final String? Function(String? value)? validator;
  final TextCapitalization capitalization;
  final TextInputType? keyboardType;
  final List<TextInputFormatter> inputFormatters;

  String? _validate(String? value) =>
      validator?.call(value) ??
      ((value ?? '').trim().isEmpty ? 'This field is required.' : null);

  @override
  Widget build(BuildContext context) => FieldWithErrorBanner(
    controller: controller,
    validator: _validate,
    builder: (context, validate) => TextFormField(
      controller: controller,
      textCapitalization: capitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (_) => onChanged(),
      validator: validate,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: BranchSetupPalette.ink, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: BranchSetupPalette.body, fontSize: 14),
        errorStyle: FieldWithErrorBanner.hiddenErrorStyle,
        // Without filled: true Flutter ignores fillColor and the Figma
        // light-orange field frame disappears.
        filled: true,
        fillColor: BranchSetupPalette.field,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BranchSetupPalette.fieldBorder),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BranchSetupPalette.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BranchSetupPalette.orange),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BranchSetupPalette.orange),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BranchSetupPalette.orange),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
      ),
    ),
  );
}
