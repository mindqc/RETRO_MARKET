import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/retro_auction_card.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../viewmodels/auction_hub_view_model.dart';

/// Screen M-AC-01: Scheduled Auction Hub (Root of Tab 3)
class ScheduledAuctionHubScreen extends ConsumerStatefulWidget {
  const ScheduledAuctionHubScreen({super.key});

  @override
  ConsumerState<ScheduledAuctionHubScreen> createState() =>
      _ScheduledAuctionHubScreenState();
}

class _ScheduledAuctionHubScreenState
    extends ConsumerState<ScheduledAuctionHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<_HubTabDefinition> _tabs = const [
    _HubTabDefinition(key: 'live', label: '🔴 Đang diễn ra'),
    _HubTabDefinition(key: 'ending_soon', label: '⚡ Sắp kết thúc'),
    _HubTabDefinition(key: 'upcoming', label: '⏰ Sắp mở'),
    _HubTabDefinition(key: 'completed', label: '📦 Đã kết thúc'),
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
      ref.read(auctionHubViewModelProvider.notifier).switchTab(tabKey);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(auctionHubViewModelProvider.notifier).loadMore();
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
    final vm = ref.watch(auctionHubViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: DesignTokens.spaceLg,
        title: const RetroBrandWordmark(titleText: 'izithrift • Đấu giá'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => context.push(AppRoutes.myAuctions),
              icon: const Icon(
                Icons.gavel_rounded,
                size: 16,
                color: AppColors.creamBadgeText,
              ),
              label: const Text(
                'Của tôi',
                style: TextStyle(
                  fontFamily: AppTypography.fontBody,
                  color: AppColors.creamBadgeText,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.creamBadgeBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                side: const BorderSide(color: AppColors.creamBadgeBorder),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
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
      body: RetroAmbientSnowflakes(
        child: RefreshIndicator(
          color: AppColors.ctaTerracotta,
          onRefresh: () =>
              ref.read(auctionHubViewModelProvider.notifier).fetchInitial(),
          child: _buildBody(vm),
        ),
      ),
    );
  }

  Widget _buildBody(AuctionHubViewModel vm) {
    if (vm.isError && vm.items.isEmpty) {
      return RetroErrorRetryView(
        errorMessage: vm.errorMessage ?? 'Không thể tải danh sách đấu giá.',
        onRetry: () =>
            ref.read(auctionHubViewModelProvider.notifier).fetchInitial(),
      );
    }

    if (vm.items.isEmpty) {
      return const RetroEmptyStateView(
        title: 'Chưa có phiên đấu giá nào',
        message:
            'Hiện chưa có phiên đấu giá trong danh mục này. Hãy quay lại sau nhé!',
        icon: Icons.gavel_rounded,
      );
    }

    final firstEnding = vm.items.first.auctionEndsAt;

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Deep Pine Spotlight Banner at top of Auction Hub
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: RetroPineSpotlightContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.creamBadgeBg.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.gavel_rounded,
                      color: AppColors.starGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sàn Đấu Giá Vintage',
                          style: AppTypography.headingSmall.copyWith(
                            color: Colors.white,
                            fontSize: 15.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vm.items.length} phiên nổi bật • Chống sniping +2 phút',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RetroSegmentedCountdown(endsAt: firstEnding),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.64,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final card = vm.items[index];
                return Stack(
                  children: [
                    RetroAuctionCard(
                      id: card.id,
                      title: card.productTitle,
                      currentBid: card.currentHighestBid,
                      bidCount: card.bidCount,
                      endsAt: card.auctionEndsAt,
                      primaryImageUrl: card.primaryImageUrl,
                      status: card.status,
                      extendedCount: card.extendedCount,
                      isOwner: card.isOwner,
                      onTap: () =>
                          context.push(AppRoutes.auctionRoomPath(card.id)),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: card.isWatching
                            ? Colors.white.withValues(alpha: 0.94)
                            : AppColors.darkFrostOverlay,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            ref
                                .read(auctionHubViewModelProvider.notifier)
                                .toggleWatch(card.id);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              card.isWatching
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: card.isWatching
                                  ? AppColors.priceCrimson
                                  : Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              childCount: vm.items.length,
            ),
          ),
        ),
        if (vm.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.ctaTerracotta,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HubTabDefinition {
  final String key;
  final String label;

  const _HubTabDefinition({required this.key, required this.label});
}
