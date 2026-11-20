import 'package:flutter/material.dart';

/// The screenshot's single quick-action card: "Add a Job" / "New drying job".
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key, required this.onAddJob});

  final VoidCallback onAddJob;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFD97247),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onAddJob,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.sunny, color: Color(0xFFFEF7F2), size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New drying job',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFFEF7F2),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Create a new drying session',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFF4D7C8),
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFFEF7F2),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
