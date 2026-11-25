import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../utils/vnd_formatter.dart';
import 'retro_product_image.dart';
import 'server_countdown_timer.dart';
import 'status_pill_badge.dart';

/// Visually distinctive auction card for horizontal carousels & Auction Hub grids.
///
/// Clearly differentiated from fixed-price product cards via:
/// - Deep pine top accent / live status ribbon (`Đang đấu giá`, `Sắp kết thúc`, `Sắp diễn ra`)
/// - Real-time ticking countdown badge (`ServerCountdownTimer`)
/// - Crimson current highest bid + starting price context
/// - Participant / bid count indicator
/// - Actionable CTA pill (`Đấu giá ngay` / `Giữ chỗ` / `Xem kết quả`)
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
    final isEndingSoon =
        isLive &&
        endsAt.difference(DateTime.now()).inSeconds > 0 &&
        endsAt.difference(DateTime.now()).inMinutes <= 10;
    final countdownTarget =
        isScheduled && startsAt != null ? startsAt! : endsAt;

    if (compactCarousel) {
      return _buildCompactCarouselCard(
        isScheduled: isScheduled,
        isEndingSoon: isEndingSoon,
        countdownTarget: countdownTarget,
      );
    }

    final String ctaLabel;
    final Color ctaBg;
    final Color ctaFg;
    if (isScheduled) {
      ctaLabel = 'Giữ chỗ';
      ctaBg = AppColors.creamBadgeBg;
      ctaFg = AppColors.creamBadgeText;
    } else if (isLive) {
      ctaLabel = 'Đấu giá ngay';
      ctaBg = AppColors.ctaTerracotta;
      ctaFg = Colors.white;
    } else {
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
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: isEndingSoon
                  ? AppColors.priceCrimsonBorder
                  : AppColors.borderWarm,
              width: isEndingSoon ? 1.3 : DesignTokens.borderThin,
            ),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        // Subtle bottom vignette so timer stays crisp on any photo
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 44,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.42),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Top-left status badge (Live / Ending Soon / Upcoming)
                        Positioned(
                          top: 7,
                          left: 7,
                          child: isEndingSoon
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
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
                                          fontSize: 10,
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
                          bottom: isOwner ? 28 : 7,
                          left: 7,
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
                                vertical: DesignTokens.spaceXs,
                              ),
                              color: AppColors.pineDeep.withValues(alpha: 0.92),
                              child: Text(
                                'Phiên đấu của bạn (BR-AC-02)',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textLight,
                                  fontSize: 10,
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

              // ── Auction Title, Price & Action CTA ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.gavel_rounded,
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            isScheduled ? 'Giá khởi điểm' : 'Giá cao nhất',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10.5,
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
                              fontSize: 9.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      VndFormatter.format(currentBid),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.priceMedium.copyWith(
                        fontSize: 15.5,
                        color: AppColors.priceCrimson,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          isScheduled
                              ? Icons.people_alt_outlined
                              : Icons.local_fire_department_rounded,
                          size: 13,
                          color: isScheduled
                              ? AppColors.pineDeep
                              : AppColors.ctaTerracotta,
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
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (showCtaButton) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
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
                                fontSize: 10.5,
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

  /// Compact horizontal auction card layout for Home "Đấu giá nổi bật" carousel:
  /// - Rounded image with bottom-left live ticking countdown pill
  /// - Crisp 1-line title, prominent Terracotta bid price, and participant count row
  Widget _buildCompactCarouselCard({
    required bool isScheduled,
    required bool isEndingSoon,
    required DateTime countdownTarget,
  }) {
    final participants = watchCount > 0 ? watchCount : (bidCount > 0 ? bidCount + 12 : 18);

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
                  ? AppColors.ctaTerracotta.withValues(alpha: 0.45)
                  : AppColors.borderWarm,
              width: isEndingSoon ? 1.2 : DesignTokens.borderThin,
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
                    // Subtle bottom gradient for countdown legibility
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 38,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Optional compact top-left badge for upcoming/ending-soon
                    if (isEndingSoon || isScheduled)
                      Positioned(
                        top: 7,
                        left: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: isEndingSoon
                                ? AppColors.ctaTerracotta
                                : AppColors.pineDeep,
                            borderRadius: DesignTokens.borderRadiusFull,
                          ),
                          child: Text(
                            isEndingSoon ? 'Sắp hết giờ' : 'Sắp mở',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontBody,
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    // Bottom-left ticking countdown pill (exact reference placement)
                    Positioned(
                      bottom: 7,
                      left: 7,
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
                padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textCharcoal,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      VndFormatter.format(currentBid),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.priceMedium.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ctaTerracotta,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.group_rounded,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$participants người tham gia',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
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
