import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/widgets/error_banner.dart';

class AuthPasswordField extends StatelessWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.visible,
    required this.onToggleVisibility,
    this.validator,
    this.textInputAction = TextInputAction.done,
  });

  final TextEditingController controller;
  final String hintText;
  final bool visible;
  final VoidCallback onToggleVisibility;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  /// Validation errors show in the app's error banner under the field.
  @override
  Widget build(BuildContext context) => FieldWithErrorBanner(
    controller: controller,
    validator: validator,
    builder: (context, validate) => TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: validate,
      textInputAction: textInputAction,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        hintText: hintText,
        errorStyle: FieldWithErrorBanner.hiddenErrorStyle,
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
          color: AppColors.primary,
          tooltip: visible ? 'Hide password' : 'Show password',
        ),
      ),
    ),
  );
}
