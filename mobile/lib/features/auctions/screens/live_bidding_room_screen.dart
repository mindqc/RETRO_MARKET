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
import '../../../core/widgets/retro_product_image.dart';
import '../../../core/widgets/retro_shop_avatar.dart';
import '../../../core/widgets/server_countdown_timer.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../../core/widgets/status_pill_badge.dart';
import '../../auth/widgets/auth_login_bottom_sheet.dart';
import '../../engagement/repositories/communication_engagement_repository.dart';
import '../models/auction_detail_model.dart';
import '../viewmodels/live_auction_view_model.dart';
import 'bid_placement_bottom_sheet.dart';
import 'seller_close_early_modal.dart';
import 'seller_relist_auction_modal.dart';

/// Screen M-AC-03: Live Bidding Room, Upcoming Seat Reservation & Anti-Sniping Hub
class LiveBiddingRoomScreen extends ConsumerStatefulWidget {
  final int auctionId;

  const LiveBiddingRoomScreen({super.key, required this.auctionId});

  @override
  ConsumerState<LiveBiddingRoomScreen> createState() =>
      _LiveBiddingRoomScreenState();
}

class _LiveBiddingRoomScreenState extends ConsumerState<LiveBiddingRoomScreen> {
  final PageController _photoController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _handleToggleReservation(
    BuildContext context,
    LiveAuctionViewModel vm,
    bool isScheduled,
  ) async {
    final allowed = requireAuthOrPrompt(
      context,
      ref,
      featureTitle: isScheduled
          ? 'Đăng nhập để giữ chỗ đấu giá'
          : 'Đăng nhập để theo dõi phiên đấu giá',
      description:
          'Nhận thông báo khi phiên sắp bắt đầu, sắp kết thúc hoặc có người vượt giá.',
      intendedTarget: PendingNavigationTarget(
        route: AppRoutes.auctionRoomPath(widget.auctionId),
        returnToCaller: true,
      ),
      icon: Icons.notifications_active_outlined,
    );
    if (!allowed) return;

    final nowWatching = await vm.toggleWatch();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowWatching
              ? (isScheduled
                    ? '✓ Đã đăng ký giữ chỗ tham gia đấu giá! Bạn sẽ nhận nhắc nhở trước giờ mở.'
                    : '✓ Đã thêm phiên đấu giá vào danh sách theo dõi.')
              : (isScheduled
                    ? 'Đã hủy giữ chỗ tham gia phiên đấu giá này.'
                    : 'Đã bỏ theo dõi phiên đấu giá này.'),
        ),
        backgroundColor: nowWatching ? AppColors.pineDeep : AppColors.textMuted,
      ),
    );
  }

  Future<void> _handleQuickBid(
    BuildContext context,
    LiveAuctionViewModel vm,
    double amount,
  ) async {
    final allowed = requireAuthOrPrompt(
      context,
      ref,
      featureTitle: 'Đăng nhập để đặt giá thầu',
      description:
          'Xác thực tài khoản izithrift để đặt giá nhanh và bảo vệ quyền thắng thầu của bạn.',
      intendedTarget: PendingNavigationTarget(
        route: AppRoutes.auctionRoomPath(widget.auctionId),
        returnToCaller: true,
      ),
      icon: Icons.gavel_rounded,
    );
    if (!allowed) return;

    final success = await vm.placeBid(amount);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Đã đặt giá nhanh thành công: ${VndFormatter.format(amount)}!',
          ),
          backgroundColor: AppColors.pineDeep,
        ),
      );
    } else if (vm.outbidConflict != null) {
      await BidPlacementBottomSheet.show(context, widget.auctionId);
    } else if (vm.bidErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.bidErrorMessage!),
          backgroundColor: AppColors.priceCrimson,
        ),
      );
    }
  }

  Future<void> _openChatWithSeller(
    BuildContext context,
    AuctionDetailModel auction,
  ) async {
    final allowed = requireAuthOrPrompt(
      context,
      ref,
      featureTitle: 'Đăng nhập để nhắn tin chủ phiên',
      description:
          'Trao đổi trực tiếp với chủ tiệm về tình trạng món đồ và lịch sử kiểm định.',
      intendedTarget: PendingNavigationTarget(
        route: AppRoutes.auctionRoomPath(widget.auctionId),
        returnToCaller: true,
      ),
      icon: Icons.chat_bubble_outline_rounded,
    );
    if (!allowed) return;

    try {
      final repo = ref.read(communicationEngagementRepositoryProvider);
      final conv = await repo.startOrGetConversation(
        recipientId: auction.sellerId,
        contextProductId: auction.productId,
      );
      if (context.mounted) {
        context.push(AppRoutes.chatRoomPath(conv.id));
      }
    } catch (_) {
      // Demo-compatible fallback when backend is offline
      if (context.mounted) {
        context.push(AppRoutes.chatRoomPath(101));
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$hh:$mm • $dd/$mo/${local.year}';
  }

  String _formatBidTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');
    final diff = DateTime.now().difference(local);
    if (diff.inSeconds < 60 && diff.inSeconds >= 0) {
      return '$hh:$mm:$ss • Vừa xong';
    }
    if (diff.inMinutes < 60 && diff.inMinutes > 0) {
      return '$hh:$mm:$ss • ${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24 && diff.inHours > 0) {
      return '$hh:$mm • ${diff.inHours} giờ trước';
    }
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$hh:$mm • $dd/$mo';
  }

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
            tooltip: auction.isScheduled
                ? (auction.isWatching ? 'Hủy giữ chỗ' : 'Giữ chỗ tham gia')
                : 'Theo dõi phiên',
            icon: Icon(
              auction.isWatching
                  ? (auction.isScheduled
                        ? Icons.notifications_active_rounded
                        : Icons.favorite_rounded)
                  : (auction.isScheduled
                        ? Icons.notifications_none_rounded
                        : Icons.favorite_border_rounded),
              color: auction.isWatching
                  ? AppColors.priceCrimson
                  : AppColors.textCharcoal,
            ),
            onPressed: () =>
                _handleToggleReservation(context, vm, auction.isScheduled),
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
                    _buildSellerAndReserveSection(context, auction),
                    const SizedBox(height: 14),
                    _buildAuctionRulesCard(auction),
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
          const Icon(
            Icons.bolt_rounded,
            color: AppColors.creamBadgeBg,
            size: 20,
          ),
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
    final now = ServerTimeService.instance.now();
    final targetTime = auction.isScheduled && auction.auctionStartsAt != null
        ? auction.auctionStartsAt!
        : auction.auctionEndsAt;
    final remaining = auction.auctionEndsAt.difference(now);
    final isEndingSoon =
        auction.isLive && remaining.inSeconds > 0 && remaining.inMinutes < 15;

    final String statusTag;
    final Color statusTagBg;
    if (auction.isScheduled) {
      statusTag = '⏰ SẮP DIỄN RA';
      statusTagBg = AppColors.ctaTerracotta;
    } else if (isEndingSoon) {
      statusTag = '⚡ SẮP KẾT THÚC';
      statusTagBg = AppColors.priceCrimson;
    } else if (auction.isLive) {
      statusTag = '🔴 ĐANG DIỄN RA';
      statusTagBg = AppColors.priceCrimson;
    } else {
      statusTag = '✓ ĐÃ KẾT THÚC';
      statusTagBg = Colors.white24;
    }

    return RetroPineSpotlightContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusTagBg,
                  borderRadius: DesignTokens.borderRadiusFull,
                ),
                child: Text(
                  statusTag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: DesignTokens.borderRadiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      size: 13,
                      color: AppColors.starGold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      auction.isScheduled
                          ? '${auction.watchCount} người giữ chỗ'
                          : '${auction.bidCount} lượt • ${auction.watchCount} theo dõi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          if (auction.isScheduled && auction.auctionStartsAt != null) ...[
            const SizedBox(height: 10),
            Text(
              'Khởi tranh lúc ${_formatDateTime(auction.auctionStartsAt!)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.creamBadgeBg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductSection(AuctionDetailModel auction) {
    final galleryImages = auction.productImages.isNotEmpty
        ? auction.productImages
        : (auction.primaryImageUrl != null &&
                  auction.primaryImageUrl!.isNotEmpty
              ? [auction.primaryImageUrl!]
              : <String>[]);

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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (galleryImages.length > 1)
                    PageView.builder(
                      controller: _photoController,
                      itemCount: galleryImages.length,
                      onPageChanged: (idx) {
                        setState(() => _currentPhotoIndex = idx);
                      },
                      itemBuilder: (context, idx) => RetroProductImage(
                        imageUrl: galleryImages[idx],
                        title: auction.productTitle,
                        categoryName: auction.categoryName,
                        productId: auction.productId + idx,
                      ),
                    )
                  else
                    RetroProductImage(
                      imageUrl: galleryImages.isNotEmpty
                          ? galleryImages.first
                          : auction.primaryImageUrl,
                      title: auction.productTitle,
                      categoryName: auction.categoryName,
                      productId: auction.productId,
                    ),
                  if (galleryImages.length > 1)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: DesignTokens.borderRadiusFull,
                        ),
                        child: Text(
                          '${_currentPhotoIndex + 1}/${galleryImages.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (galleryImages.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(galleryImages.length, (idx) {
                final active = idx == _currentPhotoIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppColors.pineDeep : AppColors.borderWarm,
                    borderRadius: DesignTokens.borderRadiusFull,
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (auction.condition != null)
                ConditionBadge(condition: auction.condition!),
              StatusPillBadge(status: auction.status),
              if (auction.categoryName != null &&
                  auction.categoryName!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSection,
                    borderRadius: DesignTokens.borderRadiusFull,
                    border: Border.all(color: AppColors.borderWarm),
                  ),
                  child: Text(
                    auction.categoryName!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textCharcoal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
          if (auction.isLive && (auction.isLeading || auction.isOutbid)) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: auction.isLeading
                    ? AppColors.verifiedLeafBg
                    : AppColors.priceCrimsonSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: auction.isLeading
                      ? AppColors.verifiedLeaf
                      : AppColors.priceCrimsonBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    auction.isLeading
                        ? Icons.workspace_premium_rounded
                        : Icons.trending_up_rounded,
                    size: 18,
                    color: auction.isLeading
                        ? AppColors.verifiedLeaf
                        : AppColors.priceCrimson,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      auction.isLeading
                          ? 'Bạn đang là người dẫn đầu phiên đấu giá này!'
                          : 'Bạn đã bị vượt giá! Đặt mức cao hơn để giành lại vị trí dẫn đầu.',
                      style: AppTypography.bodySmall.copyWith(
                        color: auction.isLeading
                            ? AppColors.verifiedLeaf
                            : AppColors.priceCrimson,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.creamBadgeSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.creamBadgeBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auction.isScheduled
                              ? 'Giá khởi điểm:'
                              : 'Giá cao nhất hiện tại:',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.creamBadgeText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          VndFormatter.format(
                            auction.isScheduled
                                ? auction.startingPrice
                                : auction.currentHighestBid,
                          ),
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
                          auction.isScheduled ? 'Đã giữ chỗ:' : 'Lượt trả giá:',
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
                            border: Border.all(
                              color: AppColors.creamBadgeBorder,
                            ),
                          ),
                          child: Text(
                            auction.isScheduled
                                ? '${auction.watchCount} người'
                                : '${auction.bidCount} lượt',
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
                const Divider(height: 20, color: AppColors.creamBadgeBorder),
                Row(
                  children: [
                    Expanded(
                      child: _buildPriceStatTile(
                        label: 'Giá khởi điểm',
                        value: VndFormatter.format(auction.startingPrice),
                      ),
                    ),
                    Expanded(
                      child: _buildPriceStatTile(
                        label: 'Bước giá',
                        value: '+${VndFormatter.format(auction.minBidIncrement)}',
                      ),
                    ),
                    Expanded(
                      child: _buildPriceStatTile(
                        label: auction.isScheduled ? 'Trạng thái' : 'Giá kế tiếp',
                        value: auction.isScheduled
                            ? (auction.isWatching ? 'Đã giữ chỗ' : 'Mở đăng ký')
                            : VndFormatter.format(auction.minimumNextBid),
                        highlight: !auction.isScheduled,
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

  Widget _buildPriceStatTile({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 10.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.pineDeep : AppColors.textCharcoal,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildSellerAndReserveSection(
    BuildContext context,
    AuctionDetailModel auction,
  ) {
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
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                context.push(AppRoutes.sellerStorefrontPath(auction.sellerId)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  RetroShopAvatar(
                    sellerId: auction.sellerId,
                    shopName: auction.sellerDisplayName ?? 'Chủ tiệm Retro',
                    avatarUrl: auction.sellerAvatarUrl,
                    size: 44,
                    borderColor: AppColors.creamBadgeBorder,
                    borderWidth: 1.5,
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
                          'Độ tin cậy: ${auction.sellerTrustScore.toStringAsFixed(0)}% uy tín • Xem tiệm',
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openChatWithSeller(context, auction),
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 14,
                            color: AppColors.pineDeep,
                          ),
                          label: const Text(
                            'Nhắn tin',
                            style: TextStyle(
                              fontFamily: AppTypography.fontBody,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pineDeep,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 32),
                            side: const BorderSide(color: AppColors.pineDeep),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
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

  Widget _buildAuctionRulesCard(AuctionDetailModel auction) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSection,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: AppColors.borderWarm),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 17,
                color: AppColors.pineDeep,
              ),
              const SizedBox(width: 6),
              Text(
                'Thể lệ & Bảo vệ đấu giá Retro Market',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.pineDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRuleRow(
            Icons.bolt_rounded,
            'Chống đặt giá phút chót (Anti-Sniping): tự động cộng thêm 2 phút nếu có giá mới trong 2 phút cuối.',
          ),
          const SizedBox(height: 6),
          _buildRuleRow(
            Icons.timer_outlined,
            'Người thắng cần thanh toán trong 30 phút sau khi kết phiên (BR-AU-07) để giữ quyền sở hữu sản phẩm.',
          ),
          const SizedBox(height: 6),
          _buildRuleRow(
            Icons.shield_outlined,
            'Tiền thanh toán được bảo vệ bởi ký quỹ Escrow cho đến khi bạn nhận hàng đúng mô tả.',
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 14, color: AppColors.ctaTerracotta),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption.copyWith(
              color: AppColors.textCharcoal,
              height: 1.4,
            ),
          ),
        ),
      ],
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
              auction.isLive
                  ? 'Tự động làm mới mỗi 3s'
                  : (auction.isScheduled ? 'Chờ mở phiên' : 'Đã chốt kết quả'),
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
                auction.isScheduled
                    ? 'Phiên đấu giá chưa bắt đầu. Hãy nhấn "Đăng ký tham gia đấu giá" để giữ chỗ trước!'
                    : 'Chưa có lượt trả giá nào. Hãy là người đầu tiên đặt giá!',
                textAlign: TextAlign.center,
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
                        bid.bidderName.isNotEmpty
                            ? bid.bidderName.substring(0, 1).toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 12,
                          color: isTop
                              ? Colors.white
                              : AppColors.creamBadgeText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                bid.bidderName,
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (isTop)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.pineDeep,
                                    borderRadius: DesignTokens.borderRadiusFull,
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
                              if (bid.isMine)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.priceCrimson,
                                    borderRadius: DesignTokens.borderRadiusFull,
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
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatBidTimestamp(bid.createdAt),
                            style: AppTypography.caption.copyWith(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
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
                    const SizedBox(width: 8),
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

    final quickBid1 = auction.minimumNextBid;
    final quickBid2 = auction.minimumNextBid + auction.minBidIncrement;
    final quickBid3 = auction.minimumNextBid + (auction.minBidIncrement * 2);

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
                if (auction.winnerDisplayName != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Người thắng cuộc: ${auction.winnerDisplayName} • ${VndFormatter.format(auction.currentHighestBid)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.pineDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
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
            ] else if (auction.isScheduled) ...[
              if (auction.isWatching) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.verifiedLeafBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.verifiedLeaf),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.verifiedLeaf,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Đã giữ chỗ tham gia • Sẽ nhắc trước giờ mở',
                          style: TextStyle(
                            color: AppColors.verifiedLeaf,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _handleToggleReservation(context, vm, true),
                        icon: const Icon(
                          Icons.notifications_off_outlined,
                          size: 17,
                        ),
                        label: const Text('Hủy giữ chỗ'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          side: const BorderSide(color: AppColors.borderWarm),
                          shape: const StadiumBorder(),
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.myAuctions),
                        icon: const Icon(Icons.gavel_rounded, size: 17),
                        label: const Text('Đấu giá của tôi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pineBanner,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _handleToggleReservation(context, vm, true),
                    icon: const Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Đăng ký tham gia đấu giá',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pineBanner,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ] else ...[
              if (auction.isLive) ...[
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildQuickBidPill(
                        context: context,
                        vm: vm,
                        label: 'Tối thiểu • ${VndFormatter.format(quickBid1)}',
                        amount: quickBid1,
                      ),
                      const SizedBox(width: 8),
                      _buildQuickBidPill(
                        context: context,
                        vm: vm,
                        label: '+1 bước • ${VndFormatter.format(quickBid2)}',
                        amount: quickBid2,
                      ),
                      const SizedBox(width: 8),
                      _buildQuickBidPill(
                        context: context,
                        vm: vm,
                        label: '+2 bước • ${VndFormatter.format(quickBid3)}',
                        amount: quickBid3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: auction.isLive && !vm.isSubmittingBid
                      ? () {
                          final allowed = requireAuthOrPrompt(
                            context,
                            ref,
                            featureTitle: 'Đăng nhập để đặt giá thầu',
                            description:
                                'Đăng nhập tài khoản izithrift để tham gia đấu giá trực tiếp và giữ vị trí dẫn đầu.',
                            intendedTarget: PendingNavigationTarget(
                              route: AppRoutes.auctionRoomPath(auction.id),
                              returnToCaller: true,
                            ),
                            icon: Icons.gavel_rounded,
                          );
                          if (allowed) {
                            BidPlacementBottomSheet.show(context, auction.id);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaTerracotta,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: vm.isSubmittingBid
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.gavel_rounded,
                              color: Colors.white,
                            ),
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

  Widget _buildQuickBidPill({
    required BuildContext context,
    required LiveAuctionViewModel vm,
    required String label,
    required double amount,
  }) {
    return ActionChip(
      onPressed: vm.isSubmittingBid
          ? null
          : () => _handleQuickBid(context, vm, amount),
      backgroundColor: AppColors.creamBadgeSoft,
      side: const BorderSide(color: AppColors.creamBadgeBorder),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      label: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.pineDeep,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
