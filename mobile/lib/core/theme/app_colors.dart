import 'package:flutter/material.dart';

/// Color tokens for RETRO MARKET (izithrift).
///
/// Visual identity: Modern C2C Marketplace × Cozy Vintage Christmas
/// - Background: Light Cool Gray (#F4F5F7)
/// - Surface: Pure White (#FFFFFF)
/// - Primary Brand: Deep Pine Green (#174D38)
/// - Primary CTA: Terracotta (#C65335)
/// - Accent: Vintage Gold (#D6AE55)
///
/// Legacy constant hex values (warmIvory, primaryTerracotta, secondaryPineGreen,
/// accentVintageGold, christmasBerryRed, textCharcoal) are preserved verbatim
/// for unit test & consumer compatibility.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Surfaces & Canvas
  // ---------------------------------------------------------------------------
  /// Base legacy cream token (preserved verbatim for tests).
  static const Color warmIvory = Color(0xFFFBF8F3);

  /// Modern light cool gray scaffold canvas (#F4F5F7).
  static const Color canvasParchment = Color(0xFFF4F5F7);
  static const Color backgroundGray = Color(0xFFF4F5F7);

  /// Pure white elevated card & header surface (#FFFFFF).
  static const Color surfaceCard = Color(0xFFFFFFFF);

  /// Soft neutral secondary surface (chips, nested inputs, subtle pills).
  static const Color surfaceWarm = Color(0xFFEEF0F3);

  /// Clean elevated section container surface.
  static const Color surfaceSection = Color(0xFFFFFFFF);

  /// Warm vintage gold badge / timer tile fill ("Like New", "95%", "01:24:32").
  static const Color creamBadgeBg = Color(0xFFF8EED6);
  static const Color creamBadgeSoft = Color(0xFFFDF8EC);
  static const Color creamBadgeBorder = Color(0xFFE7D29D);
  static const Color creamBadgeText = Color(0xFF3E3022);

  /// Soft pine-tinted / warm fill for circular category badges.
  static const Color categoryCircleStart = Color(0xFFF3F8F5);
  static const Color categoryCircleEnd = Color(0xFFE4F0EA);

  static const Color surfaceDark = Color(0xFF1A201E);

  // ---------------------------------------------------------------------------
  // Brand Palette
  // ---------------------------------------------------------------------------
  /// Primary Brand: Deep Pine Green (#174D38) and tonal steps.
  static const Color pineDeep = Color(0xFF174D38);
  static const Color pineBanner = Color(0xFF174D38);
  static const Color pineBannerLight = Color(0xFF21664B);
  static const Color brandPine = Color(0xFF174D38);

  /// Primary Forest Green brand tokens mapped to Deep Pine Green.
  static const Color primaryForestGreen = Color(0xFF174D38);
  static const Color primaryForestGreenDark = Color(0xFF103828);
  static const Color primaryForestGreenLight = Color(0xFFE7F2EC);

  /// Primary CTA: Terracotta (#C65335) (legacy primaryTerracotta preserved verbatim).
  static const Color primaryTerracotta = Color(0xFFC85A32);
  static const Color primaryTerracottaDark = Color(0xFFA84227);
  static const Color ctaTerracotta = Color(0xFFC65335);
  static const Color ctaTerracottaHover = Color(0xFFA94227);
  static const Color ctaTerracottaSoft = Color(0xFFFBEDE9);

  /// Legacy secondary & crimson tokens (legacy values preserved verbatim for tests).
  static const Color secondaryPineGreen = Color(0xFF2D5A3C);
  static const Color christmasBerryRed = Color(0xFFB22222);
  static const Color priceCrimson = Color(0xFFC65335);
  static const Color priceCrimsonSoft = Color(0xFFFBEDE9);
  static const Color priceCrimsonBorder = Color(0xFFF0C6BA);

  /// Accent: Vintage Gold (#D6AE55) (legacy accentVintageGold preserved verbatim).
  static const Color accentVintageGold = Color(0xFFD4AF37);
  static const Color starGold = Color(0xFFD6AE55);
  static const Color brandGold = Color(0xFFD6AE55);
  static const Color accentBurgundy = christmasBerryRed;
  static const Color primaryVintageBrown = Color(0xFF84664C);
  static const Color vintageBrown = primaryVintageBrown;

  /// Verified shop pine green ("Shop uy tín").
  static const Color verifiedLeaf = Color(0xFF174D38);
  static const Color verifiedLeafBg = Color(0xFFE7F2EC);

  // ---------------------------------------------------------------------------
  // Typography, Borders & Neutrals
  // ---------------------------------------------------------------------------
  static const Color textCharcoal = Color(0xFF231F20);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color borderWarm = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFEDF0F4);
  static const Color darkFrostOverlay = Color(0x59000000);

  // Semantic aliases retained for existing screens.
  static const Color textDarkCharcoal = textCharcoal;
  static const Color textCharcoalMuted = textMuted;
  static const Color accentMutedGold = starGold;

  // ---------------------------------------------------------------------------
  // Status Colors
  // ---------------------------------------------------------------------------
  static const Color statusSuccess = Color(0xFF1E7E53);
  static const Color statusWarning = Color(0xFFD97706);
  static const Color statusDanger = Color(0xFFC52B25);
  static const Color statusInfo = Color(0xFF0288D1);

  // Auction-specific colors
  static const Color auctionLiveBadge = Color(0xFFC65335);
  static const Color auctionEndingSoon = Color(0xFFD9531E);

  // Backward-compatible alias. Do not use for new UI code.
  // ignore: constant_identifier_names
  static const Color backgroundCream = warmIvory;
}
