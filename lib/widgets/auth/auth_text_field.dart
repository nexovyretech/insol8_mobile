import 'package:flutter/material.dart';

import 'package:insol8_mobile/widgets/error_banner.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  /// Validation errors show in the app's error banner under the field.
  @override
  Widget build(BuildContext context) => FieldWithErrorBanner(
    controller: controller,
    validator: validator,
    builder: (context, validate) => TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      validator: validate,
      textInputAction: textInputAction,
      autocorrect: false,
      enableSuggestions: !obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        errorStyle: FieldWithErrorBanner.hiddenErrorStyle,
      ),
    ),
  );
}
