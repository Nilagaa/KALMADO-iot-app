import 'package:flutter/material.dart';
import '../models/classroom_model.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/sensor_logic.dart';
import '../widgets/alert_tile.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

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
        return _AlertsBody(data: data);
      },
    );
  }
}

class _AlertsBody extends StatelessWidget {
  final ClassroomModel data;
  const _AlertsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final alerts = SensorLogic.generateAlerts(data);
    final criticalCount = alerts
        .where((a) => a['level'] == SensorStatus.critical)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alerts', style: AppTextStyles.pageTitle),
                  SizedBox(height: 2),
                  Text(
                    'Real-time notifications',
                    style: AppTextStyles.pageSubtitle,
                  ),
                ],
              ),
              const Spacer(),
              if (criticalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.criticalBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        color: AppColors.critical,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$criticalCount Critical',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.critical,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (alerts.isEmpty)
            const _EmptyAlerts()
          else
            ...alerts.map(
              (a) => AlertTile(
                sensor: a['sensor'] as String,
                label: a['label'] as String,
                description: a['description'] as String,
                level: a['level'] as SensorStatus,
                time: a['time'] as DateTime,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts();

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
                color: AppColors.comfortableBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.comfortable,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'All Clear',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.titleNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'All sensors are within comfortable range.',
              style: TextStyle(fontSize: 13, color: AppColors.subtitleGray),
            ),
          ],
        ),
      ),
    );
  }
}
