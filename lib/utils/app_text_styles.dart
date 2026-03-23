import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Central text styles for KALMADO app
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle pageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.titleNavy,
    letterSpacing: 0.2,
  );

  static const TextStyle pageSubtitle = TextStyle(
    fontSize: 13,
    color: AppColors.subtitleGray,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.subtitleGray,
    letterSpacing: 0.3,
  );

  static const TextStyle sensorValue = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.titleNavy,
  );

  static const TextStyle sensorUnit = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.subtitleGray,
  );

  static const TextStyle statusLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );

  static const TextStyle bigStatus = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle scoreNumber = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.titleNavy,
  );
}
