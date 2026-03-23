import 'package:flutter/material.dart';
import '../utils/app_text_styles.dart';
import '../utils/sensor_logic.dart';

class OverallStatusCard extends StatelessWidget {
  final SensorStatus status;
  final int timestamp;

  const OverallStatusCard({
    super.key,
    required this.status,
    required this.timestamp,
  });

  String _timeLabel() {
    if (timestamp == 0) return 'Waiting for data...';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    return 'Updated ${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = SensorLogic.statusColor(status);
    final label = SensorLogic.overallLabel(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CLASSROOM STATUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.bigStatus),
          const SizedBox(height: 8),
          Text(
            _timeLabel(),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: SensorStatus.values.map((s) {
              final isActive = s == status;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                width: isActive ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
