/// Represents a single alert entry stored in Firebase Realtime Database /alerts.
class AlertModel {
  final String id;
  final String sensor; // e.g. "Temperature", "Humidity"
  final String label; // e.g. "Too Hot", "Slightly Dry"
  final String description;
  final String status; // "CRITICAL" or "MODERATE"
  final int savedAt; // real wall-clock Unix seconds (app time)

  const AlertModel({
    required this.id,
    required this.sensor,
    required this.label,
    required this.description,
    required this.status,
    required this.savedAt,
  });

  factory AlertModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return AlertModel(
      id: id,
      sensor: _str(map['sensor']),
      label: _str(map['label']),
      description: _str(map['description']),
      status: _str(map['status']),
      savedAt: _int(map['savedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'sensor': sensor,
    'label': label,
    'description': description,
    'status': status,
    'savedAt': savedAt,
  };

  static String _str(dynamic v) => v?.toString() ?? '';
  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
