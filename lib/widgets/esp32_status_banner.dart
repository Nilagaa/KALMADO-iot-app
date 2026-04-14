import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

enum _Esp32State { checking, online, reconnecting, offline }

/// Monitors ESP32 connection freshness.
/// The parent calls [_onNewData] every time a classroom snapshot arrives.
/// Uses wall-clock time to detect stale data — works correctly even when
/// the ESP32 is powered off mid-session.
class Esp32StatusBanner extends StatefulWidget {
  final void Function(void Function()) onRegister;
  const Esp32StatusBanner({super.key, required this.onRegister});

  @override
  State<Esp32StatusBanner> createState() => _Esp32StatusBannerState();
}

class _Esp32StatusBannerState extends State<Esp32StatusBanner>
    with SingleTickerProviderStateMixin {
  // Wall-clock time of the last received classroom update
  DateTime? _lastSeen;

  // App start time — used for the initial grace period
  final DateTime _startedAt = DateTime.now();

  _Esp32State _state = _Esp32State.checking;
  bool _popupShown = false;

  Timer? _watchdog;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Sensor sends every ~1 second
  // → reconnecting after 3 s of silence
  // → offline after 6 s of silence
  // → initial grace period: 8 s before showing offline on first launch
  static const _reconnectingAfter = Duration(seconds: 3);
  static const _offlineAfter = Duration(seconds: 6);
  static const _gracePeriod = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    widget.onRegister(_onNewData);

    // Check every 2 s — tight enough to catch a 1-second sensor going silent
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) => _check());
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Called by HomeScreen every time a new classroom snapshot arrives ────────

  void _onNewData() {
    final wasOffline =
        _state == _Esp32State.offline || _state == _Esp32State.reconnecting;
    _lastSeen = DateTime.now();
    _popupShown = false; // allow popup again next time it goes offline

    if (mounted) setState(() => _state = _Esp32State.online);

    // If it just came back, briefly hold the "online" state visually
    if (wasOffline) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() {});
      });
    }
  }

  // ── Watchdog ─────────────────────────────────────────────────────────────────

  void _check() {
    final now = DateTime.now();

    // No data received yet
    if (_lastSeen == null) {
      final sinceStart = now.difference(_startedAt);
      // Give the app a grace period on first launch before declaring offline
      final newState = sinceStart >= _gracePeriod
          ? _Esp32State.offline
          : _Esp32State.checking;
      _applyState(newState, now);
      return;
    }

    // Data was received before — check how stale it is
    final age = now.difference(_lastSeen!);
    final _Esp32State newState;
    if (age >= _offlineAfter) {
      newState = _Esp32State.offline;
    } else if (age >= _reconnectingAfter) {
      newState = _Esp32State.reconnecting;
    } else {
      newState = _Esp32State.online;
    }
    _applyState(newState, now);
  }

  void _applyState(_Esp32State newState, DateTime now) {
    if (newState != _state && mounted) {
      setState(() => _state = newState);
    }
    // Show popup once per offline event
    if (_state == _Esp32State.offline && !_popupShown && mounted) {
      _popupShown = true;
      _showOfflineDialog();
    }
  }

  // ── Offline dialog ────────────────────────────────────────────────────────────

  void _showOfflineDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
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
                Icons.wifi_off_rounded,
                color: AppColors.critical,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ESP32 Offline',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B4A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check the connection for ESP32.\nNo new sensor data is being received.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF7A8FA6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _Esp32State.checking:
        return FadeTransition(
          opacity: _pulseAnim,
          child: const _StatusChip(
            color: AppColors.subtitleGray,
            bg: Color(0xFFF0F4F8),
            icon: Icons.wifi_find_rounded,
            label: 'Connecting...',
          ),
        );

      case _Esp32State.online:
        return const _StatusChip(
          color: AppColors.comfortable,
          bg: AppColors.comfortableBg,
          icon: Icons.wifi_rounded,
          label: 'ESP32 Online',
        );

      case _Esp32State.reconnecting:
        return FadeTransition(
          opacity: _pulseAnim,
          child: const _StatusChip(
            color: AppColors.moderate,
            bg: AppColors.moderateBg,
            icon: Icons.wifi_find_rounded,
            label: 'Reconnecting...',
          ),
        );

      case _Esp32State.offline:
        return const _StatusChip(
          color: AppColors.critical,
          bg: AppColors.criticalBg,
          icon: Icons.wifi_off_rounded,
          label: 'ESP32 Offline',
        );
    }
  }
}

class _StatusChip extends StatelessWidget {
  final Color color, bg;
  final IconData icon;
  final String label;
  const _StatusChip({
    required this.color,
    required this.bg,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
