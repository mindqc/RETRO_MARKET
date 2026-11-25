import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/condition_badge.dart';
import '../../../core/widgets/defect_authenticity_box.dart';
import '../../../core/widgets/price_breakdown_card.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../../core/widgets/retro_product_card.dart';
import '../../../core/widgets/retro_product_image.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../../core/widgets/verification_badge.dart';
import '../models/product_detail_model.dart';
import '../models/product_image_model.dart';
import '../viewmodels/product_detail_view_model.dart';
import 'defect_verification_modal.dart';
import 'full_screen_zoom_viewer.dart';

/// Product Detail Screen for secondhand vintage items (M-PD-01).
/// Adheres to Decision DEC-04 (Price Breakdown Card), BR-AC-02 (Self-Transaction Forbidden),
/// and DEC-01 (Guest Authentication Guard).
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
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          state.data != null ? state.data!.productCode : 'Chi tiết sản phẩm',
          style: AppTypography.headingSmall.copyWith(fontSize: 16),
        ),
        actions: [
          if (state.data != null) ...[
            IconButton(
              icon: Icon(
                state.data!.isFavorited
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: state.data!.isFavorited
                    ? AppColors.priceCrimson
                    : AppColors.textCharcoal,
              ),
              tooltip: 'Yêu thích',
              onPressed: () => viewModel.toggleFavorite(context),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Chia sẻ',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã sao chép liên kết sản phẩm ${state.data!.title}',
                    ),
                    backgroundColor: AppColors.pineDeep,
                  ),
                );
              },
            ),
            RetroHeaderIconButton(
              icon: Icons.shopping_bag_outlined,
              tooltip: 'Giỏ hàng',
              onPressed: () => context.push(AppRoutes.cart),
            ),
            const SizedBox(width: 4),
          ],
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Framed Rounded Product Image Carousel
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _buildImageCarousel(context, images, product, viewModel),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Price & Title Editorial Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              VndFormatter.format(product.price),
                              style: AppTypography.priceLarge.copyWith(
                                fontSize: 27,
                                color: AppColors.priceCrimson,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConditionBadge(condition: product.condition),
                              const SizedBox(width: 6),
                              VerificationBadge(
                                status: product.verificationLevel,
                                isCompact: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product.title,
                        style: AppTypography.headingMedium.copyWith(
                          fontSize: 20,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (product.category != null)
                            _buildMetaChip(
                              Icons.category_outlined,
                              product.category!.name,
                            ),
                          if (product.brand != null &&
                              product.brand!.name.isNotEmpty)
                            _buildMetaChip(
                              Icons.sell_outlined,
                              product.brand!.name,
                            ),
                          _buildMetaChip(
                            Icons.inventory_2_outlined,
                            product.availableQuantity > 0
                                ? 'Còn lại ${product.availableQuantity} sản phẩm'
                                : 'Đã hết hàng',
                            color: product.availableQuantity > 0
                                ? AppColors.verifiedLeaf
                                : AppColors.priceCrimson,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Defect & Vintage Condition Section (BR-PR-03)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSection,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    border: Border.all(color: AppColors.borderWarm),
                    boxShadow: DesignTokens.cardElevation,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.verified_outlined,
                                color: AppColors.ctaTerracotta,
                                size: 19,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Kiểm định khuyết điểm đồ si',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textCharcoal,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              visualDensity: VisualDensity.compact,
                              foregroundColor: AppColors.ctaTerracotta,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                            onPressed: () =>
                                DefectVerificationModal.show(context, product),
                            child: const Text('Xem phiếu kiểm định →'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      DefectAuthenticityBox(
                        defectInfo: product.defectInfo,
                        rejectionReason: product.rejectionReason,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Price Breakdown Card (DEC-04)
                PriceBreakdownCard(
                  itemSubtotal: product.price,
                  shippingFee: 25000,
                  customBuyerProtectionFee: product.buyerProtectionFee,
                  showSellerNetAmount: product.isOwner,
                ),

                const SizedBox(height: 16),

                // 5. Seller Micro-Card
                if (product.seller != null)
                  _buildSellerCard(context, product.seller!, product),

                const SizedBox(height: 18),

                // 6. Product Description
                const RetroSectionHeader(
                  title: 'Mô tả chi tiết',
                  icon: Icons.notes_rounded,
                  iconColor: AppColors.pineDeep,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    border: Border.all(color: AppColors.borderWarm),
                    boxShadow: DesignTokens.cardElevation,
                  ),
                  child: Text(
                    product.description.isNotEmpty
                        ? product.description
                        : 'Người bán chưa cung cấp thêm mô tả chi tiết.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textCharcoal,
                      height: 1.55,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // 7. Related Products
                if (product.relatedProducts.isNotEmpty) ...[
                  const RetroSectionHeader(
                    title: 'Đồ vintage tương tự',
                    icon: Icons.auto_awesome_rounded,
                    iconColor: AppColors.starGold,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: product.relatedProducts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, idx) {
                        final relProd = product.relatedProducts[idx];
                        return SizedBox(
                          width: 176,
                          child: RetroProductCard(
                            id: relProd.id,
                            title: relProd.title,
                            price: relProd.price,
                            condition: relProd.condition,
                            primaryImageUrl: relProd.primaryImageUrl,
                            isLiked: relProd.isFavorited,
                            isOwner: relProd.isOwner,
                            sellerName: relProd.sellerDisplayName,
                            onTap: () => context.push(
                              AppRoutes.productDetailPath(relProd.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
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
      height: 360,
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
                          title: product.title,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: AppColors.surfaceWarm,
                    child: RetroProductImage(
                      imageUrl: img.imageUrl,
                      title: product.title,
                      categoryName: product.category?.name,
                      productId: product.id + idx,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                );
              },
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
                        title: product.title,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: DesignTokens.borderRadiusFull,
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.zoom_in_rounded,
                          color: Colors.white, size: 15),
                      const SizedBox(width: 5),
                      Text(
                        '${viewModel.currentImageIndex + 1} / ${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.creamBadgeSoft,
        borderRadius: DesignTokens.borderRadiusFull,
        border: Border.all(color: AppColors.creamBadgeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: color ?? AppColors.creamBadgeText),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.creamBadgeText,
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
      padding: const EdgeInsets.all(16),
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
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.creamBadgeBorder,
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.categoryCircleEnd,
                  backgroundImage: seller.avatarUrl != null
                      ? NetworkImage(seller.avatarUrl!)
                      : null,
                  child: seller.avatarUrl == null
                      ? const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.pineDeep,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller.displayName,
                      style: AppTypography.headingSmall.copyWith(fontSize: 16),
                    ),
                    if (seller.shopSlug != null)
                      Text(
                        '@${seller.shopSlug}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
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
                          seller.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Trust ${seller.trustScore.toStringAsFixed(0)}/100',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pineDeep,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const RetroVerifiedShopChip(fontSize: 10.5),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.pineDeep,
                    side: const BorderSide(
                      color: AppColors.pineBanner,
                      width: 1.3,
                    ),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: () =>
                      context.push(AppRoutes.sellerStorefrontPath(seller.id)),
                  child: const Text(
                    'Xem Tiệm',
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
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Mở cuộc trò chuyện với tiệm ${seller.displayName} về sản phẩm này.',
                        ),
                        backgroundColor: AppColors.pineDeep,
                      ),
                    );
                  },
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
                          : () => _showBuyNowQuantitySheet(
                                context,
                                product,
                                viewModel,
                              ),
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
}
