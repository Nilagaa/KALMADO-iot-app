import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/sensor_logic.dart';

/// Full-width highlighted noise level card with animated progress bar.
class NoiseCard extends StatefulWidget {
  final double noiseDb;
  final StatusResult? status;
  final VoidCallback? onTap;

  const NoiseCard({super.key, required this.noiseDb, this.status, this.onTap});

  @override
  State<NoiseCard> createState() => _NoiseCardState();
}

class _NoiseCardState extends State<NoiseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progressAnim;
  double _prevProgress = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final p = SensorLogic.noiseProgress(widget.noiseDb);
    _progressAnim = Tween<double>(
      begin: 0,
      end: p,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _prevProgress = p;
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(NoiseCard old) {
    super.didUpdateWidget(old);
    final newP = SensorLogic.noiseProgress(widget.noiseDb);
    if ((newP - _prevProgress).abs() > 0.001) {
      _progressAnim = Tween<double>(
        begin: _prevProgress,
        end: newP,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
      _prevProgress = newP;
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedStatus =
        widget.status ?? SensorLogic.noiseStatus(widget.noiseDb);
    final statusColor = SensorLogic.statusColor(resolvedStatus.level);
    final statusBg = SensorLogic.statusBgColor(resolvedStatus.level);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
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
                      resolvedStatus.label,
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
                    widget.noiseDb.toStringAsFixed(0),
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

              // Animated mini bar graph
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, child) => _MiniBarGraph(
                  progress: _progressAnim.value,
                  color: statusColor,
                ),
              ),

              const SizedBox(height: 14),

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

              // Animated progress bar
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, child) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _progressAnim.value,
                    minHeight: 8,
                    backgroundColor: statusBg,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBarGraph extends StatelessWidget {
  final double progress;
  final Color color;
  const _MiniBarGraph({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    final heights = [
      0.4,
      0.6,
      0.5,
      0.8,
      progress.clamp(0.05, 1.0),
      0.7,
      0.5,
      0.3,
    ];
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
