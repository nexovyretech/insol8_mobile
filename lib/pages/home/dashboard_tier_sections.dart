import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/dashboard_data.dart';
import 'package:insol8_mobile/pages/home/dashboard_metric_grid.dart';

/// Basic tier section under "Needs Attention".
class DashboardDryingJobList extends StatelessWidget {
  const DashboardDryingJobList({super.key, required this.jobs});

  final List<DashboardDryingJob> jobs;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No drying jobs are running right now.',
          style: TextStyle(color: DashboardMetricColors.label, fontSize: 12),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < jobs.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          _DryingJobRow(job: jobs[index]),
        ],
      ],
    );
  }
}

class _DryingJobRow extends StatelessWidget {
  const _DryingJobRow({required this.job});

  final DashboardDryingJob job;

  @override
  Widget build(BuildContext context) {
    final load = job.loadKg == job.loadKg.roundToDouble()
        ? job.loadKg.toInt().toString()
        : job.loadKg.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: DashboardMetricColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardMetricColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                job.dryerName,
                style: const TextStyle(
                  color: Color(0xFFC75C36),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  job.status,
                  style: const TextStyle(
                    color: Color(0xFF60C261),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Load: $load kg • Remaining: ${job.remainingMinutes} min',
            style: const TextStyle(
              color: Color(0xFF5D5D5D),
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

/// Org tier section under "Needs Attention": "First Recorded Job Today".
class DashboardBranchList extends StatelessWidget {
  const DashboardBranchList({super.key, required this.branches});

  final List<DashboardBranchActivity> branches;

  @override
  Widget build(BuildContext context) {
    if (branches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No jobs recorded today.',
          style: TextStyle(color: DashboardMetricColors.label, fontSize: 12),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < branches.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          _BranchRow(branch: branches[index]),
        ],
      ],
    );
  }
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({required this.branch});

  final DashboardBranchActivity branch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: DashboardMetricColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardMetricColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFF4D7C8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${branch.number}',
                style: const TextStyle(
                  color: DashboardMetricColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch.location,
                  style: const TextStyle(
                    color: Color(0xFF1A1613),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  branch.name,
                  style: const TextStyle(
                    color: DashboardMetricColors.label,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            branch.time,
            style: const TextStyle(
              color: Color(0xFF917F75),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
