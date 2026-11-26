import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../utils/vnd_formatter.dart';
import 'retro_product_image.dart';
import 'server_countdown_timer.dart';
import 'status_pill_badge.dart';

/// Visually distinctive auction card for Home carousels & Auction Hub grids.
///
/// Clearly differentiates Ongoing (LIVE), Ending Soon (<= 15m), Upcoming (SCHEDULED),
/// and Completed sessions with state-specific accent strips, countdowns, pricing
/// hierarchy, bid/watch counts, and action CTAs.
class RetroAuctionCard extends StatelessWidget {
  final int id;
  final String title;
  final num currentBid;
  final num? startingPrice;
  final int bidCount;
  final int watchCount;
  final DateTime? startsAt;
  final DateTime endsAt;
  final String? primaryImageUrl;
  final String? categoryName;
  final String status;
  final int extendedCount;
  final bool isOwner;
  final bool showCtaButton;
  final bool compactCarousel;
  final VoidCallback? onTap;

  const RetroAuctionCard({
    super.key,
    required this.id,
    required this.title,
    required this.currentBid,
    this.startingPrice,
    required this.bidCount,
    this.watchCount = 0,
    this.startsAt,
    required this.endsAt,
    this.primaryImageUrl,
    this.categoryName,
    this.status = 'LIVE',
    this.extendedCount = 0,
    this.isOwner = false,
    this.showCtaButton = true,
    this.compactCarousel = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toUpperCase();
    final isScheduled = normalizedStatus == 'SCHEDULED';
    final isLive = normalizedStatus == 'LIVE';
    final remaining = endsAt.difference(DateTime.now());
    final isEndingSoon =
        isLive && remaining.inSeconds > 0 && remaining.inMinutes <= 15;
    final countdownTarget =
        isScheduled && startsAt != null ? startsAt! : endsAt;

    if (compactCarousel) {
      return _buildCompactCarouselCard(
        isScheduled: isScheduled,
        isLive: isLive,
        isEndingSoon: isEndingSoon,
        countdownTarget: countdownTarget,
      );
    }

    final Color topAccentColor;
    final Color cardBorderColor;
    final Color footerTint;
    final Color priceColor;
    final String ctaLabel;
    final Color ctaBg;
    final Color ctaFg;

    if (isEndingSoon) {
      topAccentColor = AppColors.priceCrimson;
      cardBorderColor = AppColors.priceCrimsonBorder;
      footerTint = AppColors.priceCrimsonSoft.withValues(alpha: 0.45);
      priceColor = AppColors.priceCrimson;
      ctaLabel = 'Đặt giá gấp';
      ctaBg = AppColors.priceCrimson;
      ctaFg = Colors.white;
    } else if (isLive) {
      topAccentColor = AppColors.pineDeep;
      cardBorderColor = AppColors.borderWarm;
      footerTint = AppColors.surfaceCard;
      priceColor = AppColors.priceCrimson;
      ctaLabel = 'Đấu giá ngay';
      ctaBg = AppColors.ctaTerracotta;
      ctaFg = Colors.white;
    } else if (isScheduled) {
      topAccentColor = AppColors.starGold;
      cardBorderColor = AppColors.creamBadgeBorder;
      footerTint = AppColors.creamBadgeSoft.withValues(alpha: 0.45);
      priceColor = AppColors.pineDeep;
      ctaLabel = 'Giữ chỗ';
      ctaBg = AppColors.creamBadgeBg;
      ctaFg = AppColors.creamBadgeText;
    } else {
      topAccentColor = AppColors.textMuted;
      cardBorderColor = AppColors.borderWarm;
      footerTint = AppColors.surfaceWarm.withValues(alpha: 0.5);
      priceColor = AppColors.textCharcoal;
      ctaLabel = 'Xem kết quả';
      ctaBg = AppColors.surfaceWarm;
      ctaFg = AppColors.textCharcoal;
    }

    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            color: footerTint,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: cardBorderColor,
              width: isEndingSoon ? 1.4 : DesignTokens.borderThin,
            ),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Distinct top state accent bar
              Container(height: 3.5, width: double.infinity, color: topAccentColor),

              // ── Photo Frame with Status & Live Countdown ──────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RetroProductImage(
                          imageUrl: primaryImageUrl,
                          title: title,
                          categoryName: categoryName,
                          productId: id,
                          fit: BoxFit.cover,
                        ),
                        // Subtle bottom vignette for countdown readability
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 46,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.46),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Top-left state pill (Ending Soon / Upcoming / Live / Completed)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: isEndingSoon
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7.5,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.priceCrimson,
                                    borderRadius: DesignTokens.borderRadiusFull,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.bolt_rounded,
                                        size: 11,
                                        color: AppColors.creamBadgeBg,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'Sắp kết thúc',
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontBody,
                                          color: Colors.white,
                                          fontSize: 9.8,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : isScheduled
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7.5,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.creamBadgeBg,
                                        borderRadius:
                                            DesignTokens.borderRadiusFull,
                                        border: Border.all(
                                          color: AppColors.starGold,
                                          width: 0.9,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.schedule_rounded,
                                            size: 10.5,
                                            color: AppColors.creamBadgeText,
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Sắp mở phiên',
                                            style: TextStyle(
                                              fontFamily:
                                                  AppTypography.fontBody,
                                              color: AppColors.creamBadgeText,
                                              fontSize: 9.6,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : StatusPillBadge(
                                      status: status,
                                      isCompact: true,
                                    ),
                        ),
                        // Bottom-left real ticking countdown
                        Positioned(
                          bottom: isOwner ? 26 : 6,
                          left: 6,
                          child: ServerCountdownTimer(
                            endsAt: countdownTarget,
                            extendedCount: extendedCount,
                            isCompact: true,
                          ),
                        ),
                        if (isOwner)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.spaceSm,
                                vertical: 3,
                              ),
                              color: AppColors.pineDeep.withValues(alpha: 0.92),
                              child: Text(
                                'Phiên đấu của bạn (BR-AC-02)',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textLight,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Auction Title, Pricing Context & Action CTA ───────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 12.6,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textCharcoal,
                        height: 1.22,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          isScheduled
                              ? Icons.sell_outlined
                              : Icons.gavel_rounded,
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            isScheduled ? 'Giá khởi điểm' : 'Giá hiện tại',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        if (!isScheduled &&
                            startingPrice != null &&
                            startingPrice! > 0 &&
                            startingPrice! < currentBid)
                          Text(
                            'KĐ ${VndFormatter.format(startingPrice!)}',
                            style: AppTypography.caption.copyWith(
                              fontSize: 9.2,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      VndFormatter.format(currentBid),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.priceMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: priceColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          isScheduled
                              ? Icons.people_alt_outlined
                              : (isEndingSoon
                                    ? Icons.whatshot_rounded
                                    : Icons.local_fire_department_rounded),
                          size: 12.5,
                          color: isScheduled
                              ? AppColors.pineDeep
                              : (isEndingSoon
                                    ? AppColors.priceCrimson
                                    : AppColors.ctaTerracotta),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            isScheduled
                                ? '${watchCount > 0 ? watchCount : 12} giữ chỗ'
                                : '$bidCount lượt trả',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (showCtaButton) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.5,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ctaBg,
                              borderRadius: DesignTokens.borderRadiusFull,
                              border: isScheduled
                                  ? Border.all(
                                      color: AppColors.creamBadgeBorder,
                                    )
                                  : null,
                            ),
                            child: Text(
                              ctaLabel,
                              style: TextStyle(
                                fontFamily: AppTypography.fontBody,
                                color: ctaFg,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact horizontal auction card layout for Home "Đấu giá nổi bật" carousel.
  Widget _buildCompactCarouselCard({
    required bool isScheduled,
    required bool isLive,
    required bool isEndingSoon,
    required DateTime countdownTarget,
  }) {
    final participants =
        watchCount > 0 ? watchCount : (bidCount > 0 ? bidCount + 12 : 18);

    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: isEndingSoon
                  ? AppColors.priceCrimsonBorder
                  : (isScheduled
                        ? AppColors.creamBadgeBorder
                        : AppColors.borderWarm),
              width: isEndingSoon ? 1.3 : DesignTokens.borderThin,
            ),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RetroProductImage(
                      imageUrl: primaryImageUrl,
                      title: title,
                      categoryName: categoryName,
                      productId: id,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 40,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.48),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Top-left state badge
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: isEndingSoon
                              ? AppColors.priceCrimson
                              : (isScheduled
                                    ? AppColors.creamBadgeBg
                                    : AppColors.pineDeep),
                          borderRadius: DesignTokens.borderRadiusFull,
                          border: isScheduled
                              ? Border.all(
                                  color: AppColors.starGold,
                                  width: 0.8,
                                )
                              : null,
                        ),
                        child: Text(
                          isEndingSoon
                              ? '⚡ Sắp hết giờ'
                              : (isScheduled
                                    ? '⏰ Sắp mở'
                                    : (isLive ? '● LIVE' : 'Đã xong')),
                          style: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            color: isScheduled
                                ? AppColors.creamBadgeText
                                : Colors.white,
                            fontSize: 9.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    // Bottom-left ticking countdown pill
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: ServerCountdownTimer(
                        endsAt: countdownTarget,
                        extendedCount: extendedCount,
                        isCompact: true,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 12.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textCharcoal,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2.5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            VndFormatter.format(currentBid),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.priceMedium.copyWith(
                              fontSize: 14.2,
                              fontWeight: FontWeight.w800,
                              color: isScheduled
                                  ? AppColors.pineDeep
                                  : AppColors.priceCrimson,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3.5),
                    Row(
                      children: [
                        Icon(
                          isScheduled
                              ? Icons.notifications_active_outlined
                              : Icons.gavel_rounded,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isScheduled
                                ? '$participants giữ chỗ'
                                : '$bidCount lượt • $participants xem',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10.2,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
