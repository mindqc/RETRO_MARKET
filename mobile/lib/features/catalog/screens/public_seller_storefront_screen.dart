import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/retro_auction_card.dart';
import '../../../core/widgets/retro_product_card.dart';
import '../../../core/widgets/seasonal_decor_overlay.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/review_item_model.dart';
import '../models/seller_public_profile_model.dart';
import '../viewmodels/seller_storefront_view_model.dart';

/// Public Seller Storefront Screen (M-US-03).
/// Displays vintage shop branding, Trust Score, followers, and 4 content tabs:
/// 1. Active Listings, 2. Auctions, 3. Sold Archive, 4. Verified Buyer Reviews.
/// Enforces BR-AC-02 (Self-follow forbidden) and DEC-01 (Guest login prompt).
class PublicSellerStorefrontScreen extends ConsumerStatefulWidget {
  final int sellerId;

  const PublicSellerStorefrontScreen({
    super.key,
    required this.sellerId,
  });

  @override
  ConsumerState<PublicSellerStorefrontScreen> createState() => _PublicSellerStorefrontScreenState();
}

class _PublicSellerStorefrontScreenState extends ConsumerState<PublicSellerStorefrontScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(sellerStorefrontViewModelProvider.notifier).setTabIndex(_tabController.index);
        if (_tabController.index == 3) {
          ref.read(sellerStorefrontViewModelProvider.notifier).loadReviews(widget.sellerId);
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
      backgroundColor: AppColors.backgroundCream,
      body: state.when(
        initial: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
        empty: (msg) => Scaffold(
          appBar: AppBar(title: const Text('Cửa hàng đồ si')),
          body: RetroEmptyStateView(
            title: 'Gian hàng không tồn tại',
            message: msg ?? 'Người bán này không tồn tại hoặc đã tạm khóa gian hàng.',
            actionLabel: 'Quay lại',
            onAction: () => context.pop(),
          ),
        ),
        error: (msg, error) => Scaffold(
          appBar: AppBar(title: const Text('Cửa hàng đồ si')),
          body: RetroErrorRetryView(
            errorMessage: msg,
            onRetry: () => viewModel.loadStorefront(widget.sellerId),
          ),
        ),
        success: (seller) => _buildStorefrontContent(context, seller, viewModel),
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
          // Collapsible Vintage Storefront Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.secondaryPineGreen,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover Photo
                  if (seller.coverImageUrl != null)
                    Image.network(
                      seller.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: AppColors.secondaryPineGreen),
                    )
                  else
                    Container(color: AppColors.secondaryPineGreen),

                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.75),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Optional Christmas decor overlay if enabled
                  if (seller.seasonalDecorEnabled)
                    const Positioned.fill(child: SeasonalDecorOverlay(child: SizedBox.shrink())),

                  // Seller Info Overlay
                  Positioned(
                    left: DesignTokens.spaceLg,
                    right: DesignTokens.spaceLg,
                    bottom: DesignTokens.spaceMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.surfaceWarm,
                              backgroundImage: seller.avatarUrl != null ? NetworkImage(seller.avatarUrl!) : null,
                              child: seller.avatarUrl == null
                                  ? const Icon(Icons.storefront, color: AppColors.primaryTerracotta, size: 32)
                                  : null,
                            ),
                            const SizedBox(width: DesignTokens.spaceMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    seller.displayName,
                                    style: const TextStyle(
                                      fontFamily: AppTypography.fontHeading,
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (seller.shopSlug != null)
                                    Text(
                                      '@${seller.shopSlug}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2D5A3C).withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFF5BA872)),
                                        ),
                                        child: Text(
                                          'Trust ${seller.trustScore.toStringAsFixed(0)}/100',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        seller.averageRating.toStringAsFixed(1),
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${seller.reviewCount} đánh giá)',
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (seller.bio != null && seller.bio!.isNotEmpty) ...[
                          const SizedBox(height: DesignTokens.spaceSm),
                          Text(
                            seller.bio!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: DesignTokens.spaceSm),
                        // Stats & Action Buttons
                        Row(
                          children: [
                            Text(
                              '${seller.followersCount} người theo dõi  •  ${seller.completedOrdersCount} đơn thành công',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            const Spacer(),
                            if (!seller.isOwner)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: seller.isFollowing ? AppColors.surfaceWarm : AppColors.primaryTerracotta,
                                  foregroundColor: seller.isFollowing ? AppColors.textCharcoal : Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                onPressed: () => viewModel.toggleFollow(context),
                                child: Text(seller.isFollowing ? 'Đang theo dõi' : '+ Theo dõi'),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Tiệm của bạn',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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

          // Pinned 4-Tab Navigation Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryTerracotta,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primaryTerracotta,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
          // Tab 1: Active Listings
          _buildActiveListingsTab(context, seller),

          // Tab 2: Auctions
          _buildAuctionsTab(context, seller),

          // Tab 3: Sold Listings
          _buildSoldListingsTab(context, seller),

          // Tab 4: Verified Buyer Reviews
          _buildReviewsTab(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildActiveListingsTab(BuildContext context, SellerPublicProfileModel seller) {
    if (seller.activeListings.isEmpty) {
      return const RetroEmptyStateView(
        title: 'Chưa có sản phẩm mở bán',
        message: 'Tiệm hiện tại chưa đăng sản phẩm nào mới.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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

  Widget _buildAuctionsTab(BuildContext context, SellerPublicProfileModel seller) {
    if (seller.auctions.isEmpty) {
      return const RetroEmptyStateView(
        title: 'Chưa có phiên đấu giá',
        message: 'Tiệm chưa khởi tạo phiên đấu giá vintage nào.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
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

  Widget _buildSoldListingsTab(BuildContext context, SellerPublicProfileModel seller) {
    if (seller.soldListings.isEmpty) {
      return const RetroEmptyStateView(
        title: 'Chưa có đồ vintage đã bán',
        message: 'Lịch sử các sản phẩm đã giao dịch thành công sẽ xuất hiện tại đây.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: seller.soldListings.length,
      itemBuilder: (context, idx) {
        final prod = seller.soldListings[idx];
        return Opacity(
          opacity: 0.75,
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

  Widget _buildReviewsTab(BuildContext context, SellerStorefrontViewModel viewModel) {
    if (viewModel.isLoadingReviews) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta));
    }

    if (viewModel.reviews.isEmpty) {
      return const RetroEmptyStateView(
        title: 'Chưa có đánh giá nào',
        message: 'Tiệm chưa nhận được đánh giá từ người mua đã hoàn thành đơn.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      itemCount: viewModel.reviews.length,
      separatorBuilder: (context, index) => const Divider(height: 24, color: AppColors.borderWarm),
      itemBuilder: (context, idx) {
        final review = viewModel.reviews[idx];
        return _buildReviewTile(review);
      },
    );
  }

  Widget _buildReviewTile(ReviewItemModel review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceWarm,
              backgroundImage: review.reviewerAvatarUrl != null ? NetworkImage(review.reviewerAvatarUrl!) : null,
              child: review.reviewerAvatarUrl == null
                  ? const Icon(Icons.person, color: AppColors.textMuted, size: 16)
                  : null,
            ),
            const SizedBox(width: DesignTokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.reviewerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFC5A66B),
                            size: 13,
                          ),
                        ),
                      ),
                      if (review.isVerifiedPurchase) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF5EE),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'Đã mua hàng',
                            style: TextStyle(
                              color: AppColors.secondaryPineGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        Text(
          review.comment,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textCharcoal, height: 1.4),
        ),
        if (review.productTitle != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    review.productTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surfaceCard,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
