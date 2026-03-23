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
import 'sensor_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load data.\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.critical, fontSize: 13),
            ),
          );
        }
        final data = snapshot.data ?? ClassroomModel.empty();
        return _HomeBody(data: data);
      },
    );
  }
}

class _HomeBody extends StatelessWidget {
  final ClassroomModel data;
  const _HomeBody({required this.data});

  void _openDetail(BuildContext context, SensorType type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SensorDetailScreen(sensorType: type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overall = SensorLogic.overallStatus(data);
    final score = SensorLogic.comfortScore(data);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Monitor', style: AppTextStyles.pageTitle),
          const SizedBox(height: 2),
          const Text(
            'Real-time classroom environment',
            style: AppTextStyles.pageSubtitle,
          ),
          const SizedBox(height: 20),
          OverallStatusCard(status: overall, timestamp: data.timestamp),
          const SizedBox(height: 20),
          _SensorGrid(data: data, onTap: _openDetail),
          const SizedBox(height: 20),
          NoiseCard(
            noiseDb: data.noise,
            onTap: () => _openDetail(context, SensorType.noise),
          ),
          const SizedBox(height: 20),
          ScoreCard(score: score),
        ],
      ),
    );
  }
}

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
        unit: '\u00b0C',
        iconColor: AppColors.tempIcon,
        iconBg: AppColors.tempBg,
        status: SensorLogic.temperatureStatus(data.temperature),
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
        status: SensorLogic.humidityStatus(data.humidity),
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
        status: SensorLogic.lightStatus(data.light),
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
        status: SensorLogic.gasStatus(data.gas),
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
