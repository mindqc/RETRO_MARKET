import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../utils/vnd_formatter.dart';
import 'server_countdown_timer.dart';
import 'status_pill_badge.dart';
import 'state_feedback_views.dart';

/// RetroAuctionCard displays scheduled or live auction cards with live countdown
/// Enforces BR-AC-02 awareness (highlights if the auction is hosted by viewing user).
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: AppColors.borderWarm, width: DesignTokens.borderThin),
          boxShadow: DesignTokens.cardElevation,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with Countdown & Status overlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildAuctionImage(),
                  // Top right live or status badge
                  Positioned(
                    top: DesignTokens.spaceSm,
                    right: DesignTokens.spaceSm,
                    child: StatusPillBadge(status: status, isCompact: true),
                  ),
                  // Bottom left countdown timer
                  Positioned(
                    bottom: isOwner ? 22 : DesignTokens.spaceSm,
                    left: DesignTokens.spaceSm,
                    child: ServerCountdownTimer(
                      endsAt: endsAt,
                      extendedCount: extendedCount,
                      isCompact: true,
                    ),
                  ),
                  // Owner notice
                  if (isOwner)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        color: AppColors.surfaceDark.withValues(alpha: 0.8),
                        child: Text(
                          'Phiên đấu của bạn (BR-AC-02)',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Auction Details
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceXs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Giá hiện tại', style: AppTypography.caption),
                            Text(
                              VndFormatter.format(currentBid),
                              style: AppTypography.priceMedium.copyWith(
                                color: AppColors.christmasBerryRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                        ),
                        child: Text(
                          '$bidCount lượt trả',
                          style: AppTypography.caption.copyWith(
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
    );
  }

  Widget _buildAuctionImage() {
    if (primaryImageUrl == null || primaryImageUrl!.isEmpty) {
      return Container(
        color: AppColors.surfaceWarm,
        child: const Center(
          child: Icon(Icons.gavel_outlined, color: AppColors.textMuted, size: 36),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: primaryImageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => const RetroShimmerBox(width: double.infinity, height: double.infinity),
      errorWidget: (context, url, error) => Container(
        color: AppColors.surfaceWarm,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 36),
        ),
      ),
    );
  }
}
