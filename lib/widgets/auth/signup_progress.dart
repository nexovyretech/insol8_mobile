import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';

class SignupProgress extends StatelessWidget {
  const SignupProgress({super.key, required this.activeStep});

  final int activeStep;

  static const _labels = ['Name', 'Register', 'Password', 'Username'];
  static const _icons = [
    Icons.person,
    Icons.fact_check,
    Icons.password,
    Icons.badge,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final lineWidth = ((constraints.maxWidth - 4 * 45) / 3)
            .clamp(6.0, 24.0)
            .toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var index = 0; index < _labels.length; index++) ...[
              _ProgressItem(
                label: _labels[index],
                icon: _icons[index],
                active: index <= activeStep,
              ),
              if (index < _labels.length - 1)
                Container(
                  width: lineWidth,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 21),
                  color: index < activeStep
                      ? AppColors.primary
                      : AppColors.inactive,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _ProgressItem extends StatelessWidget {
  const _ProgressItem({
    required this.label,
    required this.icon,
    required this.active,
  });

  final String label;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.inactive;
    return SizedBox(
      width: 45,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(color: color, fontSize: 9, height: 1.1),
          ),
        ],
      ),
    );
  }
}
