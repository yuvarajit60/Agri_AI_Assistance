import 'package:flutter/material.dart';

/// Brand palette for the Agriculture AI Assistant.
///
/// Greens read as "growth/agriculture", amber is reserved for AI/insight
/// accents (spark, alerts-of-interest), and status colors map to the
/// confidence/risk language used throughout the recommendation contract
/// (high/medium/low confidence, risk levels).
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF1B5E20); // deep green
  static const Color primaryLight = Color(0xFF4C8C4A);
  static const Color primaryDark = Color(0xFF0A3D10);
  static const Color secondary = Color(0xFF8BC34A); // leaf green
  static const Color accent = Color(0xFFFFC107); // AI spark gold

  // Neutrals
  static const Color background = Color(0xFFF7F9F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEFF3EA);
  static const Color textPrimary = Color(0xFF1A2318);
  static const Color textSecondary = Color(0xFF5B6B57);
  static const Color border = Color(0xFFDCE4D6);

  // Dark theme neutrals
  static const Color backgroundDark = Color(0xFF10140F);
  static const Color surfaceDark = Color(0xFF1B211A);
  static const Color surfaceAltDark = Color(0xFF232B21);
  static const Color textPrimaryDark = Color(0xFFECF1E8);
  static const Color textSecondaryDark = Color(0xFFA8B5A3);
  static const Color borderDark = Color(0xFF31392E);

  // Semantic / confidence & risk
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF0277BD);

  /// High/medium/low confidence colors used on recommendation cards.
  static const Color confidenceHigh = success;
  static const Color confidenceMedium = warning;
  static const Color confidenceLow = danger;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF558B2F)],
  );
}
