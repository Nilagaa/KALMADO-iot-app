import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/sensor_logic.dart';

/// Full-width highlighted noise level card.
class NoiseCard extends StatelessWidget {
  final double noiseDb;
  final VoidCallback? onTap;

  const NoiseCard({super.key, required this.noiseDb, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = SensorLogic.noiseStatus(noiseDb);
    final statusColor = SensorLogic.statusColor(status.level);
    final statusBg = SensorLogic.statusBgColor(status.level);
    final progress = SensorLogic.noiseProgress(noiseDb);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.noiseIcon.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: statusColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.noiseBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      color: AppColors.noiseIcon,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Noise Level', style: AppTextStyles.cardTitle),
                      Text(
                        'Critical for sensory students',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.subtitleGray.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status.label,
                      style: AppTextStyles.statusLabel.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Big value
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    noiseDb.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: AppColors.titleNavy,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('dB', style: AppTextStyles.sensorUnit),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Mini bar graph placeholder (5 bars)
              _MiniBarGraph(progress: progress, color: statusColor),

              const SizedBox(height: 14),

              // Scale labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quiet',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.subtitleGray,
                    ),
                  ),
                  Text(
                    'Too Loud',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.subtitleGray,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Horizontal progress scale
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: statusBg,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple animated bar graph placeholder
class _MiniBarGraph extends StatelessWidget {
  final double progress;
  final Color color;

  const _MiniBarGraph({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    // Generate 8 bars with varying heights to simulate a waveform
    final heights = [0.4, 0.6, 0.5, 0.8, progress, 0.7, 0.5, 0.3];
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: heights.map((h) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 40 * h,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25 + h * 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
