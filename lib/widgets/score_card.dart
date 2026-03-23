import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/sensor_logic.dart';

class ScoreCard extends StatelessWidget {
  final int score;
  const ScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final SensorStatus level;
    if (score >= 70) {
      level = SensorStatus.comfortable;
    } else if (score >= 40) {
      level = SensorStatus.moderate;
    } else {
      level = SensorStatus.critical;
    }

    final color = SensorLogic.statusColor(level);
    final bg = SensorLogic.statusBgColor(level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: bg,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: AppTextStyles.scoreNumber.copyWith(
                        fontSize: 28,
                        color: color,
                      ),
                    ),
                    Text(
                      'Score',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.subtitleGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OVERALL COMFORT SCORE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.subtitleGray,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  SensorLogic.overallLabel(level),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Based on all sensor readings',
                  style: TextStyle(fontSize: 12, color: AppColors.subtitleGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
