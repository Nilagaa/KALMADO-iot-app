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
  final double rangeIdealStart; // comfortable zone start
  final double rangeIdealEnd; // comfortable zone end
  final double rangeMax;

  // Moderate zone boundaries (optional — defaults to no moderate zone)
  final double rangeModerateStart; // where moderate begins (left side)
  final double rangeModerateEnd; // where moderate ends (right side)

  /// Label shown at the low end of the range bar.
  final String rangeLowLabel;

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
    this.rangeModerateStart = -1, // -1 = not set
    this.rangeModerateEnd = -1,
    this.rangeLowLabel = 'Too Low',
  });
}
