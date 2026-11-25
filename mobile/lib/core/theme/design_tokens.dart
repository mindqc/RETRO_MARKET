import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared spacing, shape, border and warm elevation tokens for RETRO MARKET (izithrift).
class DesignTokens {
  DesignTokens._();

  // Spacing scale (multiples of 4 logical pixels)
  static const double space2xs = 2.0;
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double space2xl = 32.0;
  static const double space3xl = 40.0;
  static const double space4xl = 48.0;
  static const double space5xl = 64.0;

  // Backward-compatible spacing aliases
  static const double spacingXs = spaceXs;
  static const double spacingSm = spaceSm;
  static const double spacingMd = spaceMd;
  static const double spacingLg = spaceLg;
  static const double spacingXl = spaceXl;
  static const double spacing2xl = space2xl;
  static const double spacing3xl = space3xl;

  // Corner radius scale (matches reference soft editorial curves)
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusBanner = 20.0;
  static const double radiusXl = 24.0;
  static const double radius2xl = 32.0;
  static const double radiusFull = 999.0;
  static const double radiusRound = radiusFull;

  // Border widths
  static const double borderThin = 1.0;
  static const double borderMedium = 1.5;
  static const double borderThick = 2.0;

  // Standard border radii
  static const BorderRadius borderRadiusXs =
      BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius borderRadiusSm =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg =
      BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusBanner =
      BorderRadius.all(Radius.circular(radiusBanner));
  static const BorderRadius borderRadiusXl =
      BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusFull =
      BorderRadius.all(Radius.circular(radiusFull));
  static const BorderRadius borderRadiusRound = borderRadiusFull;

  // Warm ambient shadows (soft espresso tint, never harsh grey)
  static const List<BoxShadow> cardElevation = [
    BoxShadow(
      color: Color(0x112B2118),
      offset: Offset(0, 3),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> sectionContainerShadow = [
    BoxShadow(
      color: Color(0x0E2B2118),
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> bannerElevation = [
    BoxShadow(
      color: Color(0x221E1610),
      offset: Offset(0, 6),
      blurRadius: 18,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> bottomNavElevation = [
    BoxShadow(
      color: Color(0x14231F20),
      offset: Offset(0, -4),
      blurRadius: 18,
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
      color: Color(0x28203A29),
      offset: Offset(0, 4),
      blurRadius: 14,
      spreadRadius: 0,
    ),
  ];

  // Borders
  static Border defaultBorder = Border.all(
    color: AppColors.borderWarm,
    width: borderThin,
  );

  static Border subtleBorder = Border.all(
    color: AppColors.borderSubtle,
    width: borderThin,
  );

  static Border activeBorder = Border.all(
    color: AppColors.primaryForestGreen,
    width: borderMedium,
  );
}
