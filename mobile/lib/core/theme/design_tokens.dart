import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design tokens for RETRO MARKET (izithrift)
/// Defines standard spacing, radius, border width, and elevation/shadows.
class DesignTokens {
  DesignTokens._();

  // Spacing Tokens
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double space2xl = 32.0;
  static const double space3xl = 40.0;

  // Spacing Aliases
  static const double spacingXs = spaceXs;
  static const double spacingSm = spaceSm;
  static const double spacingMd = spaceMd;
  static const double spacingLg = spaceLg;
  static const double spacingXl = spaceXl;
  static const double spacing2xl = space2xl;
  static const double spacing3xl = space3xl;

  // Corner Radius Tokens
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;
  static const double radiusRound = radiusFull;

  // Border Widths
  static const double borderThin = 1.0;
  static const double borderMedium = 1.5;
  static const double borderThick = 2.0;

  // Standard Border Radii
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));
  static const BorderRadius borderRadiusRound = borderRadiusFull;

  // Card & Container Shadows
  static const List<BoxShadow> cardElevation = [
    BoxShadow(
      color: Color(0x0F231F20),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> modalElevation = [
    BoxShadow(
      color: Color(0x1F231F20),
      offset: Offset(0, 6),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> floatingButtonElevation = [
    BoxShadow(
      color: Color(0x24C85A32),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // Standard Outlined Borders
  static Border defaultBorder = Border.all(
    color: AppColors.borderWarm,
    width: borderThin,
  );

  static Border activeBorder = Border.all(
    color: AppColors.primaryTerracotta,
    width: borderMedium,
  );
}
