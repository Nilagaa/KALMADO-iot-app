import 'package:flutter/material.dart';
import '../models/classroom_model.dart';
import '../models/sensor_detail_config.dart';
import 'app_colors.dart';

enum SensorStatus { comfortable, moderate, critical }

class StatusResult {
  final SensorStatus level;
  final String label;
  const StatusResult(this.level, this.label);
}

class SensorLogic {
  SensorLogic._();

  // ── Firebase status string → StatusResult ──────────────────────────────────
  // Converts the raw Firebase status string (e.g. "COMFORTABLE", "MODERATE",
  // "CRITICAL") into a typed StatusResult with a display label.
  // This is the PRIMARY path used by the UI — no recalculation needed.

  static StatusResult fromFirebaseStatus(String fbStatus, String displayLabel) {
    switch (fbStatus.toUpperCase().trim()) {
      case 'COMFORTABLE':
        return StatusResult(SensorStatus.comfortable, displayLabel);
      case 'MODERATE':
        return StatusResult(SensorStatus.moderate, displayLabel);
      case 'CRITICAL':
        return StatusResult(SensorStatus.critical, displayLabel);
      default:
        // Fallback: treat unknown as moderate so it's visible
        return StatusResult(SensorStatus.moderate, displayLabel);
    }
  }

  // ── Per-sensor Firebase status helpers ────────────────────────────────────
  // These read the status string from the model and return a StatusResult
  // with a human-readable label derived from the value + status.

  static StatusResult temperatureStatusFromModel(ClassroomModel m) {
    // Use Flutter threshold as source of truth — overrides ESP32 status if contradictory
    final fallback = temperatureStatus(m.temperature);
    final label = _temperatureLabel(
      m.temperature,
      fallback.level == SensorStatus.comfortable
          ? 'COMFORTABLE'
          : fallback.level == SensorStatus.moderate
          ? 'MODERATE'
          : 'CRITICAL',
    );
    return StatusResult(fallback.level, label);
  }

  static StatusResult humidityStatusFromModel(ClassroomModel m) {
    // Humidity: trust ESP32 status directly — ESP32 thresholds differ from Flutter fallback
    final label = _humidityLabel(m.humidity, m.humidityStatus);
    return fromFirebaseStatus(m.humidityStatus, label);
  }

  static StatusResult lightStatusFromModel(ClassroomModel m) {
    final fallback = lightStatus(m.light);
    final label = _lightLabel(
      m.light,
      fallback.level == SensorStatus.comfortable
          ? 'COMFORTABLE'
          : fallback.level == SensorStatus.moderate
          ? 'MODERATE'
          : 'CRITICAL',
    );
    return StatusResult(fallback.level, label);
  }

  static StatusResult gasStatusFromModel(ClassroomModel m) {
    final fallback = gasStatus(m.gas);
    final label = _gasLabel(
      m.gas,
      fallback.level == SensorStatus.comfortable
          ? 'COMFORTABLE'
          : fallback.level == SensorStatus.moderate
          ? 'MODERATE'
          : 'CRITICAL',
    );
    return StatusResult(fallback.level, label);
  }

  static StatusResult noiseStatusFromModel(ClassroomModel m) {
    final fallback = noiseStatus(m.noise);
    final label = _noiseLabel(
      m.noise,
      fallback.level == SensorStatus.comfortable
          ? 'COMFORTABLE'
          : fallback.level == SensorStatus.moderate
          ? 'MODERATE'
          : 'CRITICAL',
    );
    return StatusResult(fallback.level, label);
  }

  // ── Display label helpers (value-aware) ───────────────────────────────────

  static String _temperatureLabel(double v, String fbStatus) {
    switch (fbStatus.toUpperCase().trim()) {
      case 'COMFORTABLE':
        return 'Comfortable';
      case 'MODERATE':
        return v < 25 ? 'Slightly Cold' : 'Slightly Warm';
      case 'CRITICAL':
        return v < 22 ? 'Too Cold' : 'Too Hot';
      default:
        return fbStatus;
    }
  }

  static String _humidityLabel(double v, String fbStatus) {
    switch (fbStatus.toUpperCase().trim()) {
      case 'COMFORTABLE':
        return 'Comfortable';
      case 'MODERATE':
        return v < 60 ? 'Slightly Dry' : 'Slightly Humid';
      case 'CRITICAL':
        return v < 40 ? 'Too Dry' : 'Too Humid';
      default:
        return fbStatus;
    }
  }

  // Light is normalized 0–100 by Arduino
  static String _lightLabel(double v, String fbStatus) {
    switch (fbStatus.toUpperCase().trim()) {
      case 'COMFORTABLE':
        return 'Comfortable';
      case 'MODERATE':
        return v <= 40 ? 'Slightly Dim' : 'Slightly Bright';
      case 'CRITICAL':
        return v <= 20 ? 'Too Dark' : 'Too Bright';
      default:
        return fbStatus;
    }
  }

  // Gas is normalized 0–100 by Arduino
  static String _gasLabel(double v, String fbStatus) {
    switch (fbStatus.toUpperCase().trim()) {
      case 'COMFORTABLE':
        return 'Clean';
      case 'MODERATE':
        return 'Needs Monitoring';
      case 'CRITICAL':
        return 'Poor Air Quality';
      default:
        return fbStatus;
    }
  }

  // Noise is normalized 0–100 by Arduino
  static String _noiseLabel(double v, String fbStatus) {
    switch (fbStatus.toUpperCase().trim()) {
      case 'COMFORTABLE':
        return 'Quiet';
      case 'MODERATE':
        return 'Distracting';
      case 'CRITICAL':
        return 'Too Loud';
      default:
        return fbStatus;
    }
  }

  // ── Fallback threshold logic (matches latest Arduino code) ────────────────
  // Used only when Firebase status fields are missing/unknown,
  // or for interpretation text and suggestions on the detail screen.

  static StatusResult temperatureStatus(double v) {
    if (v < 22) {
      return const StatusResult(SensorStatus.critical, 'Too Cold');
    }
    if (v <= 24) {
      return const StatusResult(SensorStatus.moderate, 'Slightly Cold');
    }
    if (v <= 28) {
      return const StatusResult(SensorStatus.comfortable, 'Comfortable');
    }
    if (v <= 31) {
      return const StatusResult(SensorStatus.moderate, 'Slightly Warm');
    }
    return const StatusResult(SensorStatus.critical, 'Too Hot');
  }

  static StatusResult humidityStatus(double v) {
    if (v < 40) {
      return const StatusResult(SensorStatus.critical, 'Too Dry');
    }
    if (v <= 59) {
      return const StatusResult(SensorStatus.moderate, 'Slightly Dry');
    }
    if (v <= 70) {
      return const StatusResult(SensorStatus.comfortable, 'Comfortable');
    }
    if (v <= 85) {
      return const StatusResult(SensorStatus.moderate, 'Slightly Humid');
    }
    return const StatusResult(SensorStatus.critical, 'Too Humid');
  }

  // Light: normalized 0–100
  static StatusResult lightStatus(double v) {
    if (v <= 20) {
      return const StatusResult(SensorStatus.critical, 'Too Dark');
    }
    if (v <= 40) {
      return const StatusResult(SensorStatus.moderate, 'Slightly Dim');
    }
    if (v <= 80) {
      return const StatusResult(SensorStatus.comfortable, 'Comfortable');
    }
    if (v <= 100) {
      return const StatusResult(SensorStatus.critical, 'Too Bright');
    }
    return const StatusResult(SensorStatus.critical, 'Too Bright');
  }

  // Gas: normalized 0–100
  static StatusResult gasStatus(double v) {
    if (v <= 20) {
      return const StatusResult(SensorStatus.comfortable, 'Clean');
    }
    if (v <= 50) {
      return const StatusResult(SensorStatus.moderate, 'Needs Monitoring');
    }
    return const StatusResult(SensorStatus.critical, 'Poor Air Quality');
  }

  // Noise: normalized 0–100
  static StatusResult noiseStatus(double v) {
    if (v <= 20) {
      return const StatusResult(SensorStatus.comfortable, 'Quiet');
    }
    if (v <= 50) {
      return const StatusResult(SensorStatus.moderate, 'Distracting');
    }
    return const StatusResult(SensorStatus.critical, 'Too Loud');
  }

  // ── Overall status ────────────────────────────────────────────────────────

  /// Computes overall status from Flutter thresholds — ignores ESP32 status strings
  /// to avoid mismatch when ESP32 logic differs from Flutter thresholds.
  static SensorStatus overallStatus(ClassroomModel m) {
    final levels = [
      temperatureStatus(m.temperature).level,
      humidityStatusFromModel(m).level, // ESP32 for humidity
      lightStatus(m.light).level,
      gasStatus(m.gas).level,
      noiseStatus(m.noise).level,
    ];
    final criticalCount = levels
        .where((l) => l == SensorStatus.critical)
        .length;
    final comfortableCount = levels
        .where((l) => l == SensorStatus.comfortable)
        .length;
    if (criticalCount >= 2) return SensorStatus.critical;
    if (comfortableCount > levels.length / 2 && criticalCount == 0) {
      return SensorStatus.comfortable;
    }
    if (criticalCount >= 1 || levels.contains(SensorStatus.moderate)) {
      return SensorStatus.moderate;
    }
    return SensorStatus.comfortable;
  }

  static String overallLabel(SensorStatus s) {
    switch (s) {
      case SensorStatus.comfortable:
        return 'Comfortable';
      case SensorStatus.moderate:
        return 'Moderate';
      case SensorStatus.critical:
        return 'Critical';
    }
  }

  // ── Comfort score ─────────────────────────────────────────────────────────

  static int comfortScore(ClassroomModel m) {
    final levels = [
      temperatureStatus(m.temperature).level,
      humidityStatusFromModel(m).level, // ESP32 for humidity
      lightStatus(m.light).level,
      gasStatus(m.gas).level,
      noiseStatus(m.noise).level,
    ];
    double total = levels.fold(0.0, (sum, l) => sum + _levelScore(l));
    return ((total / 5) * 100).round().clamp(0, 100);
  }

  static int singleSensorScore(SensorStatus level) {
    switch (level) {
      case SensorStatus.comfortable:
        return 100;
      case SensorStatus.moderate:
        return 55;
      case SensorStatus.critical:
        return 10;
    }
  }

  static double _levelScore(SensorStatus s) {
    switch (s) {
      case SensorStatus.comfortable:
        return 1.0;
      case SensorStatus.moderate:
        return 0.5;
      case SensorStatus.critical:
        return 0.0;
    }
  }

  // ── Color helpers ─────────────────────────────────────────────────────────

  static Color statusColor(SensorStatus s) {
    switch (s) {
      case SensorStatus.comfortable:
        return AppColors.comfortable;
      case SensorStatus.moderate:
        return AppColors.moderate;
      case SensorStatus.critical:
        return AppColors.critical;
    }
  }

  static Color statusBgColor(SensorStatus s) {
    switch (s) {
      case SensorStatus.comfortable:
        return AppColors.comfortableBg;
      case SensorStatus.moderate:
        return AppColors.moderateBg;
      case SensorStatus.critical:
        return AppColors.criticalBg;
    }
  }

  // ── Progress bar helpers (normalized 0–1) ─────────────────────────────────

  static double temperatureProgress(double v) =>
      ((v - 16) / (36 - 16)).clamp(0.0, 1.0);
  static double humidityProgress(double v) => (v / 100).clamp(0.0, 1.0);
  // Light/gas/noise are already 0–100 normalized
  static double lightProgress(double v) => (v / 100).clamp(0.0, 1.0);
  static double gasProgress(double v) => (v / 100).clamp(0.0, 1.0);
  static double noiseProgress(double v) => (v / 100).clamp(0.0, 1.0);

  // ── Interpretation text ───────────────────────────────────────────────────

  static String temperatureInterpretation(double v) {
    if (v < 22) {
      return 'Temperature is too cold and may cause discomfort and reduced focus.';
    }
    if (v <= 24) {
      return 'Temperature is slightly below the ideal range. Some students may feel mild discomfort.';
    }
    if (v <= 28) {
      return 'Temperature is within the optimal comfort range. Ideal for learning and concentration.';
    }
    if (v <= 31) {
      return 'Temperature is slightly warm and may reduce comfort and attention over time.';
    }
    return 'Temperature is outside the recommended zone and may significantly affect focus and self-regulation.';
  }

  static String humidityInterpretation(double v) {
    if (v < 40) {
      return 'Air is too dry. This can cause irritation to skin, eyes, and respiratory tract.';
    }
    if (v <= 59) {
      return 'Humidity is slightly below ideal. Some students may experience mild dryness.';
    }
    if (v <= 70) {
      return 'Humidity is within the comfortable range. Air quality is supportive for learning.';
    }
    if (v <= 85) {
      return 'Humidity is slightly elevated. The air may feel heavy and reduce comfort over time.';
    }
    return 'Humidity is too high. This can cause discomfort and difficulty breathing for sensitive students.';
  }

  static String lightInterpretation(double v) {
    if (v <= 20) {
      return 'Lighting is too dark. Poor visibility can cause eye strain and reduce engagement.';
    }
    if (v <= 40) {
      return 'Lighting is slightly dim. Some students may find it harder to read or focus.';
    }
    if (v <= 80) {
      return 'Lighting is within the comfortable range. Ideal for reading, writing, and classroom activities.';
    }
    return 'Lighting is too intense. Excessive brightness can trigger sensory overload in SNED students.';
  }

  static String gasInterpretation(double v) {
    if (v <= 20) {
      return 'Air quality is clean and safe. Ideal for students with respiratory sensitivities.';
    }
    if (v <= 50) {
      return 'Air quality needs monitoring. Some pollutants are present but within tolerable levels.';
    }
    return 'Air quality is poor. High gas levels may cause headaches, fatigue, or breathing difficulty.';
  }

  static String noiseInterpretation(double v) {
    if (v <= 20) {
      return 'Noise level is low and supportive for learning. Ideal for students with sensory sensitivities.';
    }
    if (v <= 50) {
      return 'Noise level is distracting. Some students may find it hard to focus.';
    }
    return 'Noise level is too loud. High sound exposure can cause sensory overload and significantly impact SNED students.';
  }

  // ── Suggestions ───────────────────────────────────────────────────────────

  static List<String> temperatureSuggestions(double v) {
    if (temperatureStatus(v).level == SensorStatus.comfortable) {
      return [
        'Maintain current temperature',
        'Monitor regularly throughout the day',
        'Keep conditions stable for students',
      ];
    }
    if (v < 22) {
      return [
        'Turn on or increase heating',
        'Close windows and doors to retain warmth',
        'Reassess temperature after 10 minutes',
      ];
    }
    return [
      'Adjust fan or air conditioning',
      'Improve ventilation in the room',
      'Reassess after a few minutes',
    ];
  }

  static List<String> humiditySuggestions(double v) {
    if (humidityStatus(v).level == SensorStatus.comfortable) {
      return [
        'Maintain current humidity level',
        'Monitor regularly',
        'Keep ventilation consistent',
      ];
    }
    if (v < 60) {
      return [
        'Use a humidifier to add moisture',
        'Avoid excessive air conditioning',
        'Check again after 15 minutes',
      ];
    }
    return [
      'Use a dehumidifier or improve airflow',
      'Open windows if outdoor humidity is lower',
      'Monitor for signs of mold or condensation',
    ];
  }

  static List<String> lightSuggestions(double v) {
    if (lightStatus(v).level == SensorStatus.comfortable) {
      return [
        'Maintain current lighting level',
        'Ensure even light distribution',
        'Monitor during different times of day',
      ];
    }
    if (v <= 40) {
      return [
        'Turn on additional lights',
        'Open blinds or curtains for natural light',
        'Replace dim or faulty bulbs',
      ];
    }
    return [
      'Close blinds to reduce direct sunlight',
      'Dim overhead lights if possible',
      'Use diffused or indirect lighting',
    ];
  }

  static List<String> gasSuggestions(double v) {
    if (gasStatus(v).level == SensorStatus.comfortable) {
      return [
        'Maintain current ventilation',
        'Keep windows open when possible',
        'Monitor air quality regularly',
      ];
    }
    if (v <= 50) {
      return [
        'Increase ventilation by opening windows',
        'Avoid using strong cleaning products nearby',
        'Monitor for further changes',
      ];
    }
    return [
      'Immediately improve ventilation',
      'Identify and remove sources of gas or odor',
      'Consider temporarily relocating students',
    ];
  }

  static List<String> noiseSuggestions(double v) {
    if (noiseStatus(v).level == SensorStatus.comfortable) {
      return [
        'Maintain the current quiet environment',
        'Encourage calm classroom behavior',
        'Monitor during transitions or activities',
      ];
    }
    if (v <= 50) {
      return [
        'Remind students to use indoor voices',
        'Reduce background noise sources',
        'Monitor if noise level increases further',
      ];
    }
    return [
      'Immediately address noise sources',
      'Use noise-cancelling tools or quiet zones',
      'Consider sensory breaks for affected students',
    ];
  }

  // ── Sensor detail configs ─────────────────────────────────────────────────
  // These are used by SensorDetailScreen. They use the Firebase status from
  // the model for the status label, and fallback logic for interpretation/suggestions.

  static SensorDetailConfig temperatureConfig(ClassroomModel m) {
    final s = temperatureStatusFromModel(m);
    return SensorDetailConfig(
      title: 'Temperature',
      subtitle: 'Thermal comfort monitoring',
      icon: Icons.thermostat_rounded,
      iconColor: AppColors.tempIcon,
      iconBg: AppColors.tempBg,
      value: m.temperature,
      unit: '°C',
      statusLabel: s.label,
      interpretation: temperatureInterpretation(m.temperature),
      suggestions: temperatureSuggestions(m.temperature),
      score: singleSensorScore(s.level),
      rangeMin: 16,
      rangeIdealStart: 22,
      rangeIdealEnd: 28,
      rangeMax: 36,
      // Moderate: 29–31 on right side; left of 22 is critical (no moderate left)
      rangeModerateStart: 28,
      rangeModerateEnd: 31,
    );
  }

  static SensorDetailConfig humidityConfig(ClassroomModel m) {
    final s = humidityStatusFromModel(m);
    return SensorDetailConfig(
      title: 'Humidity',
      subtitle: 'Air moisture monitoring',
      icon: Icons.water_drop_rounded,
      iconColor: AppColors.humidIcon,
      iconBg: AppColors.humidBg,
      value: m.humidity,
      unit: '%',
      statusLabel: s.label,
      interpretation: humidityInterpretation(m.humidity),
      suggestions: humiditySuggestions(m.humidity),
      score: singleSensorScore(s.level),
      rangeMin: 0,
      rangeIdealStart: 60,
      rangeIdealEnd: 70,
      rangeMax: 100,
      // Moderate: 40–59 left, 71–85 right
      rangeModerateStart: 40,
      rangeModerateEnd: 85,
    );
  }

  static SensorDetailConfig lightConfig(ClassroomModel m) {
    final s = lightStatusFromModel(m);
    return SensorDetailConfig(
      title: 'Light Level',
      subtitle: 'Illumination monitoring',
      icon: Icons.light_mode_rounded,
      iconColor: AppColors.lightIcon,
      iconBg: AppColors.lightBg,
      value: m.light,
      unit: '%',
      statusLabel: s.label,
      interpretation: lightInterpretation(m.light),
      suggestions: lightSuggestions(m.light),
      score: singleSensorScore(s.level),
      rangeMin: 0,
      rangeIdealStart: 41,
      rangeIdealEnd: 80,
      rangeMax: 100,
      // Moderate: 21–40 on left side, >80 is critical (no right moderate)
      rangeModerateStart: 21,
      rangeModerateEnd: 40,
    );
  }

  static SensorDetailConfig gasConfig(ClassroomModel m) {
    final s = gasStatusFromModel(m);
    return SensorDetailConfig(
      title: 'Air Quality',
      subtitle: 'Gas & air quality monitoring',
      icon: Icons.air_rounded,
      iconColor: AppColors.gasIcon,
      iconBg: AppColors.gasBg,
      value: m.gas,
      unit: '%',
      statusLabel: s.label,
      interpretation: gasInterpretation(m.gas),
      suggestions: gasSuggestions(m.gas),
      score: singleSensorScore(s.level),
      rangeMin: 0,
      rangeIdealStart: 0,
      rangeIdealEnd: 20,
      rangeMax: 100,
      // Moderate: 21–50
      rangeModerateStart: 20,
      rangeModerateEnd: 50,
      rangeLowLabel: 'Optimal',
    );
  }

  static SensorDetailConfig noiseConfig(ClassroomModel m) {
    final s = noiseStatusFromModel(m);
    return SensorDetailConfig(
      title: 'Noise Level',
      subtitle: 'Sound environment monitoring',
      icon: Icons.volume_up_rounded,
      iconColor: AppColors.noiseIcon,
      iconBg: AppColors.noiseBg,
      value: m.noise,
      unit: '%',
      statusLabel: s.label,
      interpretation: noiseInterpretation(m.noise),
      suggestions: noiseSuggestions(m.noise),
      score: singleSensorScore(s.level),
      rangeMin: 0,
      rangeIdealStart: 0,
      rangeIdealEnd: 20,
      rangeMax: 100,
      // Moderate: 21–50
      rangeModerateStart: 20,
      rangeModerateEnd: 50,
      rangeLowLabel: 'Optimal',
    );
  }

  // ── Alert generation ──────────────────────────────────────────────────────

  static List<Map<String, dynamic>> generateAlerts(ClassroomModel m) {
    final alerts = <Map<String, dynamic>>[];
    final now = DateTime.now();

    void check(String sensor, StatusResult result, String description) {
      if (result.level != SensorStatus.comfortable) {
        alerts.add({
          'sensor': sensor,
          'label': result.label,
          'description': description,
          'level': result.level,
          'time': now,
        });
      }
    }

    check(
      'Temperature',
      temperatureStatusFromModel(m),
      'Current temperature is ${m.temperature.toStringAsFixed(1)}°C',
    );
    check(
      'Humidity',
      humidityStatusFromModel(m),
      'Current humidity is ${m.humidity.toStringAsFixed(0)}%',
    );
    check(
      'Light',
      lightStatusFromModel(m),
      'Light level is ${m.light.toStringAsFixed(0)}%',
    );
    check(
      'Air Quality',
      gasStatusFromModel(m),
      'Air quality reading is ${m.gas.toStringAsFixed(0)}%',
    );
    check(
      'Noise',
      noiseStatusFromModel(m),
      'Noise level is ${m.noise.toStringAsFixed(0)}% — may affect sensory students',
    );

    return alerts;
  }
}
