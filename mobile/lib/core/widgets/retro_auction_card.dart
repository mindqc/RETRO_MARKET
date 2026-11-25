import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../utils/vnd_formatter.dart';
import 'server_countdown_timer.dart';
import 'status_pill_badge.dart';
import 'state_feedback_views.dart';

/// Editorial auction card with live status and server-synchronized countdown.
/// Keeps BR-AC-02 ownership awareness and all existing auction data behavior.
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildAuctionImage(),
                    Positioned(
                      top: DesignTokens.spaceSm,
                      right: DesignTokens.spaceSm,
                      child: StatusPillBadge(status: status, isCompact: true),
                    ),
                    Positioned(
                      bottom: isOwner ? 30 : DesignTokens.spaceSm,
                      left: DesignTokens.spaceSm,
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
                          color: AppColors.primaryForestGreen.withValues(
                            alpha: 0.92,
                          ),
                          child: Text(
                            'Phiên đấu của bạn (BR-AC-02)',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.spaceMd,
                  DesignTokens.spaceSm,
                  DesignTokens.spaceMd,
                  DesignTokens.spaceMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giá hiện tại',
                                style: AppTypography.caption,
                              ),
                              const SizedBox(height: DesignTokens.space2xs),
                              Text(
                                VndFormatter.format(currentBid),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.priceMedium.copyWith(
                                  color: AppColors.primaryForestGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spaceXs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.spaceSm,
                            vertical: DesignTokens.spaceXs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryForestGreenLight,
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusFull,
                            ),
                          ),
                          child: Text(
                            '$bidCount lượt trả',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForestGreenDark,
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
            size: 36,
          ),
        ),
      ),
    );
  }
}
