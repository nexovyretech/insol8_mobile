import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:insol8_mobile/theme/app_colors.dart';

class VerificationCodeInput extends StatelessWidget {
  const VerificationCodeInput({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  }) : assert(controllers.length == focusNodes.length);

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < controllers.length; index++) ...[
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: TextField(
                controller: controllers[index],
                focusNode: focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) => onChanged(index, value),
              ),
            ),
          ),
          if (index != controllers.length - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}
