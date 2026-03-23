import 'package:flutter/material.dart';
import '../models/classroom_model.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/sensor_logic.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ClassroomModel>(
      stream: FirebaseService.instance.classroomStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        final data = snapshot.data ?? ClassroomModel.empty();
        return _AnalyticsBody(data: data);
      },
    );
  }
}

class _AnalyticsBody extends StatefulWidget {
  final ClassroomModel data;
  const _AnalyticsBody({required this.data});

  @override
  State<_AnalyticsBody> createState() => _AnalyticsBodyState();
}

class _AnalyticsBodyState extends State<_AnalyticsBody> {
  int _filterIndex = 0;
  final _filters = const ['1 min', '10 min', 'Hour', 'Weekly'];
  final _mockDist = const [
    [0.6, 0.3, 0.1],
    [0.5, 0.35, 0.15],
    [0.55, 0.3, 0.15],
    [0.65, 0.25, 0.10],
  ];

  @override
  Widget build(BuildContext context) {
    final dist = _mockDist[_filterIndex];
    final score = SensorLogic.comfortScore(widget.data);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analytics', style: AppTextStyles.pageTitle),
          const SizedBox(height: 2),
          const Text('Trends & insights', style: AppTextStyles.pageSubtitle),
          const SizedBox(height: 20),
          _FilterRow(
            filters: _filters,
            selected: _filterIndex,
            onSelect: (i) => setState(() => _filterIndex = i),
          ),
          const SizedBox(height: 20),
          _BarChartCard(distribution: dist),
          const SizedBox(height: 20),
          _InsightsCard(score: score),
          const SizedBox(height: 20),
          _ObservationsCard(data: widget.data),
          const SizedBox(height: 20),
          _RecommendationsCard(data: widget.data),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final List<String> filters;
  final int selected;
  final ValueChanged<int> onSelect;
  const _FilterRow({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(filters.length, (i) {
        final active = i == selected;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.accent : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(
                    alpha: active ? 0.3 : 0.08,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              filters[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.subtitleGray,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final List<double> distribution;
  const _BarChartCard({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final labels = ['Comfortable', 'Moderate', 'Critical'];
    final colors = [
      AppColors.comfortable,
      AppColors.moderate,
      AppColors.critical,
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Distribution', style: AppTextStyles.cardTitle),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (i) {
              return Column(
                children: [
                  Text(
                    '${(distribution[i] * 100).round()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors[i],
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    width: 52,
                    height: 120 * distribution[i],
                    decoration: BoxDecoration(
                      color: colors[i].withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[i],
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.subtitleGray,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final int score;
  const _InsightsCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Insights', style: AppTextStyles.cardTitle),
          const SizedBox(height: 16),
          _InsightRow(
            icon: Icons.trending_up_rounded,
            color: AppColors.comfortable,
            text: 'Comfort score averaged $score/100 this period.',
          ),
          const SizedBox(height: 10),
          const _InsightRow(
            icon: Icons.access_time_rounded,
            color: AppColors.accent,
            text: 'Peak discomfort typically occurs mid-morning.',
          ),
          const SizedBox(height: 10),
          const _InsightRow(
            icon: Icons.thermostat_rounded,
            color: AppColors.moderate,
            text:
                'Temperature fluctuations most frequent between 10\u201311 AM.',
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InsightRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.bodyGray,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ObservationsCard extends StatelessWidget {
  final ClassroomModel data;
  const _ObservationsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final noise = SensorLogic.noiseStatus(data.noise);
    final temp = SensorLogic.temperatureStatus(data.temperature);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Behavior Observations', style: AppTextStyles.cardTitle),
          const SizedBox(height: 16),
          _ObsRow(
            label: 'Noise Impact',
            value: noise.label,
            color: SensorLogic.statusColor(noise.level),
            note: 'High noise may increase sensory overload risk.',
          ),
          const Divider(height: 20, color: Color(0xFFF0F4F8)),
          _ObsRow(
            label: 'Thermal Comfort',
            value: temp.label,
            color: SensorLogic.statusColor(temp.level),
            note: 'Temperature affects student focus and behavior.',
          ),
        ],
      ),
    );
  }
}

class _ObsRow extends StatelessWidget {
  final String label, value, note;
  final Color color;
  const _ObsRow({
    required this.label,
    required this.value,
    required this.color,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.titleNavy,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          note,
          style: const TextStyle(fontSize: 12, color: AppColors.subtitleGray),
        ),
      ],
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  final ClassroomModel data;
  const _RecommendationsCard({required this.data});

  List<String> _recs() {
    final out = <String>[];
    if (SensorLogic.temperatureStatus(data.temperature).level !=
        SensorStatus.comfortable) {
      out.add(
        'Adjust air conditioning to maintain 25\u201328\u00b0C for optimal comfort.',
      );
    }
    if (SensorLogic.humidityStatus(data.humidity).level !=
        SensorStatus.comfortable) {
      out.add(
        'Use a humidifier or dehumidifier to keep humidity between 60\u201370%.',
      );
    }
    if (SensorLogic.lightStatus(data.light).level != SensorStatus.comfortable) {
      out.add('Adjust blinds or lighting to reach 800\u20132000 lux.');
    }
    if (SensorLogic.gasStatus(data.gas).level != SensorStatus.comfortable) {
      out.add('Improve ventilation to reduce gas levels.');
    }
    if (SensorLogic.noiseStatus(data.noise).level != SensorStatus.comfortable) {
      out.add('Reduce noise sources or use acoustic panels.');
    }
    if (out.isEmpty) {
      out.add('Classroom environment is optimal. Maintain current conditions.');
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recommendations', style: AppTextStyles.cardTitle),
          const SizedBox(height: 16),
          ..._recs().map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.bodyGray,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
      child: child,
    );
  }
}
