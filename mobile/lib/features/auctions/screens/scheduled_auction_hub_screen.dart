import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/retro_auction_card.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../viewmodels/auction_hub_view_model.dart';

/// Screen M-AC-01: Scheduled Auction Hub (Root of Tab 3)
class ScheduledAuctionHubScreen extends ConsumerStatefulWidget {
  const ScheduledAuctionHubScreen({super.key});

  @override
  ConsumerState<ScheduledAuctionHubScreen> createState() => _ScheduledAuctionHubScreenState();
}

class _ScheduledAuctionHubScreenState extends ConsumerState<ScheduledAuctionHubScreen>
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        title: const Text(
          'izithrift • Đấu giá',
          style: TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textCharcoal,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: DesignTokens.spacingSm),
            child: TextButton.icon(
              onPressed: () {
                context.push(AppRoutes.myAuctions);
              },
              icon: const Icon(Icons.gavel, size: 18, color: AppColors.accentBurgundy),
              label: Text(
                'Của tôi',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.accentBurgundy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.accentBurgundy.withAlpha(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
              ),
            ),
          ),
        ],
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
        onRefresh: () => ref.read(auctionHubViewModelProvider.notifier).fetchInitial(),
        child: _buildBody(vm),
      ),
    );
  }

  Widget _buildBody(AuctionHubViewModel vm) {
    if (vm.isError && vm.items.isEmpty) {
      return RetroErrorRetryView(
        errorMessage: vm.errorMessage ?? 'Không thể tải danh sách đấu giá.',
        onRetry: () => ref.read(auctionHubViewModelProvider.notifier).fetchInitial(),
      );
    }

    if (vm.items.isEmpty) {
      return const RetroEmptyStateView(
        title: 'Chưa có phiên đấu giá nào',
        message: 'Hiện chưa có phiên đấu giá trong danh mục này. Hãy quay lại sau nhé!',
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: DesignTokens.spacingMd,
              crossAxisSpacing: DesignTokens.spacingMd,
              childAspectRatio: 0.65,
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
                      onTap: () {
                        context.push(AppRoutes.auctionRoomPath(card.id));
                      },
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.black.withAlpha(80),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            ref.read(auctionHubViewModelProvider.notifier).toggleWatch(card.id);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              card.isWatching ? Icons.favorite : Icons.favorite_border,
                              color: card.isWatching ? Colors.redAccent : Colors.white,
                              size: 18,
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
              padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingLg),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primaryForestGreen,
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
