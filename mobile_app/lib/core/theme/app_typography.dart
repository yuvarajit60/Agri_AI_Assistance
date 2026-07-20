import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Poppins for display/headline weight (distinct, modern), Inter for body
/// text (highly legible at small sizes — important for dense data cards).
/// Both are bundled as local assets (see pubspec.yaml `fonts:`) rather
/// than fetched at runtime, so text renders instantly with no network
/// dependency — important on the patchy connectivity this app targets.
abstract final class AppTypography {
  static TextTheme textTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: primaryText,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primaryText,
        height: 1.2,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primaryText,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryText,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primaryText,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryText,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryText,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondaryText,
        letterSpacing: 0.4,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryText,
        letterSpacing: 0.4,
      ),
    );
  }

  static TextTheme get light => textTheme(AppColors.textPrimary, AppColors.textSecondary);
  static TextTheme get dark => textTheme(AppColors.textPrimaryDark, AppColors.textSecondaryDark);
}
