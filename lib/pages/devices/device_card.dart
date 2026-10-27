import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/theme/app_colors.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key, required this.device, this.onTap});

  final DeviceData device;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (device.status) {
      DeviceStatus.active => AppColors.primary,
      DeviceStatus.idle => AppColors.sectionLabel,
      DeviceStatus.offline => AppColors.inactive,
    };

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.dashboardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatTemperature(device.temperatureCelsius)}°C  |  ${device.batteryPercent}%  |  ${device.cycleDuration}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.fieldHint, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    device.lastUpdated,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.fieldHint, fontSize: 11),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTemperature(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
