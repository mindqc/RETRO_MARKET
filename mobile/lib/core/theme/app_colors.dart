import 'package:flutter/material.dart';

/// Color tokens for RETRO MARKET (izithrift).
///
/// Primary UI identity: Forest Green.
/// Supporting editorial palette: Warm Ivory, Terracotta, Burgundy and Vintage Gold.
/// Legacy colors remain unchanged for backward compatibility.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Surfaces
  // ---------------------------------------------------------------------------
  static const Color warmIvory = Color(0xFFFBF8F3);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFF4EFE6);
  static const Color surfaceDark = Color(0xFF231F20);

  // ---------------------------------------------------------------------------
  // Brand palette
  // ---------------------------------------------------------------------------

  /// Main brand color for navigation, primary actions and selected states.
  static const Color primaryForestGreen = Color(0xFF2D5A3C);
  static const Color primaryForestGreenDark = Color(0xFF1F422C);
  static const Color primaryForestGreenLight = Color(0xFFE7EFE8);

  /// Legacy primary color. Keep its original value for existing consumers/tests.
  static const Color primaryTerracotta = Color(0xFFC85A32);
  static const Color primaryTerracottaDark = Color(0xFFA34320);

  static const Color secondaryPineGreen = Color(0xFF2D5A3C);
  static const Color christmasBerryRed = Color(0xFFB22222);
  static const Color accentVintageGold = Color(0xFFD4AF37);
  static const Color accentBurgundy = christmasBerryRed;
  static const Color primaryVintageBrown = Color(0xFF84664C);

  // ---------------------------------------------------------------------------
  // Typography, borders and neutral colors
  // ---------------------------------------------------------------------------
  static const Color textCharcoal = Color(0xFF231F20);
  static const Color textMuted = Color(0xFF6E655F);
  static const Color textLight = Color(0xFFFAF7F2);
  static const Color borderWarm = Color(0xFFE5DEC9);
  static const Color borderSubtle = Color(0xFFF0EAE1);

  // Semantic aliases retained for existing screens.
  static const Color textDarkCharcoal = textCharcoal;
  static const Color textCharcoalMuted = textMuted;
  static const Color accentMutedGold = accentVintageGold;

  // ---------------------------------------------------------------------------
  // Status colors
  // ---------------------------------------------------------------------------
  static const Color statusSuccess = Color(0xFF2E7D32);
  static const Color statusWarning = Color(0xFFED6C02);
  static const Color statusDanger = Color(0xFFD32F2F);
  static const Color statusInfo = Color(0xFF0288D1);

  // Auction-specific colors
  static const Color auctionLiveBadge = Color(0xFFB22222);
  static const Color auctionEndingSoon = Color(0xFFE65100);

  // Backward-compatible alias. Do not use for new UI code.
  // ignore: constant_identifier_names
  static const Color backgroundCream = warmIvory;
}
