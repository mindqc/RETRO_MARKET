import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/retro_product_image.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/auction_card_model.dart';
import '../viewmodels/my_auctions_view_model.dart';

/// Screen M-AC-02: My Auctions (Participating, Watchlist / Reserved, Won)
class MyAuctionsScreen extends ConsumerStatefulWidget {
  const MyAuctionsScreen({super.key});

  @override
  ConsumerState<MyAuctionsScreen> createState() => _MyAuctionsScreenState();
}

class _MyAuctionsScreenState extends ConsumerState<MyAuctionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<_MyTabDef> _tabs = const [
    _MyTabDef(key: 'participating', label: 'Đang tham gia'),
    _MyTabDef(key: 'watchlist', label: 'Đang theo dõi'),
    _MyTabDef(key: 'won', label: '🏆 Đã thắng đấu giá'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final tabKey = _tabs[_tabController.index].key;
      ref.read(myAuctionsViewModelProvider.notifier).switchTab(tabKey);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(myAuctionsViewModelProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(myAuctionsViewModelProvider);

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
          'Đấu Giá Của Tôi',
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.pineDeep,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: DesignTokens.borderRadiusFull,
              border: Border.all(color: AppColors.borderWarm),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.all(3),
              indicator: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: DesignTokens.borderRadiusFull,
                boxShadow: DesignTokens.cardElevation,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.priceCrimson,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(
                fontFamily: AppTypography.fontBody,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
              tabs: _tabs.map((t) => Tab(height: 36, text: t.label)).toList(),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.ctaTerracotta,
        onRefresh: () =>
            ref.read(myAuctionsViewModelProvider.notifier).fetchInitial(),
        child: _buildBody(vm),
      ),
    );
  }

  Widget _buildBody(MyAuctionsViewModel vm) {
    if (vm.isLoading && vm.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.ctaTerracotta),
      );
    }

    if (vm.isError && vm.items.isEmpty) {
      return RetroErrorRetryView(
        errorMessage: vm.errorMessage ?? 'Không thể tải danh sách hoạt động.',
        onRetry: () =>
            ref.read(myAuctionsViewModelProvider.notifier).fetchInitial(),
      );
    }

    if (vm.items.isEmpty) {
      return const RetroEmptyStateView(
        title: 'Chưa có dữ liệu',
        message: 'Bạn chưa có phiên đấu giá nào trong mục này.',
        icon: Icons.gavel_rounded,
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      itemCount: vm.items.length + (vm.isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= vm.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.ctaTerracotta,
              ),
            ),
          );
        }
        return _buildAuctionCard(context, vm.items[index], vm.currentTab);
      },
    );
  }

  Widget _buildAuctionCard(
    BuildContext context,
    AuctionCardModel item,
    String currentTab,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: item.isOutbid ? AppColors.ctaTerracotta : AppColors.borderWarm,
          width: item.isOutbid ? 1.5 : 1,
        ),
        boxShadow: DesignTokens.cardElevation,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentTab == 'participating') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: item.isLeading
                  ? AppColors.verifiedLeafBg
                  : AppColors.priceCrimsonSoft,
              child: Row(
                children: [
                  Icon(
                    item.isLeading
                        ? Icons.military_tech_rounded
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color: item.isLeading
                        ? AppColors.verifiedLeaf
                        : AppColors.priceCrimson,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.isLeading
                        ? '👑 BẠN ĐANG DẪN ĐẦU'
                        : '⚠️ ĐÃ BỊ VƯỢT GIÁ',
                    style: AppTypography.bodySmall.copyWith(
                      color: item.isLeading
                          ? AppColors.verifiedLeaf
                          : AppColors.priceCrimson,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (item.myHighestBid != null)
                    Text(
                      'Giá của bạn: ${VndFormatter.format(item.myHighestBid!)}',
                      style: AppTypography.caption.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (currentTab == 'watchlist') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: item.isScheduled
                  ? AppColors.verifiedLeafBg
                  : AppColors.creamBadgeSoft,
              child: Row(
                children: [
                  Icon(
                    item.isScheduled
                        ? Icons.notifications_active_rounded
                        : Icons.gavel_rounded,
                    size: 16,
                    color: item.isScheduled
                        ? AppColors.verifiedLeaf
                        : AppColors.priceCrimson,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.isScheduled
                        ? '⏰ ĐÃ GIỮ CHỖ • SẮP DIỄN RA'
                        : (item.isLive
                              ? '🔴 ĐANG DIỄN RA'
                              : '✓ ĐÃ KẾT THÚC'),
                    style: AppTypography.bodySmall.copyWith(
                      color: item.isScheduled
                          ? AppColors.verifiedLeaf
                          : AppColors.priceCrimson,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${item.watchCount} người quan tâm',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ],
          if (currentTab == 'won') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              color: AppColors.pineDeep,
              child: const Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 18,
                    color: AppColors.starGold,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🏆 BẠN ĐÃ CHIẾN THẮNG PHIÊN ĐẤU GIÁ!',
                      style: TextStyle(
                        color: AppColors.creamBadgeBg,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          InkWell(
            onTap: () => context.push(AppRoutes.auctionRoomPath(item.id)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RetroProductImage(
                    imageUrl: item.primaryImageUrl,
                    title: item.productTitle,
                    categoryName: item.categoryName,
                    productId: item.productId,
                    width: 88,
                    height: 88,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productTitle,
                          style: AppTypography.headingSmall.copyWith(
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              item.isScheduled ? 'Khởi điểm: ' : 'Cao nhất: ',
                              style: AppTypography.caption,
                            ),
                            Text(
                              VndFormatter.format(
                                item.isScheduled
                                    ? item.startingPrice
                                    : item.currentHighestBid,
                              ),
                              style: AppTypography.priceMedium.copyWith(
                                color: AppColors.priceCrimson,
                                fontSize: 15.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.bidCount} lượt trả giá',
                              style: AppTypography.caption,
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
          if (currentTab == 'watchlist') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(myAuctionsViewModelProvider.notifier)
                            .toggleWatch(item.id);
                      },
                      icon: const Icon(
                        Icons.notifications_off_outlined,
                        size: 16,
                      ),
                      label: Text(
                        item.isScheduled ? 'Hủy giữ chỗ' : 'Bỏ theo dõi',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.borderWarm),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push(AppRoutes.auctionRoomPath(item.id)),
                      icon: const Icon(Icons.gavel_rounded, size: 16),
                      label: Text(
                        item.isLive ? 'Vào đấu giá' : 'Xem chi tiết',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pineBanner,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (currentTab == 'participating' && item.isOutbid) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push(AppRoutes.auctionRoomPath(item.id)),
                  icon: const Icon(Icons.gavel_rounded, size: 17),
                  label: const Text('Trả giá lại ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaTerracotta,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ),
          ],
          if (currentTab == 'won') ...[
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.creamBadgeSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.creamBadgeBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: AppColors.ctaTerracotta,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Thời hạn thanh toán (30 phút - BR-AU-07):',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: AppColors.creamBadgeText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vui lòng thanh toán sớm để không bị đánh dấu bùng cọc (WINNER_DEFAULTED).',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textCharcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.myPurchases),
                      icon: const Icon(Icons.payment_rounded, size: 18),
                      label: const Text('Thanh toán đơn hàng ngay 💳'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pineBanner,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MyTabDef {
  final String key;
  final String label;

  const _MyTabDef({required this.key, required this.label});
}
