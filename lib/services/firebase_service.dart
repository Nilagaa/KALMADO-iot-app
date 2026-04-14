import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/classroom_model.dart';
import '../models/alert_model.dart';
import '../utils/sensor_logic.dart';

/// Singleton service for Firebase.
///
/// Data separation:
///   classroom         → RTDB  → Home screen (live only)
///   classroom_history → Firestore → Analytics screen (history only)
///   alerts            → RTDB  → Alerts screen (notifications only)
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  // ── References ─────────────────────────────────────────────────────────────

  final DatabaseReference _classroomRef = FirebaseDatabase.instance.ref(
    'classroom',
  );

  final DatabaseReference _alertsRef = FirebaseDatabase.instance.ref('alerts');

  final CollectionReference<Map<String, dynamic>> _historyCol =
      FirebaseFirestore.instance.collection('classroom_history');

  // ── State ──────────────────────────────────────────────────────────────────

  int _lastSavedTimestamp = 0;
  // Tracks last alert label per sensor to avoid duplicate pushes
  final Map<String, String> _lastAlertLabel = {};
  // Controls whether new alerts are pushed to /alerts node
  bool _alertsEnabled = true;

  StreamSubscription<ClassroomModel>? _loggerSub;

  // ══════════════════════════════════════════════════════════════════════════
  // CLASSROOM — live sensor stream (Home screen only)
  // ══════════════════════════════════════════════════════════════════════════

  Stream<ClassroomModel> get classroomStream {
    return _classroomRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return ClassroomModel.empty();
      return ClassroomModel.fromMap(data as Map<dynamic, dynamic>);
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ALERTS — read / write / clear  (Alerts screen only)
  // ══════════════════════════════════════════════════════════════════════════

  /// Real-time stream of all alerts from /alerts node, newest first.
  Stream<List<AlertModel>> get alertsStream {
    return _alertsRef.onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null) return <AlertModel>[];

      final list = <AlertModel>[];
      if (raw is Map) {
        raw.forEach((key, value) {
          if (value is Map) {
            try {
              list.add(AlertModel.fromMap(key.toString(), value));
            } catch (_) {}
          }
        });
      }
      // Sort newest first
      list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return list;
    });
  }

  /// Removes ALL entries from /alerts — does NOT touch classroom or classroom_history.
  Future<void> clearAllAlerts() async {
    try {
      await _alertsRef.remove();
      _lastAlertLabel.clear();
    } catch (_) {}
  }

  /// Enable or disable pushing new alerts to /alerts.
  /// When disabled, sensor data still saves to classroom_history normally.
  void setAlertsEnabled(bool enabled) {
    _alertsEnabled = enabled;
    if (!enabled) _lastAlertLabel.clear();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTO-LOGGER — runs in background, feeds both classroom_history + alerts
  // ══════════════════════════════════════════════════════════════════════════

  /// Call once at app startup after Firebase.initializeApp().
  /// On every new ESP32 reading:
  ///   1. Saves snapshot to Firestore classroom_history
  ///   2. Pushes any MODERATE/CRITICAL sensor alerts to /alerts
  void startHistoryLogging() {
    _loggerSub?.cancel();
    _loggerSub = classroomStream.listen((model) async {
      if (model.timestamp == 0) return;
      if (model.timestamp == _lastSavedTimestamp) return;
      if (model.status == 'LOADING') return;

      _lastSavedTimestamp = model.timestamp;

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final nowSec = nowMs ~/ 1000;

      // 1. Save to classroom_history (Firestore)
      try {
        final data = model.toMap();
        data['savedAt'] = nowSec;
        data['recordedAt'] = Timestamp.fromMillisecondsSinceEpoch(nowMs);
        await _historyCol.doc(nowMs.toString()).set(data);
      } catch (_) {}

      // 2. Push alerts to /alerts (RTDB) for non-comfortable sensors
      if (_alertsEnabled) _pushAlertsIfNeeded(model, nowSec);
    });
  }

  void stopHistoryLogging() {
    _loggerSub?.cancel();
    _loggerSub = null;
  }

  /// Checks each sensor; if status changed to MODERATE/CRITICAL, pushes to /alerts.
  void _pushAlertsIfNeeded(ClassroomModel model, int nowSec) {
    final generated = SensorLogic.generateAlerts(model);

    // Track which sensors are currently alerting
    final activeSensors = <String>{};

    for (final a in generated) {
      final sensor = a['sensor'] as String;
      final label = a['label'] as String;
      final level = a['level'] as SensorStatus;
      activeSensors.add(sensor);

      // Only push when label changes (avoids duplicate alerts every second)
      if (_lastAlertLabel[sensor] == label) continue;
      _lastAlertLabel[sensor] = label;

      try {
        final newRef = _alertsRef.push();
        newRef.set(
          AlertModel(
            id: newRef.key ?? '',
            sensor: sensor,
            label: label,
            description: a['description'] as String,
            status: level == SensorStatus.critical ? 'CRITICAL' : 'MODERATE',
            savedAt: nowSec,
          ).toMap(),
        );
      } catch (_) {}
    }

    // Reset tracking for sensors that returned to comfortable
    for (final key in _lastAlertLabel.keys.toList()) {
      if (!activeSensors.contains(key)) {
        _lastAlertLabel.remove(key);
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CLASSROOM_HISTORY — analytics fetch  (Analytics screen only)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<ClassroomModel>> fetchHistory(Duration duration) async {
    try {
      final snapshot = await _historyCol.get();
      if (snapshot.docs.isEmpty) return [];

      final cutoffMs = DateTime.now().subtract(duration).millisecondsSinceEpoch;

      // Collect records with their resolved real-time ms for sorting
      final entries = <({ClassroomModel model, int ms})>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final docMs = _resolveDocMs(doc.id, data);
          if (docMs == null) continue;
          if (docMs >= cutoffMs) {
            entries.add((model: ClassroomModel.fromMap(data), ms: docMs));
          }
        } catch (_) {}
      }

      // Sort by real wall-clock time ascending
      entries.sort((a, b) => a.ms.compareTo(b.ms));
      return entries.map((e) => e.model).toList();
    } catch (_) {
      return [];
    }
  }

  int? _resolveDocMs(String docId, Map<String, dynamic> data) {
    // 1. savedAt (int or double) — real wall-clock Unix seconds set by the app
    final savedAt = data['savedAt'];
    if (savedAt != null) {
      final secs = savedAt is int
          ? savedAt
          : savedAt is double
          ? savedAt.toInt()
          : int.tryParse(savedAt.toString());
      // Must be after Jan 1 2020 to be a real timestamp
      if (secs != null && secs > 1_577_836_800) return secs * 1000;
    }

    // 2. recordedAt as Firestore Timestamp — set by the app logger
    if (data['recordedAt'] is Timestamp) {
      final ms = (data['recordedAt'] as Timestamp).millisecondsSinceEpoch;
      if (ms > 1_577_836_800_000) return ms;
    }

    // 3. Document ID that is epoch millis (13 digits, after Jan 2020)
    final idMs = int.tryParse(docId);
    if (idMs != null && idMs > 1_577_836_800_000) return idMs;

    // 4. Old ESP32-uptime-keyed docs (e.g. 7254674) — no real time, exclude
    return null;
  }
}
