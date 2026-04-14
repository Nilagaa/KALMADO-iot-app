import 'dart:async';
import 'package:flutter/material.dart';
import '../models/classroom_model.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/sensor_logic.dart';

// ── Filter definition ─────────────────────────────────────────────────────────

class _Filter {
  final String label;
  final Duration? duration;
  const _Filter(this.label, this.duration);
}

const _filters = [
  _Filter('Live', null),
  _Filter('10 min', Duration(minutes: 10)),
  _Filter('1 hr', Duration(hours: 1)),
  _Filter('6 hr', Duration(hours: 6)),
  _Filter('24 hr', Duration(hours: 24)),
  _Filter('Weekly', Duration(days: 7)),
];

// ── Computed analytics from a list of records ─────────────────────────────────

class _Analytics {
  final int totalRecords;
  final int avgScore;
  final int comfortableCount;
  final int moderateCount;
  final int criticalCount;

  // Per-sensor averages
  final double avgTemp;
  final double avgHumidity;
  final double avgLight;
  final double avgGas;
  final double avgNoise;

  // Most frequent status per sensor
  final String dominantTempStatus;
  final String dominantHumidStatus;
  final String dominantLightStatus;
  final String dominantGasStatus;
  final String dominantNoiseStatus;

  const _Analytics({
    required this.totalRecords,
    required this.avgScore,
    required this.comfortableCount,
    required this.moderateCount,
    required this.criticalCount,
    required this.avgTemp,
    required this.avgHumidity,
    required this.avgLight,
    required this.avgGas,
    required this.avgNoise,
    required this.dominantTempStatus,
    required this.dominantHumidStatus,
    required this.dominantLightStatus,
    required this.dominantGasStatus,
    required this.dominantNoiseStatus,
  });

  double get comfortablePct =>
      totalRecords > 0 ? comfortableCount / totalRecords : 0;
  double get moderatePct => totalRecords > 0 ? moderateCount / totalRecords : 0;
  double get criticalPct => totalRecords > 0 ? criticalCount / totalRecords : 0;

  static _Analytics from(List<ClassroomModel> records) {
    if (records.isEmpty) {
      return const _Analytics(
        totalRecords: 0,
        avgScore: 0,
        comfortableCount: 0,
        moderateCount: 0,
        criticalCount: 0,
        avgTemp: 0,
        avgHumidity: 0,
        avgLight: 0,
        avgGas: 0,
        avgNoise: 0,
        dominantTempStatus: 'UNKNOWN',
        dominantHumidStatus: 'UNKNOWN',
        dominantLightStatus: 'UNKNOWN',
        dominantGasStatus: 'UNKNOWN',
        dominantNoiseStatus: 'UNKNOWN',
      );
    }

    int comfortable = 0, moderate = 0, critical = 0, scoreSum = 0;
    double tempSum = 0, humidSum = 0, lightSum = 0, gasSum = 0, noiseSum = 0;

    // Frequency maps for dominant status
    final tempFreq = <String, int>{};
    final humidFreq = <String, int>{};
    final lightFreq = <String, int>{};
    final gasFreq = <String, int>{};
    final noiseFreq = <String, int>{};

    for (final r in records) {
      switch (SensorLogic.overallStatus(r)) {
        case SensorStatus.comfortable:
          comfortable++;
          break;
        case SensorStatus.moderate:
          moderate++;
          break;
        case SensorStatus.critical:
          critical++;
          break;
      }
      scoreSum += SensorLogic.comfortScore(r);
      tempSum += r.temperature;
      humidSum += r.humidity;
      lightSum += r.light;
      gasSum += r.gas;
      noiseSum += r.noise;

      tempFreq[r.temperatureStatus] = (tempFreq[r.temperatureStatus] ?? 0) + 1;
      humidFreq[r.humidityStatus] = (humidFreq[r.humidityStatus] ?? 0) + 1;
      lightFreq[r.lightStatus] = (lightFreq[r.lightStatus] ?? 0) + 1;
      gasFreq[r.gasStatus] = (gasFreq[r.gasStatus] ?? 0) + 1;
      noiseFreq[r.noiseStatus] = (noiseFreq[r.noiseStatus] ?? 0) + 1;
    }

    final n = records.length;
    return _Analytics(
      totalRecords: n,
      avgScore: (scoreSum / n).round(),
      comfortableCount: comfortable,
      moderateCount: moderate,
      criticalCount: critical,
      avgTemp: tempSum / n,
      avgHumidity: humidSum / n,
      avgLight: lightSum / n,
      avgGas: gasSum / n,
      avgNoise: noiseSum / n,
      dominantTempStatus: _dominant(tempFreq),
      dominantHumidStatus: _dominant(humidFreq),
      dominantLightStatus: _dominant(lightFreq),
      dominantGasStatus: _dominant(gasFreq),
      dominantNoiseStatus: _dominant(noiseFreq),
    );
  }

  static String _dominant(Map<String, int> freq) {
    if (freq.isEmpty) return 'UNKNOWN';
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

// ── Root screen ───────────────────────────────────────────────────────────────

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _filterIndex = 0;
  ClassroomModel? _liveData;
  List<ClassroomModel> _history = [];
  bool _historyLoading = false;

  StreamSubscription<ClassroomModel>? _liveSub;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Live tab — subscribe to classroom stream
    _liveSub = FirebaseService.instance.classroomStream.listen((data) {
      if (mounted) setState(() => _liveData = data);
    });
    // Auto-refresh history every 60 s so new records appear without manual tap
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      final duration = _filters[_filterIndex].duration;
      if (duration != null && mounted) _loadHistory(duration);
    });
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory(Duration duration) async {
    setState(() => _historyLoading = true);
    final records = await FirebaseService.instance.fetchHistory(duration);
    if (mounted) {
      setState(() {
        _history = records;
        _historyLoading = false;
      });
    }
  }

  void _onFilterChanged(int index) {
    setState(() {
      _filterIndex = index;
      // Clear stale history so loading state shows while fetching
      if (_filters[index].duration != null) _history = [];
    });
    final duration = _filters[index].duration;
    if (duration != null) {
      _loadHistory(duration);
    }
  }

  Future<void> _onRefresh() async {
    final duration = _filters[_filterIndex].duration;
    if (duration != null) {
      await _loadHistory(duration);
    } else {
      // Live tab — just wait briefly, stream auto-updates
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLive = _filters[_filterIndex].duration == null;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analytics', style: AppTextStyles.pageTitle),
            const SizedBox(height: 2),
            Row(
              children: [
                const Text(
                  'Trends & insights',
                  style: AppTextStyles.pageSubtitle,
                ),
                const Spacer(),
                // Refresh button — reloads current tab only
                if (_filters[_filterIndex].duration != null)
                  GestureDetector(
                    onTap: _historyLoading
                        ? null
                        : () => _loadHistory(_filters[_filterIndex].duration!),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _historyLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              size: 16,
                              color: AppColors.accent,
                            ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _FilterRow(
              filters: _filters.map((f) => f.label).toList(),
              selected: _filterIndex,
              onSelect: _onFilterChanged,
            ),
            const SizedBox(height: 20),
            if (isLive)
              _liveData == null
                  ? const _LoadingState()
                  : _AnalyticsContent(
                      analytics: _Analytics.from([_liveData!]),
                      rangeLabel: 'Live',
                      latestRecord: _liveData,
                    )
            else if (_historyLoading)
              const _LoadingState()
            else if (_history.isEmpty)
              _EmptyHistoryState(rangeLabel: _filters[_filterIndex].label)
            else
              _AnalyticsContent(
                analytics: _Analytics.from(_history),
                rangeLabel: _filters[_filterIndex].label,
                latestRecord: _history.last,
              ),
          ],
        ),
      ), // SingleChildScrollView
    ); // RefreshIndicator
  }
}

// ── Unified analytics content ─────────────────────────────────────────────────

class _AnalyticsContent extends StatelessWidget {
  final _Analytics analytics;
  final String rangeLabel;
  final ClassroomModel? latestRecord;
  const _AnalyticsContent({
    required this.analytics,
    required this.rangeLabel,
    required this.latestRecord,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Score summary card
        _ScoreSummaryCard(analytics: analytics, rangeLabel: rangeLabel),
        const SizedBox(height: 16),
        // 2. Status distribution bar chart
        _DistributionCard(analytics: analytics, rangeLabel: rangeLabel),
        const SizedBox(height: 16),
        // 3. Per-sensor averages
        _SensorAveragesCard(analytics: analytics),
        const SizedBox(height: 16),
        // 4. Per-sensor status breakdown
        _SensorStatusCard(analytics: analytics),
        const SizedBox(height: 16),
        // 5. Recommendations from latest record
        if (latestRecord != null) ...[
          _RecommendationsCard(data: latestRecord!),
        ],
      ],
    );
  }
}

// ── 1. Score summary card ─────────────────────────────────────────────────────

class _ScoreSummaryCard extends StatefulWidget {
  final _Analytics a;
  final String rangeLabel;
  const _ScoreSummaryCard({
    required _Analytics analytics,
    required this.rangeLabel,
  }) : a = analytics;

  @override
  State<_ScoreSummaryCard> createState() => _ScoreSummaryCardState();
}

class _ScoreSummaryCardState extends State<_ScoreSummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prevValue = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(
      begin: 0,
      end: widget.a.avgScore / 100,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _prevValue = widget.a.avgScore / 100;
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_ScoreSummaryCard old) {
    super.didUpdateWidget(old);
    final newVal = widget.a.avgScore / 100;
    if ((newVal - _prevValue).abs() > 0.005) {
      _anim = Tween<double>(
        begin: _prevValue,
        end: newVal,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
      _prevValue = newVal;
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

  Color get _scoreColor {
    if (widget.a.avgScore >= 70) return AppColors.comfortable;
    if (widget.a.avgScore >= 40) return AppColors.moderate;
    return AppColors.critical;
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, child) => SizedBox(
                    width: 88,
                    height: 88,
                    child: CircularProgressIndicator(
                      value: _anim.value,
                      strokeWidth: 8,
                      backgroundColor: _scoreColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.a.avgScore}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _scoreColor,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      '/ 100',
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
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMFORT SCORE — ${widget.rangeLabel}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.subtitleGray,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  SensorLogic.overallLabel(
                    widget.a.avgScore >= 70
                        ? SensorStatus.comfortable
                        : widget.a.avgScore >= 40
                        ? SensorStatus.moderate
                        : SensorStatus.critical,
                  ),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _scoreColor,
                  ),
                ),
                const SizedBox(height: 8),
                // Mini stat row
                Row(
                  children: [
                    _MiniStat(
                      '${widget.a.totalRecords}',
                      'readings',
                      AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    _MiniStat(
                      '${widget.a.criticalCount}',
                      'critical',
                      AppColors.critical,
                    ),
                    const SizedBox(width: 12),
                    _MiniStat(
                      '${widget.a.moderateCount}',
                      'moderate',
                      AppColors.moderate,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _MiniStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.subtitleGray),
        ),
      ],
    );
  }
}

// ── 2. Distribution bar chart ─────────────────────────────────────────────────

class _DistributionCard extends StatelessWidget {
  final _Analytics a;
  final String rangeLabel;
  const _DistributionCard({
    required _Analytics analytics,
    required this.rangeLabel,
  }) : a = analytics;

  @override
  Widget build(BuildContext context) {
    final labels = ['Comfortable', 'Moderate', 'Critical'];
    final colors = [
      AppColors.comfortable,
      AppColors.moderate,
      AppColors.critical,
    ];
    final pcts = [a.comfortablePct, a.moderatePct, a.criticalPct];
    final counts = [a.comfortableCount, a.moderateCount, a.criticalCount];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Distribution — $rangeLabel',
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 20),
          // Bar chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (i) {
              final pct = (pcts[i] * 100).round();
              return Column(
                children: [
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors[i],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${counts[i]}x',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.subtitleGray,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    width: 56,
                    height: (110 * pcts[i]).clamp(4.0, 110.0),
                    decoration: BoxDecoration(
                      color: colors[i].withValues(
                        alpha: pcts[i] > 0 ? 0.85 : 0.18,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[i],
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.subtitleGray,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          // Stacked progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: List.generate(3, (i) {
                final flex = (pcts[i] * 100).round().clamp(1, 100);
                return Expanded(
                  flex: flex,
                  child: Container(
                    height: 8,
                    color: colors[i].withValues(
                      alpha: pcts[i] > 0 ? 0.85 : 0.15,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3. Per-sensor averages ────────────────────────────────────────────────────

class _SensorAveragesCard extends StatelessWidget {
  final _Analytics a;
  const _SensorAveragesCard({required _Analytics analytics}) : a = analytics;

  @override
  Widget build(BuildContext context) {
    final sensors = [
      _SensorAvgRow(
        icon: Icons.thermostat_rounded,
        iconColor: AppColors.tempIcon,
        iconBg: AppColors.tempBg,
        label: 'Temperature',
        value: '${a.avgTemp.toStringAsFixed(1)}°C',
        progress: SensorLogic.temperatureProgress(a.avgTemp),
        status: SensorLogic.temperatureStatus(a.avgTemp),
      ),
      _SensorAvgRow(
        icon: Icons.water_drop_rounded,
        iconColor: AppColors.humidIcon,
        iconBg: AppColors.humidBg,
        label: 'Humidity',
        value: '${a.avgHumidity.toStringAsFixed(0)}%',
        progress: SensorLogic.humidityProgress(a.avgHumidity),
        status: SensorLogic.humidityStatus(a.avgHumidity),
      ),
      _SensorAvgRow(
        icon: Icons.light_mode_rounded,
        iconColor: AppColors.lightIcon,
        iconBg: AppColors.lightBg,
        label: 'Light',
        value: '${a.avgLight.toStringAsFixed(0)} lux',
        progress: SensorLogic.lightProgress(a.avgLight),
        status: SensorLogic.lightStatus(a.avgLight),
      ),
      _SensorAvgRow(
        icon: Icons.air_rounded,
        iconColor: AppColors.gasIcon,
        iconBg: AppColors.gasBg,
        label: 'Air Quality',
        value: '${a.avgGas.toStringAsFixed(0)} ppm',
        progress: SensorLogic.gasProgress(a.avgGas),
        status: SensorLogic.gasStatus(a.avgGas),
      ),
      _SensorAvgRow(
        icon: Icons.volume_up_rounded,
        iconColor: AppColors.noiseIcon,
        iconBg: AppColors.noiseBg,
        label: 'Noise',
        value: '${a.avgNoise.toStringAsFixed(0)} dB',
        progress: SensorLogic.noiseProgress(a.avgNoise),
        status: SensorLogic.noiseStatus(a.avgNoise),
      ),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Average Sensor Readings', style: AppTextStyles.cardTitle),
          const SizedBox(height: 16),
          ...sensors.map(
            (s) =>
                Padding(padding: const EdgeInsets.only(bottom: 14), child: s),
          ),
        ],
      ),
    );
  }
}

class _SensorAvgRow extends StatefulWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label, value;
  final double progress;
  final StatusResult status;

  const _SensorAvgRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.progress,
    required this.status,
  });

  @override
  State<_SensorAvgRow> createState() => _SensorAvgRowState();
}

class _SensorAvgRowState extends State<_SensorAvgRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prevProgress = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = Tween<double>(
      begin: 0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _prevProgress = widget.progress.clamp(0.0, 1.0);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_SensorAvgRow old) {
    super.didUpdateWidget(old);
    final newP = widget.progress.clamp(0.0, 1.0);
    if ((newP - _prevProgress).abs() > 0.001) {
      _anim = Tween<double>(
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
    final color = SensorLogic.statusColor(widget.status.level);
    final bg = SensorLogic.statusBgColor(widget.status.level);

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: widget.iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(widget.icon, size: 18, color: widget.iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.titleNavy,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.status.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedBuilder(
                animation: _anim,
                builder: (context, child) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _anim.value,
                    minHeight: 5,
                    backgroundColor: bg,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 4. Per-sensor dominant status ────────────────────────────────────────────

class _SensorStatusCard extends StatelessWidget {
  final _Analytics a;
  const _SensorStatusCard({required _Analytics analytics}) : a = analytics;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _StatusRow('Temperature', a.dominantTempStatus, AppColors.tempIcon),
      _StatusRow('Humidity', a.dominantHumidStatus, AppColors.humidIcon),
      _StatusRow('Light', a.dominantLightStatus, AppColors.lightIcon),
      _StatusRow('Air Quality', a.dominantGasStatus, AppColors.gasIcon),
      _StatusRow('Noise', a.dominantNoiseStatus, AppColors.noiseIcon),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Most Frequent Status per Sensor',
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 16),
          ...rows.map(
            (r) =>
                Padding(padding: const EdgeInsets.only(bottom: 10), child: r),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String sensor, fbStatus;
  final Color iconColor;
  const _StatusRow(this.sensor, this.fbStatus, this.iconColor);

  @override
  Widget build(BuildContext context) {
    final result = SensorLogic.fromFirebaseStatus(
      fbStatus,
      _displayLabel(fbStatus),
    );
    final color = SensorLogic.statusColor(result.level);
    final bg = SensorLogic.statusBgColor(result.level);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              sensor,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.titleNavy,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            result.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  String _displayLabel(String s) {
    switch (s.toUpperCase()) {
      case 'COMFORTABLE':
        return 'Comfortable';
      case 'MODERATE':
        return 'Moderate';
      case 'CRITICAL':
        return 'Critical';
      default:
        return s;
    }
  }
}

// ── 5. Recommendations ────────────────────────────────────────────────────────

class _RecommendationsCard extends StatelessWidget {
  final ClassroomModel data;
  const _RecommendationsCard({required this.data});

  List<String> _recs() {
    final out = <String>[];
    if (SensorLogic.temperatureStatusFromModel(data).level !=
        SensorStatus.comfortable) {
      out.add(
        'Adjust air conditioning to maintain 25–28°C for optimal comfort.',
      );
    }
    if (SensorLogic.humidityStatusFromModel(data).level !=
        SensorStatus.comfortable) {
      out.add(
        'Use a humidifier or dehumidifier to keep humidity between 60–70%.',
      );
    }
    if (SensorLogic.lightStatusFromModel(data).level !=
        SensorStatus.comfortable) {
      out.add('Adjust blinds or lighting to reach the comfortable range.');
    }
    if (SensorLogic.gasStatusFromModel(data).level !=
        SensorStatus.comfortable) {
      out.add('Improve ventilation to reduce gas levels.');
    }
    if (SensorLogic.noiseStatusFromModel(data).level !=
        SensorStatus.comfortable) {
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

// ── Shared ────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 60),
    child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
  );
}

class _EmptyHistoryState extends StatelessWidget {
  final String rangeLabel;
  const _EmptyHistoryState({required this.rangeLabel});

  String get _message {
    switch (rangeLabel) {
      case 'Weekly':
        return 'No data for the past 7 days yet.\nKeep the app running to build weekly history.';
      case '24 hr':
        return 'No data for the past 24 hours.\nData accumulates as the app runs.';
      default:
        return 'No data for this range yet.\nKeep the app open — readings are saved automatically.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: AppColors.accent,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No data for "$rangeLabel"',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.titleNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.subtitleGray,
              ),
            ),
          ],
        ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
