import 'package:flutter/material.dart';
import '../models/classroom_model.dart';
import '../models/sensor_detail_config.dart';
import '../models/sensor_type.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/sensor_logic.dart';

/// Reusable sensor detail screen.
/// Accepts a [SensorType] and streams live Firebase data — updates in real time.
class SensorDetailScreen extends StatelessWidget {
  final SensorType sensorType;

  const SensorDetailScreen({super.key, required this.sensorType});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ClassroomModel>(
      stream: FirebaseService.instance.classroomStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }
        final data = snapshot.data ?? ClassroomModel.empty();
        final config = _buildConfig(data);
        return _DetailPage(config: config);
      },
    );
  }

  /// Build the config from live classroom data for the requested sensor.
  SensorDetailConfig _buildConfig(ClassroomModel data) {
    switch (sensorType) {
      case SensorType.temperature:
        return SensorLogic.temperatureConfig(data.temperature);
      case SensorType.humidity:
        return SensorLogic.humidityConfig(data.humidity);
      case SensorType.light:
        return SensorLogic.lightConfig(data.light);
      case SensorType.gas:
        return SensorLogic.gasConfig(data.gas);
      case SensorType.noise:
        return SensorLogic.noiseConfig(data.noise);
    }
  }
}

// ── Detail page layout ────────────────────────────────────────────────────────

class _DetailPage extends StatelessWidget {
  final SensorDetailConfig config;
  const _DetailPage({required this.config});

  SensorStatus get _level {
    switch (config.statusLabel) {
      case 'Comfortable':
      case 'Clean Air':
        return SensorStatus.comfortable;
      case 'Too Cold':
      case 'Too Hot':
      case 'Too Dry':
      case 'Too Humid':
      case 'Too Dark':
      case 'Too Bright':
      case 'Poor Air':
      case 'Critical':
        return SensorStatus.critical;
      default:
        return SensorStatus.moderate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = SensorLogic.statusColor(_level);
    final statusBg = SensorLogic.statusBgColor(_level);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgMint, AppColors.bgWhite, AppColors.bgBlue],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(title: config.title, subtitle: config.subtitle),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    children: [
                      _MainValueCard(
                        config: config,
                        statusColor: statusColor,
                        statusBg: statusBg,
                      ),
                      const SizedBox(height: 16),
                      _ComfortRangeCard(
                        config: config,
                        statusColor: statusColor,
                      ),
                      const SizedBox(height: 16),
                      _DetailCard(
                        title: 'Interpretation',
                        child: Text(
                          config.interpretation,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.bodyGray,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SuggestionsCard(suggestions: config.suggestions),
                      const SizedBox(height: 16),
                      _ScoreCard(
                        score: config.score,
                        statusColor: statusColor,
                        statusBg: statusBg,
                      ),
                    ],
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

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title, subtitle;
  const _TopBar({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.titleNavy,
            iconSize: 20,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.pageTitle),
              Text(subtitle, style: AppTextStyles.pageSubtitle),
            ],
          ),
          const Spacer(),
          // Live indicator
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.comfortable,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.comfortable,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Main value card ───────────────────────────────────────────────────────────

class _MainValueCard extends StatelessWidget {
  final SensorDetailConfig config;
  final Color statusColor, statusBg;
  const _MainValueCard({
    required this.config,
    required this.statusColor,
    required this.statusBg,
  });

  @override
  Widget build(BuildContext context) {
    final display = config.unit == '\u00b0C' || config.unit == 'lux'
        ? config.value.toStringAsFixed(1)
        : config.value.toStringAsFixed(0);

    return _Card(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: config.iconBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: config.iconColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(config.icon, size: 52, color: config.iconColor),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                display,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: AppColors.titleNavy,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  config.unit,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subtitleGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              config.statusLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: statusColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Comfort range card ────────────────────────────────────────────────────────

class _ComfortRangeCard extends StatelessWidget {
  final SensorDetailConfig config;
  final Color statusColor;
  const _ComfortRangeCard({required this.config, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final total = config.rangeMax - config.rangeMin;
    final idealStart = (config.rangeIdealStart - config.rangeMin) / total;
    final idealEnd = (config.rangeIdealEnd - config.rangeMin) / total;
    final current = ((config.value - config.rangeMin) / total).clamp(0.0, 1.0);

    return _DetailCard(
      title: 'Comfort Range',
      child: Column(
        children: [
          const SizedBox(height: 8),
          _RangeBar(
            idealStart: idealStart,
            idealEnd: idealEnd,
            currentPos: current,
            statusColor: statusColor,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RangeLabel(
                text: 'Too Low',
                value: '${config.rangeMin.toStringAsFixed(0)} ${config.unit}',
                color: AppColors.critical,
              ),
              _RangeLabel(
                text: 'Optimal',
                value:
                    '${config.rangeIdealStart.toStringAsFixed(0)}\u2013${config.rangeIdealEnd.toStringAsFixed(0)} ${config.unit}',
                color: AppColors.comfortable,
                center: true,
              ),
              _RangeLabel(
                text: 'Too High',
                value: '${config.rangeMax.toStringAsFixed(0)} ${config.unit}',
                color: AppColors.critical,
                alignRight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  final double idealStart, idealEnd, currentPos;
  final Color statusColor;
  const _RangeBar({
    required this.idealStart,
    required this.idealEnd,
    required this.currentPos,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final x = (currentPos * w).clamp(6.0, w - 6.0);
        return SizedBox(
          height: 36,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: idealStart * w,
                width: (idealEnd - idealStart) * w,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.comfortable.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                left: x - 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RangeLabel extends StatelessWidget {
  final String text, value;
  final Color color;
  final bool center, alignRight;
  const _RangeLabel({
    required this.text,
    required this.value,
    required this.color,
    this.center = false,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final align = center
        ? TextAlign.center
        : alignRight
        ? TextAlign.right
        : TextAlign.left;
    final cross = center
        ? CrossAxisAlignment.center
        : alignRight
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: cross,
      children: [
        Text(
          text,
          textAlign: align,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          value,
          textAlign: align,
          style: const TextStyle(fontSize: 11, color: AppColors.subtitleGray),
        ),
      ],
    );
  }
}

// ── Suggestions card ──────────────────────────────────────────────────────────

class _SuggestionsCard extends StatelessWidget {
  final List<String> suggestions;
  const _SuggestionsCard({required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Suggested Actions',
      child: Column(
        children: List.generate(
          suggestions.length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      suggestions[i],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.bodyGray,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Score card ────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final int score;
  final Color statusColor, statusBg;
  const _ScoreCard({
    required this.score,
    required this.statusColor,
    required this.statusBg,
  });

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Comfort Score',
      child: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    backgroundColor: statusBg,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'out of 100',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.subtitleGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Shared wrappers ───────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _DetailCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [child]),
    );
  }
}
