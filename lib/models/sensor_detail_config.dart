import 'package:flutter/material.dart';

/// Configuration object passed to [SensorDetailScreen].
/// Encapsulates all data needed to render a sensor's detail page.
class SensorDetailConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final double value;
  final String unit;
  final String statusLabel;
  final String interpretation;
  final List<String> suggestions;
  final int score; // 0–100

  // Range bar values
  final double rangeMin;
  final double rangeIdealStart;
  final double rangeIdealEnd;
  final double rangeMax;

  const SensorDetailConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.unit,
    required this.statusLabel,
    required this.interpretation,
    required this.suggestions,
    required this.score,
    required this.rangeMin,
    required this.rangeIdealStart,
    required this.rangeIdealEnd,
    required this.rangeMax,
  });
}
