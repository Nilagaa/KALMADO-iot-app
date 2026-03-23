import 'package:flutter/material.dart';

/// Reusable widget for a single onboarding page.
/// Displays an icon card, title, and description.
class OnboardingPageWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final Color iconBgColor;

  const OnboardingPageWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor = const Color(0xFF4A90D9),
    this.iconBgColor = const Color(0xFFEAF4FB),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon card with rounded square and shadow
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, size: 52, color: iconColor),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B4A),
              height: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF7A8FA6),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
