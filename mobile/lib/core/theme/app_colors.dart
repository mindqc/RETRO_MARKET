import 'package:flutter/material.dart';

/// Color tokens for RETRO MARKET (izithrift).
///
/// Visual identity derived from the approved Cozy Vintage Editorial reference:
/// - Warm linen/parchment canvas (#F6F1E9) & crisp white elevated cards (#FFFFFF)
/// - Deep Pine Green (#203A29 / #2D5A3C) for brand wordmark & dark auction spotlight blocks
/// - Festive Crimson (#BC2D25 / #B22222) for prices, active nav underline, discount/live badges
/// - Warm Burnt Terracotta (#B84A27 / #C85A32) for primary hero CTAs
/// - Cream Gold (#F4E3C1 / #E2A83B) for condition pills, flip-clock timers & star ratings
///
/// Legacy constant hex values are preserved verbatim for unit test & consumer compatibility.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Surfaces & Canvas
  // ---------------------------------------------------------------------------
  /// Base legacy cream token (preserved verbatim for tests).
  static const Color warmIvory = Color(0xFFFBF8F3);

  /// Approved reference warm linen parchment scaffold canvas.
  static const Color canvasParchment = Color(0xFFF6F1E9);

  /// Crisp elevated card surface.
  static const Color surfaceCard = Color(0xFFFFFFFF);

  /// Warm soft cream secondary surface (search bar, nested containers, chips).
  static const Color surfaceWarm = Color(0xFFF4EFE6);

  /// Soft elevated section container surface ("Deal Hot Hôm Nay" backdrop).
  static const Color surfaceSection = Color(0xFFFDFBF7);

  /// Warm cream-gold badge / timer tile fill ("Like New", "Good", "01:24:32").
  static const Color creamBadgeBg = Color(0xFFF4E3C1);
  static const Color creamBadgeSoft = Color(0xFFFDF3DF);
  static const Color creamBadgeBorder = Color(0xFFE5CE9E);
  static const Color creamBadgeText = Color(0xFF3E3022);

  /// Warm glow fill for circular category badges.
  static const Color categoryCircleStart = Color(0xFFFCF4E4);
  static const Color categoryCircleEnd = Color(0xFFF3E2C1);

  static const Color surfaceDark = Color(0xFF231F20);

  // ---------------------------------------------------------------------------
  // Brand Palette
  // ---------------------------------------------------------------------------
  /// Deep Pine Green for brand wordmark and dark auction spotlight headers.
  static const Color pineDeep = Color(0xFF1C3424);
  static const Color pineBanner = Color(0xFF24412E);
  static const Color pineBannerLight = Color(0xFF2E523A);

  /// Primary Forest Green brand color.
  static const Color primaryForestGreen = Color(0xFF2D5A3C);
  static const Color primaryForestGreenDark = Color(0xFF1F422C);
  static const Color primaryForestGreenLight = Color(0xFFE8F1EA);

  /// Warm Terracotta CTA palette (legacy primaryTerracotta preserved verbatim).
  static const Color primaryTerracotta = Color(0xFFC85A32);
  static const Color primaryTerracottaDark = Color(0xFFA34320);
  static const Color ctaTerracotta = Color(0xFFB84A27);
  static const Color ctaTerracottaHover = Color(0xFF9F3C1D);

  /// Crimson / Berry Red for prices, active tab underline, & urgency badges.
  static const Color secondaryPineGreen = Color(0xFF2D5A3C);
  static const Color christmasBerryRed = Color(0xFFB22222);
  static const Color priceCrimson = Color(0xFFBC2D25);
  static const Color priceCrimsonSoft = Color(0xFFFCECEB);
  static const Color priceCrimsonBorder = Color(0xFFF3C4C0);

  /// Vintage Gold & Star Ratings.
  static const Color accentVintageGold = Color(0xFFD4AF37);
  static const Color starGold = Color(0xFFE2A83B);
  static const Color accentBurgundy = christmasBerryRed;
  static const Color primaryVintageBrown = Color(0xFF84664C);
  static const Color vintageBrown = primaryVintageBrown;

  /// Verified shop leaf green ("Shop uy tín").
  static const Color verifiedLeaf = Color(0xFF2E7D4A);
  static const Color verifiedLeafBg = Color(0xFFE8F4EC);

  // ---------------------------------------------------------------------------
  // Typography, Borders & Neutrals
  // ---------------------------------------------------------------------------
  static const Color textCharcoal = Color(0xFF231F20);
  static const Color textMuted = Color(0xFF766C63);
  static const Color textLight = Color(0xFFFAF7F2);
  static const Color borderWarm = Color(0xFFE7DFD2);
  static const Color borderSubtle = Color(0xFFF0E9DE);
  static const Color darkFrostOverlay = Color(0x59000000);

  // Semantic aliases retained for existing screens.
  static const Color textDarkCharcoal = textCharcoal;
  static const Color textCharcoalMuted = textMuted;
  static const Color accentMutedGold = accentVintageGold;

  // ---------------------------------------------------------------------------
  // Status Colors
  // ---------------------------------------------------------------------------
  static const Color statusSuccess = Color(0xFF2E7D4A);
  static const Color statusWarning = Color(0xFFD97706);
  static const Color statusDanger = Color(0xFFC52B25);
  static const Color statusInfo = Color(0xFF0288D1);

  // Auction-specific colors
  static const Color auctionLiveBadge = Color(0xFFBC2D25);
  static const Color auctionEndingSoon = Color(0xFFD9531E);

  // Backward-compatible alias. Do not use for new UI code.
  // ignore: constant_identifier_names
  static const Color backgroundCream = warmIvory;
}
