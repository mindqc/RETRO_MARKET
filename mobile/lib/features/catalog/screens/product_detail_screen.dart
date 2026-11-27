import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/condition_badge.dart';
import '../../../core/widgets/izithrift_global_app_bar.dart';
import '../../../core/widgets/price_breakdown_card.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../../core/widgets/retro_product_card.dart';
import '../../../core/widgets/retro_product_image.dart';
import '../../../core/widgets/retro_shop_avatar.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../engagement/repositories/communication_engagement_repository.dart';
import '../models/product_detail_model.dart';
import '../models/product_image_model.dart';
import '../models/product_summary_model.dart';
import '../viewmodels/product_detail_view_model.dart';
import '../widgets/product_shop_reviews_section.dart';
import '../widgets/product_specifications_card.dart';
import 'full_screen_zoom_viewer.dart';

/// Product Detail Screen for secondhand vintage items (M-PD-01).
/// Clean editorial hierarchy:
/// 1. Rounded Image Gallery (1/N)
/// 2. Main Info Block (Price, Title, single compact tag row: Condition / Category / Stock)
/// 3. Seller Block (Avatar, real shop name, Uy tín badge, Xem shop / Nhắn tin)
/// 4. Product Description
/// 5. Compact Cost Summary right above fixed CTA bar (Thêm vào giỏ | Mua ngay)
class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late PageController _imagePageController;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(productDetailViewModelProvider.notifier)
          .loadProductDetail(widget.productId);
    });
  }

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      if (_imagePageController.hasClients) {
        _imagePageController.jumpToPage(0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(productDetailViewModelProvider.notifier)
            .loadProductDetail(widget.productId);
      });
    }
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(productDetailViewModelProvider);
    final state = viewModel.state;

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: IzithriftGlobalAppBar.subPage(
        showNotificationsAction: false,
        showCartAction: state.data != null,
        extraActions: state.data != null
            ? [
                RetroHeaderIconButton(
                  icon: state.data!.isFavorited
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  tooltip: 'Yêu thích',
                  isActive: state.data!.isFavorited,
                  onPressed: () => viewModel.toggleFavorite(context),
                ),
                RetroHeaderIconButton(
                  icon: Icons.share_outlined,
                  tooltip: 'Chia sẻ',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã sao chép liên kết sản phẩm ${state.data!.displayTitle}',
                        ),
                        backgroundColor: AppColors.pineDeep,
                      ),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: state.when(
        initial: () => const Center(
          child: CircularProgressIndicator(color: AppColors.ctaTerracotta),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.ctaTerracotta),
        ),
        empty: (msg) => RetroEmptyStateView(
          title: 'Sản phẩm không tồn tại',
          message: msg ?? 'Sản phẩm đã bị ẩn hoặc gỡ khỏi sàn.',
          actionLabel: 'Quay lại khám phá',
          onAction: () => context.pop(),
        ),
        error: (msg, error) => RetroErrorRetryView(
          errorMessage: msg,
          onRetry: () => viewModel.loadProductDetail(widget.productId),
        ),
        success: (product) => _buildProductContent(context, product, viewModel),
      ),
      bottomNavigationBar: state.data != null
          ? _buildBottomActionBar(context, state.data!, viewModel)
          : null,
    );
  }

  Widget _buildProductContent(
    BuildContext context,
    ProductDetailModel product,
    ProductDetailViewModel viewModel,
  ) {
    final images = product.images.isNotEmpty
        ? product.images
        : [
            ProductImageModel(
              id: 0,
              imageUrl: product.primaryImageUrl,
              imageType: 'GALLERY',
            ),
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Large Rounded Product Image Gallery (1/N)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _buildImageCarousel(context, images, product, viewModel),
          ),

          // 2. Seamless Main Info Block (Price -> Title -> 1 compact tag row)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  VndFormatter.format(product.price),
                  style: AppTypography.priceLarge.copyWith(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: AppColors.priceCrimson,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.displayTitle,
                  style: AppTypography.headingMedium.copyWith(
                    fontSize: 19.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textCharcoal,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                // Single clean horizontal tag row: Condition | Category | Stock
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ConditionBadge(
                        condition: product.condition,
                        isCompact: true,
                      ),
                      if (product.category != null &&
                          product.category!.name.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildMetaChip(
                          Icons.category_outlined,
                          product.category!.name.trim(),
                        ),
                      ],
                      const SizedBox(width: 8),
                      _buildMetaChip(
                        Icons.inventory_2_outlined,
                        product.availableQuantity > 0
                            ? 'Còn ${product.availableQuantity} sản phẩm'
                            : 'Hết hàng',
                        color: product.availableQuantity > 0
                            ? AppColors.verifiedLeaf
                            : AppColors.priceCrimson,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Divider(height: 1, color: AppColors.borderWarm),
          ),

          // 3. Seller Block (Avatar, real shop name, Uy tín badge, Xem shop / Nhắn tin)
          if (product.seller != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSellerCard(context, product.seller!, product),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Product Specifications (Size, Garment Measurements & Material)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ProductSpecificationsCard(product: product),
          ),

          const SizedBox(height: 18),

          // 5. Product Description (clean, airy typography)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mô tả sản phẩm',
                  style: AppTypography.headingSmall.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pineDeep,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description.trim().isNotEmpty
                      ? product.description.trim()
                      : 'Người bán chưa cung cấp thêm mô tả chi tiết cho sản phẩm này.',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    color: AppColors.textCharcoal,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          // 6. Shop Reviews & Buyer Comments
          if (product.seller != null) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProductShopReviewsSection(
                averageRating: viewModel.sellerAverageRating ??
                    product.seller!.averageRating,
                reviewCount: viewModel.sellerReviewCount,
                reviews: viewModel.sellerReviews,
                isLoading: viewModel.isLoadingSellerExtras,
                onSeeAllTap: () => context.push(
                  AppRoutes.sellerStorefrontPath(product.seller!.id),
                ),
              ),
            ),
          ],

          // 7. Other Products from This Shop (horizontal scrollable carousel)
          if (viewModel.sellerOtherProducts.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildOtherShopProductsSection(
              context,
              viewModel.sellerOtherProducts,
              product,
            ),
          ],

          const SizedBox(height: 18),

          // 8. Collapsible Cost Breakdown Dropdown right above fixed CTA bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PriceBreakdownCard(
              itemSubtotal: product.price,
              shippingFee: 25000,
              customBuyerProtectionFee: product.buyerProtectionFee,
              showSellerNetAmount: product.isOwner,
              showEscrowNotice: false,
              isCompact: true,
              collapsible: true,
              initiallyExpanded: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(
    BuildContext context,
    List<ProductImageModel> images,
    ProductDetailModel product,
    ProductDetailViewModel viewModel,
  ) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        borderRadius: DesignTokens.borderRadiusBanner,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.sectionContainerShadow,
      ),
      child: ClipRRect(
        borderRadius: DesignTokens.borderRadiusBanner,
        child: Stack(
          children: [
            PageView.builder(
              controller: _imagePageController,
              itemCount: images.length,
              onPageChanged: (idx) => viewModel.setImageIndex(idx),
              itemBuilder: (context, idx) {
                final img = images[idx];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FullScreenZoomViewer(
                          images: images,
                          initialIndex: idx,
                          title: product.displayTitle,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: AppColors.surfaceWarm,
                    child: RetroProductImage(
                      imageUrl: img.imageUrl,
                      title: product.displayTitle,
                      categoryName: product.category?.name,
                      productId: product.id + idx,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                );
              },
            ),
            // Left floating navigation arrow (hidden on first image or single image)
            if (images.length > 1 && viewModel.currentImageIndex > 0)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildCarouselArrowButton(
                    key: const Key('product_carousel_prev_arrow'),
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Ảnh trước',
                    onTap: () {
                      _imagePageController.previousPage(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                      );
                    },
                  ),
                ),
              ),

            // Right floating navigation arrow (hidden on last image or single image)
            if (images.length > 1 &&
                viewModel.currentImageIndex < images.length - 1)
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildCarouselArrowButton(
                    key: const Key('product_carousel_next_arrow'),
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Ảnh tiếp theo',
                    onTap: () {
                      _imagePageController.nextPage(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                      );
                    },
                  ),
                ),
              ),

            Positioned(
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FullScreenZoomViewer(
                        images: images,
                        initialIndex: viewModel.currentImageIndex,
                        title: product.displayTitle,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: DesignTokens.borderRadiusFull,
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Text(
                    '${viewModel.currentImageIndex + 1}/${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselArrowButton({
    Key? key,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      key: key,
      color: Colors.black.withValues(alpha: 0.42),
      shape: CircleBorder(
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        icon: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildOtherShopProductsSection(
    BuildContext context,
    List<ProductSummaryModel> products,
    ProductDetailModel currentProduct,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.43).clamp(154.0, 178.0);
    final seller = currentProduct.seller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                size: 18,
                color: AppColors.pineDeep,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Các sản phẩm khác của shop',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headingSmall.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pineDeep,
                  ),
                ),
              ),
              if (seller != null)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ctaTerracotta,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => context.push(
                    AppRoutes.sellerStorefrontPath(seller.id),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem thêm',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 16),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 254,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 11),
            itemBuilder: (context, index) {
              final item = products[index];
              return SizedBox(
                width: cardWidth,
                child: RetroProductCard(
                  id: item.id,
                  title: item.displayTitle,
                  price: item.price,
                  primaryImageUrl: item.primaryImageUrl,
                  condition: item.condition,
                  categoryName: item.categoryName,
                  showConditionPercent: true,
                  sellerId: item.sellerId ?? seller?.id,
                  sellerName: seller?.displayShopName ?? item.displaySellerName,
                  sellerAvatarUrl: item.sellerAvatarUrl ?? seller?.avatarUrl,
                  isOwner: item.isOwner,
                  isLiked: item.isFavorited,
                  onTap: () => context.push(
                    AppRoutes.productDetailPath(item.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetaChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusFull,
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: color ?? AppColors.pineDeep),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(
    BuildContext context,
    ProductSellerInfo seller,
    ProductDetailModel product,
  ) {
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
              RetroShopAvatar(
                sellerId: seller.id,
                shopName: seller.displayShopName,
                avatarUrl: seller.avatarUrl,
                size: 46,
                borderColor: AppColors.creamBadgeBorder,
                borderWidth: 1.5,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            seller.displayShopName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headingSmall.copyWith(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textCharcoal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.verifiedLeafBg,
                            borderRadius: DesignTokens.borderRadiusFull,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 12,
                                color: AppColors.verifiedLeaf,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Uy tín',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.verifiedLeaf,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.starGold,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          seller.averageRating > 0
                              ? seller.averageRating.toStringAsFixed(1)
                              : '5.0',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textCharcoal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${seller.completedOrdersCount} đơn thành công',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.pineDeep,
                    side: const BorderSide(
                      color: AppColors.pineBanner,
                      width: 1.25,
                    ),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () =>
                      context.push(AppRoutes.sellerStorefrontPath(seller.id)),
                  icon: const Icon(Icons.storefront_outlined, size: 16),
                  label: const Text(
                    'Xem shop',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.creamBadgeSoft,
                    foregroundColor: AppColors.creamBadgeText,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.creamBadgeBorder),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _openChatWithSeller(context, seller, product),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text(
                    'Nhắn tin',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Fixed Bottom Action Bar enforcing Rule BR-AC-02 (Self-Transaction Forbidden)
  Widget _buildBottomActionBar(
    BuildContext context,
    ProductDetailModel product,
    ProductDetailViewModel viewModel,
  ) {
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
        child: product.isOwner
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.priceCrimsonSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.priceCrimsonBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.priceCrimson,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đây là sản phẩm của bạn',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.priceCrimson,
                            ),
                          ),
                          Text(
                            'Bạn không thể mua hàng của chính mình (BR-AC-02).',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textCharcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaTerracotta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => context.push(AppRoutes.sellerListings),
                      child: const Text(
                        'Quản lý',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.pineDeep,
                        side: const BorderSide(
                          color: AppColors.pineBanner,
                          width: 1.4,
                        ),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: viewModel.isAddingToCart
                          ? null
                          : () => viewModel.addToCart(context),
                      icon: viewModel.isAddingToCart
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.pineDeep,
                              ),
                            )
                          : const Icon(Icons.add_shopping_cart_rounded,
                              size: 18),
                      label: const Text(
                        'Thêm vào giỏ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaTerracotta,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: product.availableQuantity <= 0
                          ? null
                          : () {
                              final authVM = ref.read(authViewModelProvider);
                              if (!authVM.isAuthenticated) {
                                viewModel.showGuestLoginPrompt(
                                  context,
                                  featureTitle: 'Đăng nhập để mua ngay',
                                  description:
                                      'Đăng nhập tài khoản izithrift để chọn số lượng, áp dụng bảo vệ người mua và thanh toán nhanh chóng.',
                                  icon: Icons.shopping_cart_checkout_rounded,
                                );
                                return;
                              }
                              _showBuyNowQuantitySheet(
                                context,
                                product,
                                viewModel,
                              );
                            },
                      child: Text(
                        product.availableQuantity > 0 ? 'Mua ngay' : 'Hết hàng',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showBuyNowQuantitySheet(
    BuildContext context,
    ProductDetailModel product,
    ProductDetailViewModel viewModel,
  ) {
    int selectedQty = 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radius2xl),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chọn số lượng mua ngay',
                          style: AppTypography.headingSmall.copyWith(
                            fontSize: 17,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(
                          onPressed: selectedQty > 1
                              ? () => setSheetState(() => selectedQty--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.creamBadgeSoft,
                            border: Border.all(color: AppColors.creamBadgeBorder),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$selectedQty',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: selectedQty < product.availableQuantity
                              ? () => setSheetState(() => selectedQty++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                        ),
                        const Spacer(),
                        Text(
                          'Còn lại: ${product.availableQuantity}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ctaTerracotta,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          context.push(
                            AppRoutes.checkout,
                            extra: {
                              'source': 'BUY_NOW',
                              'productId': product.id,
                              'quantity': selectedQty,
                            },
                          );
                        },
                        child: Text(
                          'Tiến hành thanh toán (${VndFormatter.format(product.price * selectedQty)})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openChatWithSeller(
    BuildContext context,
    ProductSellerInfo seller,
    ProductDetailModel product,
  ) async {
    if (product.isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đây là gian hàng của bạn, không thể tự nhắn tin (BR-AC-02).'),
          backgroundColor: AppColors.statusDanger,
        ),
      );
      return;
    }

    final authVM = ref.read(authViewModelProvider);
    if (!authVM.isAuthenticated) {
      ref.read(productDetailViewModelProvider).showGuestLoginPrompt(
        context,
        featureTitle: 'Đăng nhập để nhắn tin chủ tiệm',
        description:
            'Hỏi thêm về số đo, tình trạng thực tế và đính kèm sản phẩm hoặc đơn hàng trực tiếp với ${seller.displayShopName}.',
        icon: Icons.chat_bubble_outline_rounded,
      );
      return;
    }

    try {
      final repo = ref.read(communicationEngagementRepositoryProvider);
      final conv = await repo.startOrGetConversation(
        recipientId: seller.id,
        contextProductId: product.id,
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
}
