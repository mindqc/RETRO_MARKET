import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/izithrift_global_app_bar.dart';
import '../../../core/widgets/retro_auction_card.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../auth/widgets/auth_login_bottom_sheet.dart';
import '../models/auction_card_model.dart';
import '../viewmodels/auction_hub_view_model.dart';

/// Screen M-AC-01: Scheduled Auction Hub (Auctions Tab)
/// Displays rich Ongoing, Ending Soon, Upcoming, Completed, and grouped All sections,
/// plus a flagship interactive live auction spotlight card.
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
    _HubTabDefinition(key: 'all', label: '✨ Tất cả'),
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

  void _openAuctionRoom(BuildContext context, int auctionId) {
    final route = AppRoutes.auctionRoomPath(auctionId);
    final allowed = requireAuthOrPrompt(
      context,
      ref,
      featureTitle: 'Đăng nhập để vào phòng đấu giá',
      description:
          'Theo dõi trực tiếp, đặt giá nhanh hoặc đăng ký giữ chỗ cho các phiên đấu giá vintage.',
      intendedTarget: PendingNavigationTarget(route: route),
      icon: Icons.gavel_rounded,
    );
    if (allowed) {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(auctionHubViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: const IzithriftGlobalAppBar(),
      body: RetroAmbientSnowflakes(
        child: Column(
          children: [
            // Section Title + Subtitle + Quick Auction Actions + State Tabs
            Container(
              color: AppColors.surfaceCard,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đấu giá',
                              style: AppTypography.headingMedium.copyWith(
                                fontSize: 20,
                                color: AppColors.textCharcoal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Săn món đồ độc đáo với mức giá của bạn.',
                              style: AppTypography.caption.copyWith(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          final allowed = requireAuthOrPrompt(
                            context,
                            ref,
                            featureTitle: 'Đăng nhập để tạo phiên đấu giá',
                            description:
                                'Đăng món đồ vintage hiếm lên sàn đấu giá và tự chọn giá khởi điểm.',
                            intendedTarget: const PendingNavigationTarget(
                              route: AppRoutes.sellerCreateAuction,
                            ),
                            icon: Icons.add_circle_outline_rounded,
                          );
                          if (allowed) {
                            context.push(AppRoutes.sellerCreateAuction);
                          }
                        },
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Tạo phiên',
                          style: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.ctaTerracotta,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          shape: const StadiumBorder(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton.icon(
                        onPressed: () {
                          final allowed = requireAuthOrPrompt(
                            context,
                            ref,
                            featureTitle: 'Đăng nhập để xem Đấu giá của tôi',
                            description:
                                'Theo dõi các phiên đang dẫn đầu, bị vượt giá và đơn hàng thắng thầu.',
                            intendedTarget: const PendingNavigationTarget(
                              route: AppRoutes.myAuctions,
                            ),
                            icon: Icons.gavel_rounded,
                          );
                          if (allowed) {
                            context.push(AppRoutes.myAuctions);
                          }
                        },
                        icon: const Icon(
                          Icons.gavel_rounded,
                          size: 14,
                          color: AppColors.pineDeep,
                        ),
                        label: const Text(
                          'Của tôi',
                          style: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            color: AppColors.pineDeep,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primaryForestGreenLight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.canvasParchment,
                      borderRadius: DesignTokens.borderRadiusFull,
                      border: Border.all(color: AppColors.borderWarm),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      padding: const EdgeInsets.all(3),
                      indicator: BoxDecoration(
                        color: AppColors.pineDeep,
                        borderRadius: DesignTokens.borderRadiusFull,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: const TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      tabs: _tabs
                          .map((t) => Tab(height: 34, text: t.label))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderWarm),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.ctaTerracotta,
                onRefresh: () => ref
                    .read(auctionHubViewModelProvider.notifier)
                    .fetchInitial(),
                child: _buildBody(vm),
              ),
            ),
          ],
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

    final spotlight = vm.items.firstWhere(
      (a) => a.id == 9001 || a.isLive,
      orElse: () => vm.items.first,
    );

    if (vm.currentTab == 'all') {
      return _buildGroupedAllView(vm, spotlight);
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildFlagshipSpotlightBanner(context, spotlight, vm.items.length),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          sliver: _buildAuctionGridSliver(vm.items),
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

  /// Renders the '✨ Tất cả' tab with visually separated Ending Soon, Ongoing,
  /// Upcoming, and Completed sections so all states are easy to explore.
  Widget _buildGroupedAllView(
    AuctionHubViewModel vm,
    AuctionCardModel spotlight,
  ) {
    final now = DateTime.now();
    final endingSoon = <AuctionCardModel>[];
    final ongoing = <AuctionCardModel>[];
    final upcoming = <AuctionCardModel>[];
    final completed = <AuctionCardModel>[];

    for (final item in vm.items) {
      if (item.isLive) {
        final minsLeft = item.auctionEndsAt.difference(now).inMinutes;
        if (minsLeft > 0 && minsLeft <= 15) {
          endingSoon.add(item);
        } else {
          ongoing.add(item);
        }
      } else if (item.isScheduled) {
        upcoming.add(item);
      } else {
        completed.add(item);
      }
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildFlagshipSpotlightBanner(context, spotlight, vm.items.length),
        ),
        if (endingSoon.isNotEmpty) ...[
          _buildGroupHeaderSliver(
            title: 'Sắp kết thúc',
            subtitle: 'Đặt giá ngay trước khi hết giờ — tự gia hạn +2p khi có đấu phút chót',
            count: endingSoon.length,
            accentColor: AppColors.priceCrimson,
            icon: Icons.bolt_rounded,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: _buildAuctionGridSliver(endingSoon),
          ),
        ],
        if (ongoing.isNotEmpty) ...[
          _buildGroupHeaderSliver(
            title: 'Đang diễn ra',
            subtitle: 'Các phiên đấu giá sôi động đang nhận lượt trả trực tiếp',
            count: ongoing.length,
            accentColor: AppColors.pineDeep,
            icon: Icons.gavel_rounded,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: _buildAuctionGridSliver(ongoing),
          ),
        ],
        if (upcoming.isNotEmpty) ...[
          _buildGroupHeaderSliver(
            title: 'Sắp mở phiên',
            subtitle: 'Đăng ký giữ chỗ trước để nhận nhắc nhở khi sàn mở cửa',
            count: upcoming.length,
            accentColor: const Color(0xFF9A6B16),
            icon: Icons.schedule_rounded,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: _buildAuctionGridSliver(upcoming),
          ),
        ],
        if (completed.isNotEmpty) ...[
          _buildGroupHeaderSliver(
            title: 'Đã kết thúc gần đây',
            subtitle: 'Tham khảo mức giá chốt thầu các món đồ vintage hiếm',
            count: completed.length,
            accentColor: AppColors.textMuted,
            icon: Icons.inventory_2_outlined,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: _buildAuctionGridSliver(completed),
          ),
        ],
      ],
    );
  }

  SliverToBoxAdapter _buildGroupHeaderSliver({
    required String title,
    required String subtitle,
    required int count,
    required Color accentColor,
    required IconData icon,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: accentColor),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTypography.headingSmall.copyWith(
                          fontSize: 16,
                          color: AppColors.textCharcoal,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: DesignTokens.borderRadiusFull,
                        ),
                        child: Text(
                          '$count phiên',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagshipSpotlightBanner(
    BuildContext context,
    AuctionCardModel spotlight,
    int totalCount,
  ) {
    final countdownTarget =
        spotlight.isScheduled && spotlight.auctionStartsAt != null
            ? spotlight.auctionStartsAt!
            : spotlight.auctionEndsAt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: GestureDetector(
        onTap: () => _openAuctionRoom(context, spotlight.id),
        child: RetroPineSpotlightContainer(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ctaTerracotta,
                      borderRadius: DesignTokens.borderRadiusFull,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'PHIÊN TÂM ĐIỂM',
                          style: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$totalCount phiên đang mở • Anti-Sniping +2p',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  RetroSegmentedCountdown(endsAt: countdownTarget),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spotlight.productTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headingSmall.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Giá hiện tại: ${VndFormatter.format(spotlight.currentHighestBid)} • ${spotlight.bidCount} lượt trả',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.starGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: DesignTokens.borderRadiusFull,
                    ),
                    child: const Text(
                      'Vào đấu giá →',
                      style: TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pineDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverGrid _buildAuctionGridSliver(List<AuctionCardModel> cards) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.56,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final card = cards[index];
          return Stack(
            children: [
              RetroAuctionCard(
                id: card.id,
                title: card.productTitle,
                currentBid: card.currentHighestBid,
                startingPrice: card.startingPrice,
                bidCount: card.bidCount,
                watchCount: card.watchCount,
                startsAt: card.auctionStartsAt,
                endsAt: card.auctionEndsAt,
                primaryImageUrl: card.primaryImageUrl,
                categoryName: card.categoryName,
                status: card.status,
                extendedCount: card.extendedCount,
                isOwner: card.isOwner,
                onTap: () => _openAuctionRoom(context, card.id),
              ),
              Positioned(
                top: 12,
                right: 11,
                child: Material(
                  color: card.isWatching
                      ? Colors.white.withValues(alpha: 0.94)
                      : AppColors.darkFrostOverlay,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final allowed = requireAuthOrPrompt(
                        context,
                        ref,
                        featureTitle: 'Đăng nhập để theo dõi phiên đấu giá',
                        description:
                            'Lưu phiên đấu giá và nhận nhắc nhở trước khi phiên bắt đầu hoặc sắp kết thúc.',
                        intendedTarget: const PendingNavigationTarget(
                          route: AppRoutes.auctions,
                          returnToCaller: true,
                        ),
                        icon: Icons.favorite_outline_rounded,
                      );
                      if (allowed) {
                        ref
                            .read(auctionHubViewModelProvider.notifier)
                            .toggleWatch(card.id);
                      }
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
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        childCount: cards.length,
      ),
    );
  }
}

class _HubTabDefinition {
  final String key;
  final String label;

  const _HubTabDefinition({required this.key, required this.label});
}
