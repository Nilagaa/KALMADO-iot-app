import 'dart:async';
import 'package:flutter/material.dart';
import '../models/classroom_model.dart';
import '../models/sensor_type.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/sensor_logic.dart';
import '../widgets/overall_status_card.dart';
import '../widgets/sensor_card.dart';
import '../widgets/noise_card.dart';
import '../widgets/score_card.dart';
import '../widgets/sensor_guide_card.dart';
import '../widgets/esp32_status_banner.dart';
import 'sensor_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ClassroomModel _data = ClassroomModel.empty();
  bool _loading = true;

  StreamSubscription<ClassroomModel>? _sub;

  // ESP32 status banner callback — set when banner registers itself
  void Function()? _notifyEsp32;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _sub?.cancel();
    _sub = FirebaseService.instance.classroomStream.listen((data) {
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
        // Notify ESP32 banner that a fresh update arrived
        _notifyEsp32?.call();
      }
    });
  }

  /// Pull-to-refresh — re-subscribes the stream to force a fresh read.
  Future<void> _onRefresh() async {
    setState(() => _loading = true);
    _subscribe();
    // Wait up to 3 s for first data
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_loading) break;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    final overall = SensorLogic.overallStatus(_data);
    final score = SensorLogic.comfortScore(_data);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header + ESP32 status ──────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Monitor', style: AppTextStyles.pageTitle),
                    SizedBox(height: 2),
                    Text(
                      'Real-time classroom environment',
                      style: AppTextStyles.pageSubtitle,
                    ),
                  ],
                ),
                const Spacer(),
                Esp32StatusBanner(onRegister: (fn) => _notifyEsp32 = fn),
              ],
            ),

            const SizedBox(height: 16),

            // ── Sensor guide (expandable) ──────────────────────────────────
            const SensorGuideCard(),

            const SizedBox(height: 20),

            // ── Overall status card ────────────────────────────────────────
            OverallStatusCard(status: overall, timestamp: _data.timestamp),
            const SizedBox(height: 20),

            // ── Sensor grid ────────────────────────────────────────────────
            _SensorGrid(data: _data, onTap: _openDetail),
            const SizedBox(height: 20),

            // ── Noise card ─────────────────────────────────────────────────
            NoiseCard(
              noiseDb: _data.noise,
              status: SensorLogic.noiseStatusFromModel(_data),
              onTap: () => _openDetail(context, SensorType.noise),
            ),
            const SizedBox(height: 20),

            // ── Score card ─────────────────────────────────────────────────
            ScoreCard(score: score),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, SensorType type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SensorDetailScreen(sensorType: type)),
    );
  }
}

// ── Sensor grid ───────────────────────────────────────────────────────────────

class _SensorGrid extends StatelessWidget {
  final ClassroomModel data;
  final void Function(BuildContext, SensorType) onTap;
  const _SensorGrid({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sensors = [
      _Def(
        icon: Icons.thermostat_rounded,
        label: 'Temperature',
        value: data.temperature.toStringAsFixed(1),
        unit: '°C',
        iconColor: AppColors.tempIcon,
        iconBg: AppColors.tempBg,
        status: SensorLogic.temperatureStatusFromModel(data),
        progress: SensorLogic.temperatureProgress(data.temperature),
        type: SensorType.temperature,
      ),
      _Def(
        icon: Icons.water_drop_rounded,
        label: 'Humidity',
        value: data.humidity.toStringAsFixed(0),
        unit: '%',
        iconColor: AppColors.humidIcon,
        iconBg: AppColors.humidBg,
        status: SensorLogic.humidityStatusFromModel(data),
        progress: SensorLogic.humidityProgress(data.humidity),
        type: SensorType.humidity,
      ),
      _Def(
        icon: Icons.light_mode_rounded,
        label: 'Light',
        value: data.light.toStringAsFixed(0),
        unit: 'lux',
        iconColor: AppColors.lightIcon,
        iconBg: AppColors.lightBg,
        status: SensorLogic.lightStatusFromModel(data),
        progress: SensorLogic.lightProgress(data.light),
        type: SensorType.light,
      ),
      _Def(
        icon: Icons.air_rounded,
        label: 'Air Quality',
        value: data.gas.toStringAsFixed(0),
        unit: 'ppm',
        iconColor: AppColors.gasIcon,
        iconBg: AppColors.gasBg,
        status: SensorLogic.gasStatusFromModel(data),
        progress: SensorLogic.gasProgress(data.gas),
        type: SensorType.gas,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 0.9,
      children: sensors
          .map(
            (s) => SensorCard(
              icon: s.icon,
              label: s.label,
              value: s.value,
              unit: s.unit,
              iconColor: s.iconColor,
              iconBg: s.iconBg,
              status: s.status,
              progress: s.progress,
              onTap: () => onTap(context, s.type),
            ),
          )
          .toList(),
    );
  }
}

class _Def {
  final IconData icon;
  final String label, value, unit;
  final Color iconColor, iconBg;
  final StatusResult status;
  final double progress;
  final SensorType type;

  const _Def({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.iconColor,
    required this.iconBg,
    required this.status,
    required this.progress,
    required this.type,
  });
}
