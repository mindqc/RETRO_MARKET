import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/auction_card_model.dart';
import '../viewmodels/my_auctions_view_model.dart';

/// Screen M-AC-02: My Auctions (Participating, Watchlist, Won)
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDarkCharcoal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Đấu Giá Của Tôi',
          style: AppTypography.headingMedium.copyWith(color: AppColors.primaryForestGreen),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.surfaceCard,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.accentBurgundy,
              unselectedLabelColor: AppColors.textCharcoalMuted,
              indicatorColor: AppColors.accentBurgundy,
              indicatorWeight: 3,
              labelStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryForestGreen,
        onRefresh: () => ref.read(myAuctionsViewModelProvider.notifier).fetchInitial(),
        child: _buildBody(vm),
      ),
    );
  }

  Widget _buildBody(MyAuctionsViewModel vm) {
    if (vm.isLoading && vm.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryForestGreen),
      );
    }

    if (vm.isError && vm.items.isEmpty) {
      return RetroErrorRetryView(
        errorMessage: vm.errorMessage ?? 'Không thể tải danh sách hoạt động.',
        onRetry: () => ref.read(myAuctionsViewModelProvider.notifier).fetchInitial(),
      );
    }

    if (vm.items.isEmpty) {
      return const RetroEmptyStateView(
        title: 'Chưa có dữ liệu',
        message: 'Bạn chưa có phiên đấu giá nào trong mục này.',
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      itemCount: vm.items.length + (vm.isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: DesignTokens.spacingMd),
      itemBuilder: (context, index) {
        if (index >= vm.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingMd),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryForestGreen,
              ),
            ),
          );
        }

        final item = vm.items[index];
        return _buildAuctionCard(context, item, vm.currentTab);
      },
    );
  }

  Widget _buildAuctionCard(BuildContext context, AuctionCardModel item, String currentTab) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: item.isOutbid ? Colors.deepOrangeAccent : AppColors.borderWarm,
          width: item.isOutbid ? 1.5 : DesignTokens.borderThin,
        ),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Status Badge
          if (currentTab == 'participating') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: item.isLeading
                    ? AppColors.primaryForestGreen.withAlpha(25)
                    : Colors.deepOrange.withAlpha(25),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusMd)),
              ),
              child: Row(
                children: [
                  Icon(
                    item.isLeading ? Icons.military_tech : Icons.warning_amber_rounded,
                    size: 16,
                    color: item.isLeading ? AppColors.primaryForestGreen : Colors.deepOrange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.isLeading ? '👑 BẠN ĐANG DẪN ĐẦU' : '⚠️ ĐÃ BỊ VƯỢT GIÁ',
                    style: AppTypography.bodySmall.copyWith(
                      color: item.isLeading ? AppColors.primaryForestGreen : Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (item.myHighestBid != null)
                    Text(
                      'Giá của bạn: ${VndFormatter.format(item.myHighestBid!)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textCharcoalMuted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
          ],

          if (currentTab == 'won') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentBurgundy.withAlpha(20),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusMd)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, size: 18, color: AppColors.accentBurgundy),
                  const SizedBox(width: 8),
                  Text(
                    '🏆 BẠN ĐÃ CHIẾN THẮNG PHIÊN ĐẤU GIÁ!',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.accentBurgundy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Card Content
          InkWell(
            onTap: () {
              context.push(AppRoutes.auctionRoomPath(item.id));
            },
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    child: Container(
                      width: 90,
                      height: 90,
                      color: AppColors.surfaceWarm,
                      child: item.primaryImageUrl != null && item.primaryImageUrl!.isNotEmpty
                          ? Image.network(
                              item.primaryImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.image_not_supported,
                                color: AppColors.textCharcoalMuted,
                              ),
                            )
                          : const Icon(Icons.gavel, color: AppColors.primaryVintageBrown, size: 36),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productTitle,
                          style: AppTypography.headingSmall.copyWith(fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Cao nhất: ',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textCharcoalMuted),
                            ),
                            Text(
                              VndFormatter.format(item.currentHighestBid),
                              style: AppTypography.priceMedium.copyWith(
                                color: AppColors.accentBurgundy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.history, size: 14, color: AppColors.textCharcoalMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${item.bidCount} lượt trả giá',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textCharcoalMuted),
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

          // Action CTA based on tab
          if (currentTab == 'participating' && item.isOutbid) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push(AppRoutes.auctionRoomPath(item.id));
                  },
                  icon: const Icon(Icons.gavel, size: 18),
                  label: const Text('Trả giá lại ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                  ),
                ),
              ),
            ),
          ],

          if (currentTab == 'won') ...[
            Container(
              margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 16, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        'Thời hạn thanh toán (30 phút - BR-AU-07):',
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vui lòng thanh toán sớm để không bị đánh dấu bùng cọc (WINNER_DEFAULTED).',
                    style: AppTypography.bodySmall.copyWith(fontSize: 12, color: Colors.brown.shade800),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Open purchase details or payment
                        context.push(AppRoutes.myPurchases);
                      },
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Thanh toán đơn hàng ngay 💳'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryForestGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                        ),
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
