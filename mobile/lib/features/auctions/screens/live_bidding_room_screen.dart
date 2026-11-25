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
import '../../../core/widgets/retro_design_primitives.dart';
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

  const LiveBiddingRoomScreen({super.key, required this.auctionId});

  @override
  ConsumerState<LiveBiddingRoomScreen> createState() =>
      _LiveBiddingRoomScreenState();
}

class _LiveBiddingRoomScreenState extends ConsumerState<LiveBiddingRoomScreen> {
  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(liveAuctionViewModelProvider(widget.auctionId));

    if (vm.isLoading && vm.auction == null) {
      return Scaffold(
        backgroundColor: AppColors.canvasParchment,
        appBar: AppBar(title: const Text('Phòng Đấu Giá')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.ctaTerracotta),
        ),
      );
    }

    if (vm.isError && vm.auction == null) {
      return Scaffold(
        backgroundColor: AppColors.canvasParchment,
        appBar: AppBar(title: const Text('Phòng Đấu Giá')),
        body: RetroErrorRetryView(
          errorMessage:
              vm.errorMessage ?? 'Không thể tải chi tiết phòng đấu giá.',
          onRetry: () => ref
              .read(liveAuctionViewModelProvider(widget.auctionId).notifier)
              .loadAuction(),
        ),
      );
    }

    final auction = vm.auction!;

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textCharcoal,
          ),
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
              auction.isWatching
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: auction.isWatching
                  ? AppColors.priceCrimson
                  : AppColors.textCharcoal,
            ),
            onPressed: () {
              ref
                  .read(liveAuctionViewModelProvider(widget.auctionId).notifier)
                  .toggleWatch();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (auction.extendedCount > 0 || vm.justTriggeredAntiSniping)
            _buildAntiSnipingBanner(vm, auction),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.ctaTerracotta,
              onRefresh: () => ref
                  .read(liveAuctionViewModelProvider(widget.auctionId).notifier)
                  .loadAuction(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCountdownStage(auction),
                    const SizedBox(height: 14),
                    _buildProductSection(auction),
                    const SizedBox(height: 14),
                    _buildSellerAndReserveSection(auction),
                    const SizedBox(height: 20),
                    _buildBidHistorySection(auction),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomActionBar(context, vm, auction),
        ],
      ),
    );
  }

  Widget _buildAntiSnipingBanner(
    LiveAuctionViewModel vm,
    AuctionDetailModel auction,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: AppColors.priceCrimson),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.creamBadgeBg, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚡ Đã kích hoạt Anti-Sniping (+2 phút) • Gia hạn lần #${auction.extendedCount}',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (vm.justTriggeredAntiSniping)
            GestureDetector(
              onTap: () => vm.dismissAntiSnipingBanner(),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountdownStage(AuctionDetailModel auction) {
    final targetTime = auction.isScheduled && auction.auctionStartsAt != null
        ? auction.auctionStartsAt!
        : auction.auctionEndsAt;

    return RetroPineSpotlightContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                auction.isLive
                    ? Icons.gavel_rounded
                    : Icons.lock_clock_outlined,
                size: 17,
                color: AppColors.starGold,
              ),
              const SizedBox(width: 7),
              Text(
                auction.isLive
                    ? 'Thời gian còn lại của phiên đấu giá:'
                    : (auction.isScheduled
                        ? 'Thời gian mở phiên:'
                        : 'Phiên đấu giá đã kết thúc'),
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ServerCountdownTimer(
            endsAt: targetTime,
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
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: auction.primaryImageUrl != null &&
                      auction.primaryImageUrl!.isNotEmpty
                  ? Image.network(
                      auction.primaryImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.surfaceWarm,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textMuted,
                          size: 46,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceWarm,
                      child: const Icon(
                        Icons.gavel_rounded,
                        color: AppColors.pineDeep,
                        size: 46,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (auction.condition != null)
                ConditionBadge(condition: auction.condition!),
              StatusPillBadge(status: auction.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            auction.productTitle,
            style: AppTypography.headingMedium.copyWith(fontSize: 19),
          ),
          if (auction.productDescription != null &&
              auction.productDescription!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              auction.productDescription!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.creamBadgeSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.creamBadgeBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giá cao nhất hiện tại:',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.creamBadgeText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      VndFormatter.format(auction.currentHighestBid),
                      style: AppTypography.priceLarge.copyWith(
                        color: AppColors.priceCrimson,
                        fontSize: 23,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Lượt trả giá:',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.creamBadgeText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: DesignTokens.borderRadiusFull,
                        border: Border.all(color: AppColors.creamBadgeBorder),
                      ),
                      child: Text(
                        '${auction.bidCount} lượt',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textCharcoal,
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
    );
  }

  Widget _buildSellerAndReserveSection(AuctionDetailModel auction) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.categoryCircleEnd,
                backgroundImage: auction.sellerAvatarUrl != null
                    ? NetworkImage(auction.sellerAvatarUrl!)
                    : null,
                child: auction.sellerAvatarUrl == null
                    ? const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.pineDeep,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.sellerDisplayName ?? 'Chủ tiệm Retro',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Độ tin cậy: ${auction.sellerTrustScore.toStringAsFixed(0)}% uy tín',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              if (auction.isOwner)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.verifiedLeafBg,
                    borderRadius: DesignTokens.borderRadiusFull,
                  ),
                  child: const Text(
                    'Tiệm của bạn',
                    style: TextStyle(
                      color: AppColors.verifiedLeaf,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                const RetroVerifiedShopChip(),
            ],
          ),
          if (auction.hasReservePrice) ...[
            const Divider(height: 22),
            Row(
              children: [
                Icon(
                  auction.reservePriceMet
                      ? Icons.check_circle_rounded
                      : Icons.shield_outlined,
                  size: 18,
                  color: auction.reservePriceMet
                      ? AppColors.verifiedLeaf
                      : AppColors.ctaTerracotta,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    auction.reservePriceMet
                        ? 'Đã đạt giá sàn bảo lưu của người bán.'
                        : (auction.reservePrice != null
                            ? 'Giá sàn: ${VndFormatter.format(auction.reservePrice!)} (Chưa đạt)'
                            : 'Phiên đấu giá có giá sàn bảo lưu ẩn.'),
                    style: AppTypography.bodySmall.copyWith(
                      color: auction.reservePriceMet
                          ? AppColors.verifiedLeaf
                          : AppColors.ctaTerracotta,
                      fontWeight: FontWeight.w600,
                    ),
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
            const Icon(
              Icons.history_rounded,
              size: 19,
              color: AppColors.pineDeep,
            ),
            const SizedBox(width: 6),
            Text(
              'Lịch Sử Trả Giá Trực Tiếp',
              style: AppTypography.headingSmall.copyWith(fontSize: 16),
            ),
            const Spacer(),
            Text(
              'Tự động làm mới mỗi 3s',
              style: AppTypography.caption.copyWith(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (auction.recentBids.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              border: Border.all(color: AppColors.borderWarm),
            ),
            child: Center(
              child: Text(
                'Chưa có lượt trả giá nào. Hãy là người đầu tiên đặt giá!',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: auction.recentBids.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final bid = auction.recentBids[index];
              final isTop = index == 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isTop
                      ? AppColors.verifiedLeafBg
                      : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isTop
                        ? AppColors.verifiedLeaf
                        : AppColors.borderWarm,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isTop
                          ? AppColors.pineDeep
                          : AppColors.creamBadgeBg,
                      child: Text(
                        bid.bidderName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isTop ? Colors.white : AppColors.creamBadgeText,
                          fontWeight: FontWeight.w800,
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
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (isTop) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.pineDeep,
                                    borderRadius:
                                        DesignTokens.borderRadiusFull,
                                  ),
                                  child: const Text(
                                    '👑 Dẫn đầu',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                              if (bid.isMine) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.priceCrimson,
                                    borderRadius:
                                        DesignTokens.borderRadiusFull,
                                  ),
                                  child: const Text(
                                    'Tôi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (bid.triggeredAntiSniping)
                            const Text(
                              '⚡ Kích hoạt Anti-Sniping',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.ctaTerracotta,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      VndFormatter.format(bid.bidAmount),
                      style: AppTypography.priceMedium.copyWith(
                        color: isTop
                            ? AppColors.priceCrimson
                            : AppColors.textCharcoal,
                        fontSize: 14.5,
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
    final isCurrentUserWinner =
        auction.myBidStatus?.toUpperCase() == 'WON' ||
        (auction.winnerId != null && auction.winnerId == vm.currentUserId);

    final canPayAuctionOrder =
        auction.isCompleted && isCurrentUserWinner && auction.orderId != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: const Border(top: BorderSide(color: AppColors.borderWarm)),
        boxShadow: DesignTokens.bottomNavElevation,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (auction.isCompleted) ...[
              if (canPayAuctionOrder) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.creamBadgeBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.creamBadgeBorder),
                  ),
                  child: const Text(
                    '🏆 BẠN ĐÃ THẮNG ĐẤU GIÁ!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.creamBadgeText,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push(AppRoutes.orderDetailPath(auction.orderId!));
                    },
                    icon: const Icon(Icons.payment_rounded),
                    label: const Text('THANH TOÁN ĐƠN HÀNG NGAY'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.priceCrimson,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ] else if (auction.canRelist) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final newA = await SellerRelistAuctionModal.show(
                        context,
                        auction.id,
                      );
                      if (context.mounted && newA != null) {
                        context.pushReplacement(
                          AppRoutes.auctionRoomPath(newA.id),
                        );
                      }
                    },
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Tái đăng phiên đấu giá (M-AC-06)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pineBanner,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSection,
                    borderRadius: DesignTokens.borderRadiusFull,
                    border: Border.all(color: AppColors.borderWarm),
                  ),
                  child: Center(
                    child: Text(
                      'Phiên đấu giá đã kết thúc (${auction.status})',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ] else if (auction.isOwner) ...[
              if (auction.canCloseEarly)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        SellerCloseEarlyModal.show(context, auction.id),
                    icon: const Icon(Icons.gavel_rounded),
                    label: const Text('Chốt phiên sớm (M-AC-05)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pineBanner,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      'Bạn là chủ phiên đấu giá này (BR-AC-02)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: auction.isLive
                      ? () => BidPlacementBottomSheet.show(context, auction.id)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaTerracotta,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gavel_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '🔨 ĐẶT GIÁ THẦU NGAY',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
