import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    required this.validator,
    this.hintText = 'Enter your mobile number',
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? Function(String?) validator;
  final String hintText;
  final ValueChanged<String>? onSubmitted;

  static const _maxDigits = 10;
  static const _groupLengths = [3, 3, 4];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          height: 56,
          child: Center(
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
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              PhoneNumberInputFormatter(
                groupLengths: _groupLengths,
                maxDigits: _maxDigits,
              ),
            ],
            validator: validator,
            onFieldSubmitted: onSubmitted,
            decoration: InputDecoration(hintText: hintText),
          ),
        ),
      ],
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
