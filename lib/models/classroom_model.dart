/// Model representing live classroom sensor data from Firebase Realtime Database.
class ClassroomModel {
  final double temperature;
  final double humidity;
  final double light;
  final double gas;
  final double noise;

  // Per-sensor status strings sent directly by the ESP32/Arduino
  final String temperatureStatus;
  final String humidityStatus;
  final String lightStatus;
  final String gasStatus;
  final String noiseStatus;

  // Overall room status
  final String status;
  final int timestamp;

  const ClassroomModel({
    required this.temperature,
    required this.humidity,
    required this.light,
    required this.gas,
    required this.noise,
    required this.temperatureStatus,
    required this.humidityStatus,
    required this.lightStatus,
    required this.gasStatus,
    required this.noiseStatus,
    required this.status,
    required this.timestamp,
  });

  /// Parse safely from Firebase snapshot map.
  factory ClassroomModel.fromMap(Map<dynamic, dynamic> map) {
    return ClassroomModel(
      temperature: _toDouble(map['temperature']),
      humidity: _toDouble(map['humidity']),
      light: _toDouble(map['light']),
      gas: _toDouble(map['gas']),
      noise: _toDouble(map['noise']),
      temperatureStatus: _toStr(map['temperatureStatus']),
      humidityStatus: _toStr(map['humidityStatus']),
      lightStatus: _toStr(map['lightStatus']),
      gasStatus: _toStr(map['gasStatus']),
      noiseStatus: _toStr(map['noiseStatus']),
      status: _toStr(map['status']),
      timestamp: _toInt(map['timestamp']),
    );
  }

  /// Serialize to a plain map for writing to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'light': light,
      'gas': gas,
      'noise': noise,
      'temperatureStatus': temperatureStatus,
      'humidityStatus': humidityStatus,
      'lightStatus': lightStatus,
      'gasStatus': gasStatus,
      'noiseStatus': noiseStatus,
      'status': status,
      'timestamp': timestamp,
      // Also store a Firestore server-readable DateTime for easy querying
      'recordedAt': DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
    };
  }

  /// Empty/loading state before Firebase responds.
  factory ClassroomModel.empty() {
    return const ClassroomModel(
      temperature: 0,
      humidity: 0,
      light: 0,
      gas: 0,
      noise: 0,
      temperatureStatus: 'LOADING',
      humidityStatus: 'LOADING',
      lightStatus: 'LOADING',
      gasStatus: 'LOADING',
      noiseStatus: 'LOADING',
      status: 'LOADING',
      timestamp: 0,
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

  static String _toStr(dynamic v) {
    if (v == null) return 'UNKNOWN';
    return v.toString().toUpperCase().trim();
  }
}
