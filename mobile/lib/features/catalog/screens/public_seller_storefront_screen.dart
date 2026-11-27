import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/izithrift_global_app_bar.dart';
import '../../../core/widgets/retro_auction_card.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../../core/widgets/retro_product_card.dart';
import '../../../core/widgets/seasonal_decor_overlay.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/review_item_model.dart';
import '../models/seller_public_profile_model.dart';
import '../viewmodels/seller_storefront_view_model.dart';

/// Public Seller Storefront Screen (M-US-03).
class PublicSellerStorefrontScreen extends ConsumerStatefulWidget {
  final int sellerId;

  const PublicSellerStorefrontScreen({
    super.key,
    required this.sellerId,
  });

  @override
  ConsumerState<PublicSellerStorefrontScreen> createState() =>
      _PublicSellerStorefrontScreenState();
}

class _PublicSellerStorefrontScreenState
    extends ConsumerState<PublicSellerStorefrontScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref
            .read(sellerStorefrontViewModelProvider.notifier)
            .setTabIndex(_tabController.index);
        if (_tabController.index == 3) {
          ref
              .read(sellerStorefrontViewModelProvider.notifier)
              .loadReviews(widget.sellerId);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(sellerStorefrontViewModelProvider.notifier);
      vm.loadStorefront(widget.sellerId);
      vm.loadReviews(widget.sellerId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(sellerStorefrontViewModelProvider);
    final state = viewModel.state;

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      body: state.when(
        initial: () => const Center(
          child: CircularProgressIndicator(color: AppColors.ctaTerracotta),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.ctaTerracotta),
        ),
        empty: (msg) => Scaffold(
          backgroundColor: AppColors.canvasParchment,
          appBar: const IzithriftGlobalAppBar.subPage(
            title: 'Cửa hàng đồ si',
            showBrandMark: true,
          ),
          body: RetroEmptyStateView(
            title: 'Gian hàng không tồn tại',
            message:
                msg ?? 'Người bán này không tồn tại hoặc đã tạm khóa gian hàng.',
            actionLabel: 'Quay lại',
            onAction: () => context.pop(),
          ),
        ),
        error: (msg, error) => Scaffold(
          backgroundColor: AppColors.canvasParchment,
          appBar: const IzithriftGlobalAppBar.subPage(
            title: 'Cửa hàng đồ si',
            showBrandMark: true,
          ),
          body: RetroErrorRetryView(
            errorMessage: msg,
            onRetry: () => viewModel.loadStorefront(widget.sellerId),
          ),
        ),
        success: (seller) =>
            _buildStorefrontContent(context, seller, viewModel),
      ),
    );
  }

  Widget _buildStorefrontContent(
    BuildContext context,
    SellerPublicProfileModel seller,
    SellerStorefrontViewModel viewModel,
  ) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 288,
            pinned: true,
            backgroundColor: AppColors.pineDeep,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (seller.coverImageUrl != null)
                    Image.network(
                      seller.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: AppColors.pineDeep),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.pineDeep, AppColors.pineBanner],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.pineDeep.withValues(alpha: 0.35),
                          AppColors.pineDeep.withValues(alpha: 0.88),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  if (seller.seasonalDecorEnabled)
                    const Positioned.fill(
                      child: SeasonalDecorOverlay(child: SizedBox.shrink()),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.creamBadgeBg,
                                  width: 2,
                                ),
                              ),
                              child: Builder(
                                builder: (_) {
                                  final avatarUrl = seller.avatarUrl?.trim();
                                  final hasValidAvatar = avatarUrl != null &&
                                      (avatarUrl.startsWith('http://') ||
                                          avatarUrl.startsWith('https://'));
                                  return CircleAvatar(
                                    radius: 32,
                                    backgroundColor: AppColors.categoryCircleEnd,
                                    backgroundImage: hasValidAvatar
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: !hasValidAvatar
                                        ? const Icon(
                                            Icons.storefront_rounded,
                                            color: AppColors.pineDeep,
                                            size: 30,
                                          )
                                        : null,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    seller.displayName,
                                    style: const TextStyle(
                                      fontFamily: AppTypography.fontHeading,
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (seller.shopSlug != null)
                                    Text(
                                      '@${seller.shopSlug}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.creamBadgeBg,
                                          borderRadius:
                                              DesignTokens.borderRadiusFull,
                                        ),
                                        child: Text(
                                          'Trust ${seller.trustScore.toStringAsFixed(0)}/100',
                                          style: const TextStyle(
                                            color: AppColors.creamBadgeText,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.star_rounded,
                                        color: AppColors.starGold,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        seller.averageRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${seller.reviewCount} đánh giá)',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (seller.bio != null && seller.bio!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            seller.bio!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${seller.followersCount} người theo dõi  •  ${seller.completedOrdersCount} đơn thành công',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                            if (!seller.isOwner)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: seller.isFollowing
                                      ? AppColors.creamBadgeBg
                                      : AppColors.ctaTerracotta,
                                  foregroundColor: seller.isFollowing
                                      ? AppColors.creamBadgeText
                                      : Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                onPressed: () => viewModel.toggleFollow(context),
                                child: Text(
                                  seller.isFollowing
                                      ? 'Đang theo dõi'
                                      : '+ Theo dõi',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: DesignTokens.borderRadiusFull,
                                ),
                                child: const Text(
                                  'Tiệm của bạn',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
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
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.priceCrimson,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.priceCrimson,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: 'Đang bán (${seller.activeListings.length})'),
                  Tab(text: 'Đấu giá (${seller.auctions.length})'),
                  Tab(text: 'Đã bán (${seller.soldListings.length})'),
                  Tab(text: 'Đánh giá (${seller.reviewCount})'),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveListingsTab(context, seller),
          _buildAuctionsTab(context, seller),
          _buildSoldListingsTab(context, seller),
          _buildReviewsTab(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildActiveListingsTab(
    BuildContext context,
    SellerPublicProfileModel seller,
  ) {
    if (seller.activeListings.isEmpty) {
      return const RetroEmptyStateView(
        title: 'Chưa có sản phẩm mở bán',
        message: 'Tiệm hiện tại chưa đăng sản phẩm nào mới.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.67,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: seller.activeListings.length,
      itemBuilder: (context, idx) {
        final prod = seller.activeListings[idx];
        return RetroProductCard(
          id: prod.id,
          title: prod.title,
          price: prod.price,
          condition: prod.condition,
          primaryImageUrl: prod.primaryImageUrl,
          isLiked: prod.isFavorited,
          isOwner: prod.isOwner,
          sellerName: prod.sellerDisplayName,
          onTap: () => context.push(AppRoutes.productDetailPath(prod.id)),
        );
      },
    );
  }

  Widget _buildAuctionsTab(
    BuildContext context,
    SellerPublicProfileModel seller,
  ) {
    if (seller.auctions.isEmpty) {
      return const RetroEmptyStateView(
        title: 'Chưa có phiên đấu giá',
        message: 'Tiệm chưa khởi tạo phiên đấu giá vintage nào.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: seller.auctions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final auc = seller.auctions[idx];
        return RetroAuctionCard(
          id: auc.id,
          title: auc.title,
          currentBid: auc.currentBid,
          bidCount: auc.bidCount,
          endsAt: auc.endsAt,
          primaryImageUrl: auc.primaryImageUrl,
          status: auc.status,
          onTap: () => context.push(AppRoutes.auctionRoomPath(auc.id)),
        );
      },
    );
  }

  Widget _buildSoldListingsTab(
    BuildContext context,
    SellerPublicProfileModel seller,
  ) {
    if (seller.soldListings.isEmpty) {
      return const RetroEmptyStateView(
        title: 'Chưa có đồ vintage đã bán',
        message:
            'Lịch sử các sản phẩm đã giao dịch thành công sẽ xuất hiện tại đây.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.60,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: seller.soldListings.length,
      itemBuilder: (context, idx) {
        final prod = seller.soldListings[idx];
        return Opacity(
          opacity: 0.72,
          child: RetroProductCard(
            id: prod.id,
            title: prod.title,
            price: prod.price,
            condition: prod.condition,
            primaryImageUrl: prod.primaryImageUrl,
            isLiked: prod.isFavorited,
            isOwner: prod.isOwner,
            sellerName: prod.sellerDisplayName,
            onTap: () => context.push(AppRoutes.productDetailPath(prod.id)),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab(
    BuildContext context,
    SellerStorefrontViewModel viewModel,
  ) {
    if (viewModel.isLoadingReviews) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.ctaTerracotta),
      );
    }

    if (viewModel.reviews.isEmpty) {
      return const RetroEmptyStateView(
        title: 'Chưa có đánh giá nào',
        message:
            'Tiệm chưa nhận được đánh giá từ người mua đã hoàn thành đơn.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.reviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, idx) => _buildReviewTile(viewModel.reviews[idx]),
    );
  }

  Widget _buildReviewTile(ReviewItemModel review) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Builder(
                builder: (_) {
                  final reviewerAvatar = review.reviewerAvatarUrl?.trim();
                  final hasValidAvatar = reviewerAvatar != null &&
                      (reviewerAvatar.startsWith('http://') ||
                          reviewerAvatar.startsWith('https://'));
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.categoryCircleEnd,
                    backgroundImage:
                        hasValidAvatar ? NetworkImage(reviewerAvatar) : null,
                    child: !hasValidAvatar
                        ? const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.pineDeep,
                            size: 18,
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: AppColors.starGold,
                              size: 14,
                            ),
                          ),
                        ),
                        if (review.isVerifiedPurchase) ...[
                          const SizedBox(width: 6),
                          const RetroVerifiedShopChip(
                            label: 'Đã mua hàng',
                            fontSize: 10,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (review.createdAt != null)
                Text(
                  '${review.createdAt!.day}/${review.createdAt!.month}/${review.createdAt!.year}',
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textCharcoal,
              height: 1.45,
            ),
          ),
          if (review.productTitle != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceSection,
                borderRadius: DesignTokens.borderRadiusFull,
                border: Border.all(color: AppColors.borderWarm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      review.productTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(fontSize: 11),
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.borderWarm)),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
