/// Model representing live classroom sensor data from Firebase Realtime Database.
class ClassroomModel {
  final double temperature;
  final double humidity;
  final double light;
  final double gas;
  final double noise;
  final String status;
  final int timestamp;

  const ClassroomModel({
    required this.temperature,
    required this.humidity,
    required this.light,
    required this.gas,
    required this.noise,
    required this.status,
    required this.timestamp,
  });

  /// Parse safely from Firebase snapshot map.
  factory ClassroomModel.fromMap(Map<dynamic, dynamic> map) {
    return ClassroomModel(
      temperature: _toDouble(map['temperature']),
      humidity:    _toDouble(map['humidity']),
      light:       _toDouble(map['light']),
      gas:         _toDouble(map['gas']),
      noise:       _toDouble(map['noise']),
      status:      (map['status'] ?? 'UNKNOWN').toString(),
      timestamp:   _toInt(map['timestamp']),
    );
  }

  /// Empty/loading state before Firebase responds.
  factory ClassroomModel.empty() {
    return const ClassroomModel(
      temperature: 0,
      humidity:    0,
      light:       0,
      gas:         0,
      noise:       0,
      status:      'LOADING',
      timestamp:   0,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
