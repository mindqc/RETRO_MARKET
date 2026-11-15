import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography tokens for RETRO MARKET (izithrift)
/// Follows typography hierarchy:
/// - Brand / Editorial Headlines: Fraunces / Serif
/// - Body / Controls / Interface: Be Vietnam Pro / Sans-Serif
/// - Prices & Countdowns: Tabular numbers [FontFeature.tabularFigures()]
class AppTypography {
  AppTypography._();

  static const String fontHeading = 'Fraunces';
  static const String fontBody = 'BeVietnamPro';

  static const List<String> headingFallbacks = ['Georgia', 'serif'];
  static const List<String> bodyFallbacks = ['Roboto', 'Arial', 'sans-serif'];

  // Display & Editorial Titles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontHeading,
    fontFamilyFallback: headingFallbacks,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textCharcoal,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = headingLarge;

  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontHeading,
    fontFamilyFallback: headingFallbacks,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textCharcoal,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontHeading,
    fontFamilyFallback: headingFallbacks,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textCharcoal,
    height: 1.35,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: fontHeading,
    fontFamilyFallback: headingFallbacks,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textCharcoal,
    height: 1.4,
  );

  // Body & Content
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontBody,
    fontFamilyFallback: bodyFallbacks,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textCharcoal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontBody,
    fontFamilyFallback: bodyFallbacks,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textCharcoal,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontBody,
    fontFamilyFallback: bodyFallbacks,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontBody,
    fontFamilyFallback: bodyFallbacks,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.35,
  );

  // Button & Label Styles
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontBody,
    fontFamilyFallback: bodyFallbacks,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontBody,
    fontFamilyFallback: bodyFallbacks,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle button = buttonMedium;

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontBody,
    fontFamilyFallback: bodyFallbacks,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textCharcoal,
  );

  // Tabular Numerals for Prices & Countdowns (Prevents layout jitter)
  static const TextStyle priceLarge = TextStyle(
    fontFamily: fontBody,
    fontFamilyFallback: bodyFallbacks,
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryTerracotta,
    height: 1.2,
  );

  static const TextStyle priceMedium = TextStyle(
    fontFamily: fontBody,
    fontFamilyFallback: bodyFallbacks,
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryTerracotta,
    height: 1.25,
  );

  static const TextStyle priceSmall = TextStyle(
    fontFamily: fontBody,
    fontFamilyFallback: bodyFallbacks,
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryTerracotta,
    height: 1.25,
  );

  static const TextStyle countdownTimer = TextStyle(
    fontFamily: fontBody,
    fontFamilyFallback: bodyFallbacks,
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}
