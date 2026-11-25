import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../utils/vnd_formatter.dart';
import 'server_countdown_timer.dart';
import 'status_pill_badge.dart';
import 'state_feedback_views.dart';

/// Editorial auction card with live status ribbon, server-synchronized countdown,
/// crimson bid value, and warm cream-gold bid-count chip matching the reference.
class RetroAuctionCard extends StatelessWidget {
  final int id;
  final String title;
  final num currentBid;
  final int bidCount;
  final DateTime endsAt;
  final String? primaryImageUrl;
  final String status;
  final int extendedCount;
  final bool isOwner;
  final VoidCallback? onTap;

  const RetroAuctionCard({
    super.key,
    required this.id,
    required this.title,
    required this.currentBid,
    required this.bidCount,
    required this.endsAt,
    this.primaryImageUrl,
    this.status = 'LIVE',
    this.extendedCount = 0,
    this.isOwner = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.borderWarm,
              width: DesignTokens.borderThin,
            ),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildAuctionImage(),
                        Positioned(
                          top: 7,
                          left: 7,
                          child: StatusPillBadge(
                            status: status,
                            isCompact: true,
                          ),
                        ),
                        Positioned(
                          bottom: isOwner ? 28 : 7,
                          left: 7,
                          child: ServerCountdownTimer(
                            endsAt: endsAt,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.gavel_rounded,
                                    size: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Giá hiện tại',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 10.5,
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
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.creamBadgeSoft,
                            borderRadius: DesignTokens.borderRadiusFull,
                            border: Border.all(
                              color: AppColors.creamBadgeBorder,
                            ),
                          ),
                          child: Text(
                            '$bidCount lượt trả',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.creamBadgeText,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
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

  Widget _buildAuctionImage() {
    if (primaryImageUrl == null || primaryImageUrl!.isEmpty) {
      return Container(
        color: AppColors.surfaceWarm,
        child: const Center(
          child: Icon(
            Icons.gavel_outlined,
            color: AppColors.textMuted,
            size: 36,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: primaryImageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => const RetroShimmerBox(
        width: double.infinity,
        height: double.infinity,
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.surfaceWarm,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.textMuted,
            size: 34,
          ),
        ),
      ),
    );
  }
}
