import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/sensor_logic.dart';
import '../widgets/alert_tile.dart';

/// Alerts screen — reads exclusively from Firebase /alerts node.
/// Clear All removes only /alerts — classroom and classroom_history are untouched.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<AlertModel> _alerts = [];
  bool _clearing = false;

  /// When false: stream is paused and new alerts are not pushed to Firebase.
  bool _notificationsEnabled = true;

  StreamSubscription<List<AlertModel>>? _sub;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startListening();
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  void _startListening() {
    _sub?.cancel();
    _sub = FirebaseService.instance.alertsStream.listen((list) {
      if (mounted) setState(() => _alerts = list);
    });
  }

  void _toggleNotifications(bool value) {
    setState(() => _notificationsEnabled = value);
    // Tell the service to pause/resume pushing new alerts
    FirebaseService.instance.setAlertsEnabled(value);
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.criticalBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                color: AppColors.critical,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Clear All Alerts?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B4A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All notifications will be permanently dismissed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF7A8FA6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF7A8FA6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.critical,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    setState(() => _clearing = true);
    await FirebaseService.instance.clearAllAlerts();
    if (mounted) setState(() => _clearing = false);
  }

  Future<void> _onRefresh() async {
    _startListening();
    // Brief delay so the indicator is visible
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount = _alerts.where((a) => a.status == 'CRITICAL').length;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                    if (_alerts.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _clearing ? null : _clearAll,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              _clearing
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.accent,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.clear_all_rounded,
                                      color: AppColors.accent,
                                      size: 16,
                                    ),
                              const SizedBox(width: 4),
                              const Text(
                                'Clear All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Notification toggle ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _notificationsEnabled
                          ? AppColors.accentLight
                          : const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _notificationsEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      size: 20,
                      color: _notificationsEnabled
                          ? AppColors.accent
                          : AppColors.subtitleGray,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.titleNavy,
                          ),
                        ),
                        Text(
                          _notificationsEnabled
                              ? 'Receiving sensor alerts'
                              : 'Alerts paused',
                          style: TextStyle(
                            fontSize: 11,
                            color: _notificationsEnabled
                                ? AppColors.comfortable
                                : AppColors.subtitleGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    activeThumbColor: AppColors.accent,
                    activeTrackColor: AppColors.accentLight,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Alert list or empty/paused state ──────────────────────────────
            if (!_notificationsEnabled)
              const _PausedState()
            else if (_alerts.isEmpty)
              const _EmptyAlerts()
            else
              ..._alerts.map(
                (a) => AlertTile(
                  sensor: a.sensor,
                  label: a.label,
                  description: a.description,
                  level: a.status == 'CRITICAL'
                      ? SensorStatus.critical
                      : SensorStatus.moderate,
                  time: DateTime.fromMillisecondsSinceEpoch(a.savedAt * 1000),
                ),
              ),
          ],
        ),
      ), // SingleChildScrollView
    ); // RefreshIndicator
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

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
              'No alerts. Classroom is comfortable.',
              style: TextStyle(fontSize: 13, color: AppColors.subtitleGray),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Paused state ──────────────────────────────────────────────────────────────

class _PausedState extends StatelessWidget {
  const _PausedState();

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
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.notifications_paused_rounded,
                color: AppColors.subtitleGray,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notifications Paused',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.titleNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Toggle the switch above to resume alerts.',
              style: TextStyle(fontSize: 13, color: AppColors.subtitleGray),
            ),
          ],
        ),
      ),
    );
  }
}
