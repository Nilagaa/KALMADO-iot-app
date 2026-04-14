import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/sensor_logic.dart';

class AlertTile extends StatelessWidget {
  final String sensor;
  final String label;
  final String description;
  final SensorStatus level;
  final DateTime time;

  const AlertTile({
    super.key,
    required this.sensor,
    required this.label,
    required this.description,
    required this.level,
    required this.time,
  });

  IconData _iconFor(String sensor) {
    switch (sensor) {
      case 'Temperature':
        return Icons.thermostat_rounded;
      case 'Humidity':
        return Icons.water_drop_rounded;
      case 'Light':
        return Icons.light_mode_rounded;
      case 'Air Quality':
        return Icons.air_rounded;
      case 'Noise':
        return Icons.volume_up_rounded;
      default:
        return Icons.sensors;
    }
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds} secs ago';
    if (diff.inMinutes == 1) return '1 minute ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours == 1) return '1 hour ago';
    return '${diff.inHours} hours ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = SensorLogic.statusColor(level);
    final bg = SensorLogic.statusBgColor(level);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(sensor), color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensor,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.titleNavy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.subtitleGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.statusLabel.copyWith(color: color),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _timeAgo(),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.subtitleGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
