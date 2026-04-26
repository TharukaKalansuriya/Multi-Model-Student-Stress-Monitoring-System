import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors (iOS Standard)
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF000000);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightBorder = Color(0xFFE5E5EA);

  // Dark Mode Colors (iOS Standard)
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkText = Colors.white;
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFF999999);
  static const Color darkBorder = Color(0xFF38383A);

  // Accent Colors (iOS Style)
  static const Color primary = Color(0xFF007AFF);
  static const Color accentBlue = Color(0xFF007AFF);
  static const Color accentGreen = Color(0xFF34C759);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color primaryLight = Color(0xFF34C759);
  static const Color secondary = Color(0xFF00B4D8);

  // Stress Level Colors
  static const Color healthyGreen = Color(0xFF34C759);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color criticalRed = Color(0xFFFF3B30);
  static const Color stressBlue = Color(0xFF007AFF);

  // Additional iOS Colors
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkText
        : lightText;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : lightBorder;
  }

  static Color getStressColor(int score) {
    if (score < 35) return healthyGreen;
    if (score < 65) return warningOrange;
    return criticalRed;
  }

  static String getStressLabel(int score) {
    if (score < 35) return 'Healthy';
    if (score < 65) return 'Moderate';
    return 'High Stress';
  }
}
