import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:insol8_mobile/utils/phone_number.dart';
import 'package:insol8_mobile/widgets/error_banner.dart';

/// The 🇵🇭 +63 mobile number field used by sign-up, forgot password, and
/// Account Profile. Its errors appear in the app's error banner under the
/// whole row, rather than squeezed under the number box.
class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    required this.validator,
    this.hintText = 'Enter your mobile number',
    this.onSubmitted,
    this.errorText,
    this.blockSmartNetwork = false,
  });

  final TextEditingController controller;
  final String? Function(String?) validator;
  final String hintText;
  final ValueChanged<String>? onSubmitted;

  /// An error from the page, shown under the row; the box turns red. Only
  /// for pages that do not validate the field through [validator].
  final String? errorText;

  /// Shows the Smart/TNT notice as soon as such a prefix is typed, and fails
  /// validation for those numbers: our SMS provider can't reach them.
  final bool blockSmartNetwork;

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  /// Where the flag starts inside the prefix.
  static const _flagInset = 14.0;

  static const _maxDigits = 10;
  static const _groupLengths = [3, 3, 4];

  /// The last error [validator] returned, shown under the row.
  String? _formError;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(PhoneNumberField oldWidget) {
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

  /// Typing clears the last validation message (the next submit checks
  /// again) and updates the live Smart/TNT notice.
  void _onChanged() {
    if (!mounted) return;
    if (_formError != null || widget.blockSmartNetwork) {
      setState(() => _formError = null);
    }
  }

  bool _isSmart(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    final national = digits.startsWith('0') ? digits.substring(1) : digits;
    return national.length >= 3 &&
        isSmartNetworkNumber('+63${national.padRight(10, '0')}');
  }

  String? _validate(String? value) {
    final error = widget.blockSmartNetwork && _isSmart(value)
        ? smartNetworkUnsupportedMessage
        : widget.validator(value);
    if (error != _formError) {
      // Validation runs during build; show the result on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _formError = error);
      });
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final liveNotice =
        widget.blockSmartNetwork && _isSmart(widget.controller.text)
        ? smartNetworkUnsupportedMessage
        : null;
    final shown = widget.errorText ?? liveNotice ?? _formError;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          height: 56,
          child: Padding(
            padding: const EdgeInsets.only(left: _flagInset),
            // Shrinks rather than overflows with a large system font.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇵🇭', style: TextStyle(fontSize: 17)),
                  const SizedBox(width: 4),
                  Text(
                    '+63',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              PhoneNumberInputFormatter(
                groupLengths: _groupLengths,
                maxDigits: _maxDigits,
              ),
            ],
            validator: _validate,
            onFieldSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: widget.hintText,
              // A validation error still turns the box red, but its text is
              // shown under the row instead of here.
              errorStyle: FieldWithErrorBanner.hiddenErrorStyle,
              error: widget.errorText == null ? null : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
    if (shown == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [row, const SizedBox(height: 8), ErrorBanner(shown)],
    );
  }
}

class PhoneNumberInputFormatter extends TextInputFormatter {
  const PhoneNumberInputFormatter({
    required this.groupLengths,
    required this.maxDigits,
  });

  final List<int> groupLengths;
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) return oldValue;

    final formatted = formatDigits(digits);
    final caretOffset = newValue.selection.extentOffset
        .clamp(0, newValue.text.length)
        .toInt();
    final digitsBeforeCaret = newValue.text
        .substring(0, caretOffset)
        .replaceAll(RegExp(r'\D'), '')
        .length;

    var formattedCaret = 0;
    var digitsCounted = 0;
    while (formattedCaret < formatted.length &&
        digitsCounted < digitsBeforeCaret) {
      if (RegExp(r'\d').hasMatch(formatted[formattedCaret])) {
        digitsCounted++;
      }
      formattedCaret++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formattedCaret),
    );
  }

  String formatDigits(String digits) {
    final output = StringBuffer();
    var start = 0;
    for (final groupLength in groupLengths) {
      if (start >= digits.length) break;
      if (start > 0) output.write(' ');
      final end = (start + groupLength).clamp(0, digits.length).toInt();
      output.write(digits.substring(start, end));
      start = end;
    }
    return output.toString();
  }
}
