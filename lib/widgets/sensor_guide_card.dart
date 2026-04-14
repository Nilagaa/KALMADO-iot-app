import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Expandable sensor threshold guide card.
/// Values reflect the actual thresholds in sensor_logic.dart — do not change
/// these independently; update sensor_logic.dart first if thresholds change.
class SensorGuideCard extends StatefulWidget {
  const SensorGuideCard({super.key});

  @override
  State<SensorGuideCard> createState() => _SensorGuideCardState();
}

class _SensorGuideCardState extends State<SensorGuideCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header / toggle ──────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Sensor Threshold Guide',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.titleNavy,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.subtitleGray,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable content ───────────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFF0F4F8)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: const [
                  _GuideRow(
                    icon: Icons.thermostat_rounded,
                    iconColor: AppColors.tempIcon,
                    label: 'Temperature',
                    comfortable: '22 – 28 °C',
                    moderate: '29 – 31 °C',
                    critical: '< 22 °C  or  > 31 °C',
                  ),
                  SizedBox(height: 10),
                  _GuideRow(
                    icon: Icons.water_drop_rounded,
                    iconColor: AppColors.humidIcon,
                    label: 'Humidity',
                    comfortable: '60 – 70 %',
                    moderate: '40 – 59 %  or  71 – 85 %',
                    critical: '< 40 %  or  > 85 %',
                  ),
                  SizedBox(height: 10),
                  _GuideRow(
                    icon: Icons.light_mode_rounded,
                    iconColor: AppColors.lightIcon,
                    label: 'Light (0–100)',
                    comfortable: '41 – 80',
                    moderate: '21 – 40',
                    critical: '0 – 20  or  > 80',
                  ),
                  SizedBox(height: 10),
                  _GuideRow(
                    icon: Icons.air_rounded,
                    iconColor: AppColors.gasIcon,
                    label: 'Air Quality (0–100)',
                    comfortable: '0 – 20',
                    moderate: '21 – 50',
                    critical: '> 50',
                  ),
                  SizedBox(height: 10),
                  _GuideRow(
                    icon: Icons.volume_up_rounded,
                    iconColor: AppColors.noiseIcon,
                    label: 'Noise (0–100)',
                    comfortable: '0 – 20',
                    moderate: '21 – 50',
                    critical: '> 50',
                  ),
                  SizedBox(height: 12),
                  _LegendRow(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Single sensor guide row ───────────────────────────────────────────────────

class _GuideRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String comfortable;
  final String moderate;
  final String critical;

  const _GuideRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.comfortable,
    required this.moderate,
    required this.critical,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.titleNavy,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Chip(
                    comfortable,
                    AppColors.comfortable,
                    AppColors.comfortableBg,
                  ),
                  _Chip(moderate, AppColors.moderate, AppColors.moderateBg),
                  _Chip(critical, AppColors.critical, AppColors.criticalBg),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  const _Chip(this.text, this.color, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(AppColors.comfortable, 'Comfortable'),
        const SizedBox(width: 12),
        _LegendDot(AppColors.moderate, 'Moderate'),
        const SizedBox(width: 12),
        _LegendDot(AppColors.critical, 'Critical'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.subtitleGray),
        ),
      ],
    );
  }
}
