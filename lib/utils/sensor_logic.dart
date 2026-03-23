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

  static StatusResult temperatureStatus(double v) {
    if (v < 22)  return const StatusResult(SensorStatus.critical,    'Too Cold');
    if (v <= 24) return const StatusResult(SensorStatus.moderate,    'Slightly Cold');
    if (v <= 28) return const StatusResult(SensorStatus.comfortable, 'Comfortable');
    if (v <= 31) return const StatusResult(SensorStatus.moderate,    'Slightly Warm');
    return       const StatusResult(SensorStatus.critical,           'Too Hot');
  }

  static String temperatureInterpretation(double v) {
    if (v < 22)  return 'Temperature is too cold and may cause discomfort and reduced focus.';
    if (v <= 24) return 'Temperature is slightly below the ideal range. Some students may feel mild discomfort.';
    if (v <= 28) return 'Temperature is within the optimal comfort range. Ideal for learning and concentration.';
    if (v <= 31) return 'Temperature is slightly warm and may reduce comfort and attention over time.';
    return 'Temperature is outside the recommended zone and may significantly affect focus and self-regulation.';
  }

  static List<String> temperatureSuggestions(double v) {
    if (temperatureStatus(v).level == SensorStatus.comfortable) {
      return ['Maintain current temperature', 'Monitor regularly throughout the day', 'Keep conditions stable for students'];
    }
    if (v < 22) {
      return ['Turn on or increase heating', 'Close windows and doors to retain warmth', 'Reassess temperature after 10 minutes'];
    }
    return ['Adjust fan or air conditioning', 'Improve ventilation in the room', 'Reassess after a few minutes'];
  }

  static StatusResult humidityStatus(double v) {
    if (v < 40)  return const StatusResult(SensorStatus.critical,    'Too Dry');
    if (v <= 59) return const StatusResult(SensorStatus.moderate,    'Slightly Dry');
    if (v <= 70) return const StatusResult(SensorStatus.comfortable, 'Comfortable');
    if (v <= 85) return const StatusResult(SensorStatus.moderate,    'Slightly Humid');
    return       const StatusResult(SensorStatus.critical,           'Too Humid');
  }

  static String humidityInterpretation(double v) {
    if (v < 40)  return 'Air is too dry. This can cause irritation to skin, eyes, and respiratory tract.';
    if (v <= 59) return 'Humidity is slightly below ideal. Some students may experience mild dryness.';
    if (v <= 70) return 'Humidity is within the comfortable range. Air quality is supportive for learning.';
    if (v <= 85) return 'Humidity is slightly elevated. The air may feel heavy and reduce comfort over time.';
    return 'Humidity is too high. This can cause discomfort and difficulty breathing for sensitive students.';
  }

  static List<String> humiditySuggestions(double v) {
    if (humidityStatus(v).level == SensorStatus.comfortable) {
      return ['Maintain current humidity level', 'Monitor regularly', 'Keep ventilation consistent'];
    }
    if (v < 60) {
      return ['Use a humidifier to add moisture', 'Avoid excessive air conditioning', 'Check again after 15 minutes'];
    }
    return ['Use a dehumidifier or improve airflow', 'Open windows if outdoor humidity is lower', 'Monitor for signs of mold or condensation'];
  }

  static StatusResult lightStatus(double v) {
    if (v < 300)   return const StatusResult(SensorStatus.critical,    'Too Dark');
    if (v <= 799)  return const StatusResult(SensorStatus.moderate,    'Slightly Dim');
    if (v <= 2000) return const StatusResult(SensorStatus.comfortable, 'Comfortable');
    if (v <= 3000) return const StatusResult(SensorStatus.moderate,    'Slightly Bright');
    return         const StatusResult(SensorStatus.critical,           'Too Bright');
  }

  static String lightInterpretation(double v) {
    if (v < 300)   return 'Lighting is too dark. Poor visibility can cause eye strain and reduce engagement.';
    if (v <= 799)  return 'Lighting is slightly dim. Some students may find it harder to read or focus.';
    if (v <= 2000) return 'Lighting is within the comfortable range. Ideal for reading, writing, and classroom activities.';
    if (v <= 3000) return 'Lighting is slightly bright. May cause glare or visual discomfort for sensitive students.';
    return 'Lighting is too intense. Excessive brightness can trigger sensory overload in SNED students.';
  }

  static List<String> lightSuggestions(double v) {
    if (lightStatus(v).level == SensorStatus.comfortable) {
      return ['Maintain current lighting level', 'Ensure even light distribution', 'Monitor during different times of day'];
    }
    if (v < 800) {
      return ['Turn on additional lights', 'Open blinds or curtains for natural light', 'Replace dim or faulty bulbs'];
    }
    return ['Close blinds to reduce direct sunlight', 'Dim overhead lights if possible', 'Use diffused or indirect lighting'];
  }

  static StatusResult gasStatus(double v) {
    if (v <= 220) return const StatusResult(SensorStatus.comfortable, 'Clean');
    if (v <= 280) return const StatusResult(SensorStatus.moderate,    'Needs Monitoring');
    return        const StatusResult(SensorStatus.critical,           'Poor Air Quality');
  }

  static String gasInterpretation(double v) {
    if (v <= 220) return 'Air quality is clean and safe. Ideal for students with respiratory sensitivities.';
    if (v <= 280) return 'Air quality needs monitoring. Some pollutants are present but within tolerable levels.';
    return 'Air quality is poor. High gas levels may cause headaches, fatigue, or breathing difficulty.';
  }

  static List<String> gasSuggestions(double v) {
    if (gasStatus(v).level == SensorStatus.comfortable) {
      return ['Maintain current ventilation', 'Keep windows open when possible', 'Monitor air quality regularly'];
    }
    if (v <= 280) {
      return ['Increase ventilation by opening windows', 'Avoid using strong cleaning products nearby', 'Monitor for further changes'];
    }
    return ['Immediately improve ventilation', 'Identify and remove sources of gas or odor', 'Consider temporarily relocating students'];
  }

  static StatusResult noiseStatus(double v) {
    if (v <= 1000) return const StatusResult(SensorStatus.comfortable, 'Quiet');
    if (v <= 2000) return const StatusResult(SensorStatus.moderate,    'Distracting');
    return         const StatusResult(SensorStatus.critical,           'Too Loud');
  }

  static String noiseInterpretation(double v) {
    if (v <= 1000) return 'Noise level is low and supportive for learning. Ideal for students with sensory sensitivities.';
    if (v <= 2000) return 'Noise level is distracting. Some students may find it hard to focus, especially those with auditory sensitivities.';
    return 'Noise level is too loud. High sound exposure can cause sensory overload and significantly impact SNED students.';
  }

  static List<String> noiseSuggestions(double v) {
    if (noiseStatus(v).level == SensorStatus.comfortable) {
      return ['Maintain the current quiet environment', 'Encourage calm classroom behavior', 'Monitor during transitions or activities'];
    }
    if (v <= 2000) {
      return ['Remind students to use indoor voices', 'Reduce background noise sources', 'Monitor if noise level increases further'];
    }
    return ['Immediately address noise sources', 'Use noise-cancelling tools or quiet zones', 'Consider sensory breaks for affected students'];
  }

  static SensorStatus overallStatus(ClassroomModel m) {
    final levels = [
      temperatureStatus(m.temperature).level,
      humidityStatus(m.humidity).level,
      lightStatus(m.light).level,
      gasStatus(m.gas).level,
      noiseStatus(m.noise).level,
    ];
    if (levels.contains(SensorStatus.critical)) return SensorStatus.critical;
    if (levels.contains(SensorStatus.moderate)) return SensorStatus.moderate;
    return SensorStatus.comfortable;
  }

  static String overallLabel(SensorStatus s) {
    switch (s) {
      case SensorStatus.comfortable: return 'Comfortable';
      case SensorStatus.moderate:    return 'Moderate';
      case SensorStatus.critical:    return 'Critical';
    }
  }

  static int comfortScore(ClassroomModel m) {
    double total = 0;
    total += _levelScore(temperatureStatus(m.temperature).level);
    total += _levelScore(humidityStatus(m.humidity).level);
    total += _levelScore(lightStatus(m.light).level);
    total += _levelScore(gasStatus(m.gas).level);
    total += _levelScore(noiseStatus(m.noise).level);
    return ((total / 5) * 100).round().clamp(0, 100);
  }

  static int singleSensorScore(SensorStatus level) {
    switch (level) {
      case SensorStatus.comfortable: return 100;
      case SensorStatus.moderate:    return 55;
      case SensorStatus.critical:    return 10;
    }
  }

  static double _levelScore(SensorStatus s) {
    switch (s) {
      case SensorStatus.comfortable: return 1.0;
      case SensorStatus.moderate:    return 0.5;
      case SensorStatus.critical:    return 0.0;
    }
  }

  static Color statusColor(SensorStatus s) {
    switch (s) {
      case SensorStatus.comfortable: return AppColors.comfortable;
      case SensorStatus.moderate:    return AppColors.moderate;
      case SensorStatus.critical:    return AppColors.critical;
    }
  }

  static Color statusBgColor(SensorStatus s) {
    switch (s) {
      case SensorStatus.comfortable: return AppColors.comfortableBg;
      case SensorStatus.moderate:    return AppColors.moderateBg;
      case SensorStatus.critical:    return AppColors.criticalBg;
    }
  }

  static double temperatureProgress(double v) => (v / 40).clamp(0.0, 1.0);
  static double humidityProgress(double v)    => (v / 100).clamp(0.0, 1.0);
  static double lightProgress(double v)       => (v / 4000).clamp(0.0, 1.0);
  static double gasProgress(double v)         => (v / 400).clamp(0.0, 1.0);
  static double noiseProgress(double v)       => (v / 3000).clamp(0.0, 1.0);

  static SensorDetailConfig temperatureConfig(double v) {
    final s = temperatureStatus(v);
    return SensorDetailConfig(
      title: 'Temperature', subtitle: 'Thermal comfort monitoring',
      icon: Icons.thermostat_rounded,
      iconColor: AppColors.tempIcon, iconBg: AppColors.tempBg,
      value: v, unit: '°C',
      statusLabel: s.label,
      interpretation: temperatureInterpretation(v),
      suggestions: temperatureSuggestions(v),
      score: singleSensorScore(s.level),
      rangeMin: 16, rangeIdealStart: 25, rangeIdealEnd: 28, rangeMax: 36,
    );
  }

  static SensorDetailConfig humidityConfig(double v) {
    final s = humidityStatus(v);
    return SensorDetailConfig(
      title: 'Humidity', subtitle: 'Air moisture monitoring',
      icon: Icons.water_drop_rounded,
      iconColor: AppColors.humidIcon, iconBg: AppColors.humidBg,
      value: v, unit: '%',
      statusLabel: s.label,
      interpretation: humidityInterpretation(v),
      suggestions: humiditySuggestions(v),
      score: singleSensorScore(s.level),
      rangeMin: 20, rangeIdealStart: 60, rangeIdealEnd: 70, rangeMax: 100,
    );
  }

  static SensorDetailConfig lightConfig(double v) {
    final s = lightStatus(v);
    return SensorDetailConfig(
      title: 'Light Level', subtitle: 'Illumination monitoring',
      icon: Icons.light_mode_rounded,
      iconColor: AppColors.lightIcon, iconBg: AppColors.lightBg,
      value: v, unit: 'lux',
      statusLabel: s.label,
      interpretation: lightInterpretation(v),
      suggestions: lightSuggestions(v),
      score: singleSensorScore(s.level),
      rangeMin: 0, rangeIdealStart: 800, rangeIdealEnd: 2000, rangeMax: 4000,
    );
  }

  static SensorDetailConfig gasConfig(double v) {
    final s = gasStatus(v);
    return SensorDetailConfig(
      title: 'Air Quality', subtitle: 'Gas & air quality monitoring',
      icon: Icons.air_rounded,
      iconColor: AppColors.gasIcon, iconBg: AppColors.gasBg,
      value: v, unit: 'ppm',
      statusLabel: s.label,
      interpretation: gasInterpretation(v),
      suggestions: gasSuggestions(v),
      score: singleSensorScore(s.level),
      rangeMin: 0, rangeIdealStart: 0, rangeIdealEnd: 220, rangeMax: 400,
    );
  }

  static SensorDetailConfig noiseConfig(double v) {
    final s = noiseStatus(v);
    return SensorDetailConfig(
      title: 'Noise Level', subtitle: 'Sound environment monitoring',
      icon: Icons.volume_up_rounded,
      iconColor: AppColors.noiseIcon, iconBg: AppColors.noiseBg,
      value: v, unit: 'raw',
      statusLabel: s.label,
      interpretation: noiseInterpretation(v),
      suggestions: noiseSuggestions(v),
      score: singleSensorScore(s.level),
      rangeMin: 0, rangeIdealStart: 0, rangeIdealEnd: 1000, rangeMax: 3000,
    );
  }

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

    check('Temperature', temperatureStatus(m.temperature),
        'Current temperature is ${m.temperature.toStringAsFixed(1)}°C');
    check('Humidity', humidityStatus(m.humidity),
        'Current humidity is ${m.humidity.toStringAsFixed(0)}%');
    check('Light', lightStatus(m.light),
        'Current light level is ${m.light.toStringAsFixed(0)} lux');
    check('Air Quality', gasStatus(m.gas),
        'Gas reading is ${m.gas.toStringAsFixed(0)} ppm');
    check('Noise', noiseStatus(m.noise),
        'Noise reading is ${m.noise.toStringAsFixed(0)} — may affect sensory students');

    return alerts;
  }
}
