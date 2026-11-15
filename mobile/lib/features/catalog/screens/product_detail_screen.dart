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
import '../../../core/widgets/retro_product_card.dart';
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

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late PageController _imagePageController;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productDetailViewModelProvider.notifier).loadProductDetail(widget.productId);
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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: Text(
          state.data != null ? state.data!.productCode : 'Chi tiết sản phẩm',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (state.data != null) ...[
            IconButton(
              icon: Icon(
                state.data!.isFavorited ? Icons.favorite : Icons.favorite_border,
                color: state.data!.isFavorited ? AppColors.christmasBerryRed : AppColors.textCharcoal,
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
                    content: Text('Đã sao chép liên kết sản phẩm ${state.data!.title}'),
                    backgroundColor: AppColors.secondaryPineGreen,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              tooltip: 'Giỏ hàng',
              onPressed: () => context.push(AppRoutes.cart),
            ),
          ],
        ],
      ),
      body: state.when(
        initial: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
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
          // 1. Image Carousel & Zoom Trigger
          _buildImageCarousel(context, images, product, viewModel),

          Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Price Header & Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      VndFormatter.format(product.price),
                      style: const TextStyle(
                        fontFamily: AppTypography.fontHeading,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.christmasBerryRed,
                      ),
                    ),
                    Row(
                      children: [
                        ConditionBadge(condition: product.condition),
                        const SizedBox(width: DesignTokens.spaceSm),
                        VerificationBadge(
                          status: product.verificationLevel,
                          isCompact: true,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: DesignTokens.spaceSm),

                // 3. Title & Identification
                Text(
                  product.title,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontHeading,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textCharcoal,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: DesignTokens.spaceXs),

                // Category, Brand, Stock
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    if (product.category != null)
                      _buildMetaChip(Icons.category_outlined, product.category!.name),
                    if (product.brand != null && product.brand!.name.isNotEmpty)
                      _buildMetaChip(Icons.sell_outlined, product.brand!.name),
                    _buildMetaChip(
                      Icons.inventory_2_outlined,
                      product.availableQuantity > 0
                          ? 'Còn lại ${product.availableQuantity} sản phẩm'
                          : 'Đã hết hàng',
                      color: product.availableQuantity > 0 ? AppColors.secondaryPineGreen : AppColors.statusDanger,
                    ),
                  ],
                ),

                const SizedBox(height: DesignTokens.spaceLg),

                // 4. Defect & Vintage Condition Section (BR-PR-03)
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceMd),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    border: Border.all(color: AppColors.borderWarm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.search, color: AppColors.primaryTerracotta, size: 20),
                              SizedBox(width: DesignTokens.spaceXs),
                              Text(
                                'Kiểm định khuyết điểm đồ si',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textCharcoal,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              foregroundColor: AppColors.primaryTerracotta,
                            ),
                            onPressed: () => DefectVerificationModal.show(context, product),
                            child: const Text('Xem phiếu kiểm định →'),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spaceXs),
                      DefectAuthenticityBox(
                        defectInfo: product.defectInfo,
                        rejectionReason: product.rejectionReason,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: DesignTokens.spaceLg),

                // 5. Price Breakdown Card (DEC-04)
                PriceBreakdownCard(
                  itemSubtotal: product.price,
                  shippingFee: 25000,
                  customBuyerProtectionFee: product.buyerProtectionFee,
                  showSellerNetAmount: product.isOwner,
                ),

                const SizedBox(height: DesignTokens.spaceLg),

                // 6. Seller Micro-Card (BR-AC-02 & Navigation to M-US-03)
                if (product.seller != null) _buildSellerCard(context, product.seller!, product),

                const SizedBox(height: DesignTokens.spaceLg),

                // 7. Product Description
                const Text(
                  'Mô tả chi tiết',
                  style: TextStyle(
                    fontFamily: AppTypography.fontHeading,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textCharcoal,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                Text(
                  product.description.isNotEmpty
                      ? product.description
                      : 'Người bán chưa cung cấp thêm mô tả chi tiết.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textCharcoal,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: DesignTokens.spaceXl),

                // 8. Related Products
                if (product.relatedProducts.isNotEmpty) ...[
                  const Text(
                    'Đồ vintage tương tự',
                    style: TextStyle(
                      fontFamily: AppTypography.fontHeading,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textCharcoal,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  SizedBox(
                    height: 270,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: product.relatedProducts.length,
                      separatorBuilder: (context, index) => const SizedBox(width: DesignTokens.spaceMd),
                      itemBuilder: (context, idx) {
                        final relProd = product.relatedProducts[idx];
                        return SizedBox(
                          width: 170,
                          child: RetroProductCard(
                            id: relProd.id,
                            title: relProd.title,
                            price: relProd.price,
                            condition: relProd.condition,
                            primaryImageUrl: relProd.primaryImageUrl,
                            isLiked: relProd.isFavorited,
                            isOwner: relProd.isOwner,
                            sellerName: relProd.sellerDisplayName,
                            onTap: () => context.push(AppRoutes.productDetailPath(relProd.id)),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: DesignTokens.spaceXl),
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
    return SizedBox(
      height: 340,
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
                  child: Image.network(
                    img.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, size: 48, color: AppColors.textMuted),
                    ),
                  ),
                ),
              );
            },
          ),

          // Zoom prompt badge overlay
          Positioned(
            right: DesignTokens.spaceMd,
            bottom: DesignTokens.spaceMd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${viewModel.currentImageIndex + 1} / ${images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color ?? AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color ?? AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSellerCard(
    BuildContext context,
    ProductSellerInfo seller,
    ProductDetailModel product,
  ) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceWarm,
                backgroundImage: seller.avatarUrl != null ? NetworkImage(seller.avatarUrl!) : null,
                child: seller.avatarUrl == null
                    ? const Icon(Icons.storefront, color: AppColors.primaryTerracotta)
                    : null,
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (seller.shopSlug != null)
                      Text(
                        '@${seller.shopSlug}',
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.secondaryPineGreen, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          'Trust ${seller.trustScore.toStringAsFixed(0)}/100',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryPineGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.star, color: Color(0xFFC5A66B), size: 14),
                        const SizedBox(width: 2),
                        Text(
                          seller.averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTerracotta,
                    side: const BorderSide(color: AppColors.primaryTerracotta),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    context.push(AppRoutes.sellerStorefrontPath(seller.id));
                  },
                  child: const Text('Xem Tiệm'),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceWarm,
                    foregroundColor: AppColors.textCharcoal,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.borderWarm),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Mở cuộc trò chuyện với tiệm ${seller.displayName} về sản phẩm này.'),
                        backgroundColor: AppColors.secondaryPineGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Nhắn tin'),
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
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceLg,
        vertical: DesignTokens.spaceMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: product.isOwner
            // BR-AC-02: Self-transaction forbidden UI banner
            ? Container(
                padding: const EdgeInsets.all(DesignTokens.spaceSm),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  border: Border.all(color: const Color(0xFFF8B4B4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.statusDanger, size: 22),
                    const SizedBox(width: DesignTokens.spaceSm),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Đây là sản phẩm của bạn',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.statusDanger,
                            ),
                          ),
                          Text(
                            'Bạn không thể mua hàng của chính mình (BR-AC-02).',
                            style: TextStyle(fontSize: 11, color: AppColors.textCharcoal),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTerracotta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        context.push(AppRoutes.sellerListings);
                      },
                      child: const Text('Quản lý'),
                    ),
                  ],
                ),
              )
            // Buyer action buttons
            : Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryTerracotta,
                        side: const BorderSide(color: AppColors.primaryTerracotta, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: viewModel.isAddingToCart
                          ? null
                          : () => viewModel.addToCart(context),
                      icon: viewModel.isAddingToCart
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Thêm vào giỏ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceMd),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTerracotta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: product.availableQuantity <= 0
                          ? null
                          : () => _showBuyNowQuantitySheet(context, product, viewModel),
                      child: Text(
                        product.availableQuantity > 0 ? 'Mua ngay' : 'Hết hàng',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chọn số lượng mua ngay',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Row(
                    children: [
                      IconButton(
                        onPressed: selectedQty > 1
                            ? () => setSheetState(() => selectedQty--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderWarm),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$selectedQty',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      IconButton(
                        onPressed: selectedQty < product.availableQuantity
                            ? () => setSheetState(() => selectedQty++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      const Spacer(),
                      Text(
                        'Còn lại: ${product.availableQuantity}',
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTerracotta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        context.push(
                          '${AppRoutes.checkout}?source=BUY_NOW&productId=${product.id}&quantity=$selectedQty',
                        );
                      },
                      child: Text('Tiến hành thanh toán (${VndFormatter.format(product.price * selectedQty)})'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
