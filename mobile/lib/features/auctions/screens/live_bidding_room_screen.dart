import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/server_time_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/condition_badge.dart';
import '../../../core/widgets/server_countdown_timer.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../../core/widgets/status_pill_badge.dart';
import '../models/auction_detail_model.dart';
import '../viewmodels/live_auction_view_model.dart';
import 'bid_placement_bottom_sheet.dart';
import 'seller_close_early_modal.dart';
import 'seller_relist_auction_modal.dart';

/// Screen M-AC-03: Live Bidding Room & Real-time Anti-Sniping Hub
class LiveBiddingRoomScreen extends ConsumerStatefulWidget {
  final int auctionId;

  const LiveBiddingRoomScreen({
    super.key,
    required this.auctionId,
  });

  @override
  ConsumerState<LiveBiddingRoomScreen> createState() => _LiveBiddingRoomScreenState();
}

class _LiveBiddingRoomScreenState extends ConsumerState<LiveBiddingRoomScreen> {
  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(liveAuctionViewModelProvider(widget.auctionId));

    if (vm.isLoading && vm.auction == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundCream,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceCard,
          title: const Text('Phòng Đấu Giá'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryForestGreen),
        ),
      );
    }

    if (vm.isError && vm.auction == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundCream,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceCard,
          title: const Text('Phòng Đấu Giá'),
        ),
        body: RetroErrorRetryView(
          errorMessage: vm.errorMessage ?? 'Không thể tải chi tiết phòng đấu giá.',
          onRetry: () => ref.read(liveAuctionViewModelProvider(widget.auctionId).notifier).loadAuction(),
        ),
      );
    }

    final auction = vm.auction!;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDarkCharcoal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          auction.productTitle,
          style: AppTypography.headingSmall.copyWith(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              auction.isWatching ? Icons.favorite : Icons.favorite_border,
              color: auction.isWatching ? Colors.redAccent : AppColors.textDarkCharcoal,
            ),
            onPressed: () {
              ref.read(liveAuctionViewModelProvider(widget.auctionId).notifier).toggleWatch();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Anti-Sniping Sticky Banner (BR-AU-04)
          if (auction.extendedCount > 0 || vm.justTriggeredAntiSniping)
            _buildAntiSnipingBanner(vm, auction),

          // Main Room Scrollable Body
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryForestGreen,
              onRefresh: () =>
                  ref.read(liveAuctionViewModelProvider(widget.auctionId).notifier).loadAuction(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(DesignTokens.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Synchronized Countdown Card
                    _buildCountdownCard(auction),
                    const SizedBox(height: DesignTokens.spacingMd),

                    // Product Image & Price Section
                    _buildProductSection(auction),
                    const SizedBox(height: DesignTokens.spacingMd),

                    // Seller & Reserve Price Info
                    _buildSellerAndReserveSection(auction),
                    const SizedBox(height: DesignTokens.spacingLg),

                    // Live Bid History (Short-polling updated)
                    _buildBidHistorySection(auction),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          _buildBottomActionBar(context, vm, auction),
        ],
      ),
    );
  }

  Widget _buildAntiSnipingBanner(LiveAuctionViewModel vm, AuctionDetailModel auction) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentBurgundy,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBurgundy.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Colors.amberAccent, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚡ Đã kích hoạt Anti-Sniping (+2 phút) • Gia hạn lần #${auction.extendedCount}',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (vm.justTriggeredAntiSniping)
            GestureDetector(
              onTap: () => vm.dismissAntiSnipingBanner(),
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard(AuctionDetailModel auction) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: auction.extendedCount > 0 ? AppColors.accentBurgundy : AppColors.borderWarm,
          width: auction.extendedCount > 0 ? 1.5 : DesignTokens.borderThin,
        ),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                auction.isLive ? Icons.timer : Icons.lock_clock,
                size: 18,
                color: auction.isLive ? AppColors.accentBurgundy : AppColors.textCharcoalMuted,
              ),
              const SizedBox(width: 8),
              Text(
                auction.isLive
                    ? 'Thời gian còn lại của phiên đấu giá:'
                    : (auction.isScheduled ? 'Thời gian mở phiên:' : 'Phiên đấu giá đã kết thúc'),
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ServerCountdownTimer(
            endsAt: auction.isScheduled && auction.auctionStartsAt != null
                ? auction.auctionStartsAt!
                : auction.auctionEndsAt,
            extendedCount: auction.extendedCount,
            customClock: () => ServerTimeService.instance.now(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection(AuctionDetailModel auction) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Image
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: auction.primaryImageUrl != null && auction.primaryImageUrl!.isNotEmpty
                  ? Image.network(
                      auction.primaryImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.surfaceWarm,
                        child: const Icon(Icons.broken_image, color: AppColors.textCharcoalMuted, size: 48),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceWarm,
                      child: const Icon(Icons.gavel, color: AppColors.primaryVintageBrown, size: 48),
                    ),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),

          // Condition Badge & Title
          Row(
            children: [
              if (auction.condition != null) ConditionBadge(condition: auction.condition!),
              const SizedBox(width: 8),
              StatusPillBadge(status: auction.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            auction.productTitle,
            style: AppTypography.headingMedium.copyWith(fontSize: 18),
          ),
          if (auction.productDescription != null && auction.productDescription!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              auction.productDescription!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textDarkCharcoal),
            ),
          ],
          const SizedBox(height: DesignTokens.spacingMd),

          // Current Highest Bid Highlight
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giá cao nhất hiện tại:', style: AppTypography.bodySmall),
                    Text(
                      VndFormatter.format(auction.currentHighestBid),
                      style: AppTypography.priceLarge.copyWith(
                        color: AppColors.accentBurgundy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Lượt trả giá:', style: AppTypography.bodySmall),
                    Text(
                      '${auction.bidCount} lượt',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerAndReserveSection(AuctionDetailModel auction) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryForestGreen.withAlpha(30),
                backgroundImage:
                    auction.sellerAvatarUrl != null ? NetworkImage(auction.sellerAvatarUrl!) : null,
                child: auction.sellerAvatarUrl == null
                    ? const Icon(Icons.storefront, color: AppColors.primaryForestGreen)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.sellerDisplayName ?? 'Chủ tiệm Retro',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Độ tin cậy: ${auction.sellerTrustScore.toStringAsFixed(0)}% uy tín',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textCharcoalMuted),
                    ),
                  ],
                ),
              ),
              if (auction.isOwner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryForestGreen.withAlpha(20),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: Text(
                    'Tiệm của bạn',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryForestGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (auction.hasReservePrice) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  auction.reservePriceMet ? Icons.check_circle : Icons.shield_outlined,
                  size: 18,
                  color: auction.reservePriceMet ? AppColors.primaryForestGreen : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  auction.reservePriceMet
                      ? 'Đã đạt giá sàn bảo lưu của người bán.'
                      : (auction.reservePrice != null
                          ? 'Giá sàn: ${VndFormatter.format(auction.reservePrice!)} (Chưa đạt)'
                          : 'Phiên đấu giá có giá sàn bảo lưu ẩn.'),
                  style: AppTypography.bodySmall.copyWith(
                    color: auction.reservePriceMet ? AppColors.primaryForestGreen : Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBidHistorySection(AuctionDetailModel auction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 18, color: AppColors.primaryForestGreen),
            const SizedBox(width: 6),
            Text(
              'Lịch Sử Trả Giá Trực Tiếp',
              style: AppTypography.headingSmall.copyWith(fontSize: 16),
            ),
            const Spacer(),
            Text(
              'Tự động làm mới mỗi 3s',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.textCharcoalMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        if (auction.recentBids.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spacingLg),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: AppColors.borderWarm),
            ),
            child: Center(
              child: Text(
                'Chưa có lượt trả giá nào. Hãy là người đầu tiên đặt giá!',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textCharcoalMuted),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: auction.recentBids.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final bid = auction.recentBids[index];
              final isTop = index == 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isTop ? AppColors.primaryForestGreen.withAlpha(15) : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  border: Border.all(
                    color: isTop ? AppColors.primaryForestGreen : AppColors.borderWarm,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isTop ? AppColors.primaryForestGreen : AppColors.surfaceWarm,
                      child: Text(
                        bid.bidderName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isTop ? Colors.white : AppColors.textDarkCharcoal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                bid.bidderName,
                                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (isTop) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryForestGreen,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '👑 Dẫn đầu',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                              if (bid.isMine) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentBurgundy,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Tôi',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (bid.triggeredAntiSniping)
                            Text(
                              '⚡ Kích hoạt Anti-Sniping',
                              style: AppTypography.bodySmall.copyWith(fontSize: 10, color: Colors.orange.shade800),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      VndFormatter.format(bid.bidAmount),
                      style: AppTypography.priceMedium.copyWith(
                        color: isTop ? AppColors.accentBurgundy : AppColors.textDarkCharcoal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    LiveAuctionViewModel vm,
    AuctionDetailModel auction,
  ) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: const Border(top: BorderSide(color: AppColors.borderWarm)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Completed auction states
            if (auction.isCompleted) ...[
              if (auction.canRelist) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final newA = await SellerRelistAuctionModal.show(context, auction.id);
                      if (context.mounted && newA != null) {
                        context.pushReplacement(AppRoutes.auctionRoomPath(newA.id));
                      }
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Tái đăng phiên đấu giá (M-AC-06)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryForestGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      'Phiên đấu giá đã kết thúc (${auction.status})',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textCharcoalMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ]
            // Owner view (BR-AC-02: cannot place bids on own auction)
            else if (auction.isOwner) ...[
              if (auction.canCloseEarly)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      SellerCloseEarlyModal.show(context, auction.id);
                    },
                    icon: const Icon(Icons.gavel),
                    label: const Text('Chốt phiên sớm (M-AC-05)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryForestGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      'Bạn là chủ phiên đấu giá này (BR-AC-02)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textCharcoalMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ]
            // Regular bidder view
            else ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: auction.isLive
                            ? () {
                                BidPlacementBottomSheet.show(context, auction.id);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBurgundy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.gavel, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              '🔨 ĐẶT GIÁ THẦU NGAY',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
