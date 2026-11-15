import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/condition_badge.dart';
import '../../../core/widgets/price_breakdown_card.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../profile/models/user_address_model.dart';
import '../models/checkout_preview_model.dart';
import '../viewmodels/checkout_view_model.dart';

/// M-OR-01: Order Confirmation & Checkout Breakdown Screen
/// Enforces Decision DEC-04 (Mandatory Buyer Protection Fee = itemSubtotal * 6% + 7.000đ),
/// grouped orders per seller, and QR payment generation.
class CheckoutScreen extends ConsumerStatefulWidget {
  final String source; // 'CART' or 'BUY_NOW'
  final List<int>? cartItemIds;
  final int? productId;
  final int? quantity;

  const CheckoutScreen({
    super.key,
    this.source = 'CART',
    this.cartItemIds,
    this.productId,
    this.quantity,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkoutViewModelProvider).loadCheckoutPreview(
            source: widget.source,
            cartItemIds: widget.cartItemIds,
            productId: widget.productId,
            quantity: widget.quantity,
          );
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(checkoutViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Xác nhận đặt hàng'),
        elevation: 0,
      ),
      bottomNavigationBar: vm.state.maybeWhen(
        success: (preview) => _buildBottomActionBar(preview, vm),
        orElse: () => null,
      ),
      body: SafeArea(
        child: vm.state.when(
          initial: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
          error: (msg, err) => RetroErrorRetryView(
            errorMessage: msg,
            onRetry: () => ref.read(checkoutViewModelProvider).loadCheckoutPreview(
                  source: widget.source,
                  cartItemIds: widget.cartItemIds,
                  productId: widget.productId,
                  quantity: widget.quantity,
                ),
          ),
          empty: (msg) => RetroEmptyStateView(
            title: 'Không có sản phẩm',
            message: msg ?? 'Không tìm thấy sản phẩm hợp lệ để thanh toán.',
            actionLabel: 'Quay lại',
            onAction: () => context.pop(),
          ),
          success: (preview) => _buildCheckoutBody(preview, vm),
        ),
      ),
    );
  }

  Widget _buildCheckoutBody(CheckoutPreviewModel preview, CheckoutViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      children: [
        // 1. Shipping Address Section
        _buildAddressCard(vm.selectedAddress),

        const SizedBox(height: DesignTokens.spaceMd),

        // 2. Order Items grouped by Store
        ...preview.orderGroups.map((group) => _buildOrderStoreGroup(group)),

        const SizedBox(height: DesignTokens.spaceMd),

        // 3. Order Note Input
        _buildOrderNoteCard(vm),

        const SizedBox(height: DesignTokens.spaceMd),

        // 4. Transparent Price Breakdown (DEC-04)
        PriceBreakdownCard(
          itemSubtotal: preview.totalItemSubtotal,
          shippingFee: preview.totalShippingFee,
          customBuyerProtectionFee: preview.totalBuyerProtectionFee,
          showSellerNetAmount: false,
        ),

        const SizedBox(height: DesignTokens.spaceLg),

        // 5. Escrow Protection Trust Badge
        _buildEscrowTrustCard(),

        const SizedBox(height: 100), // Bottom bar padding
      ],
    );
  }

  Widget _buildAddressCard(UserAddressModel? address) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Address Icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(DesignTokens.radiusMd),
                topRight: Radius.circular(DesignTokens.radiusMd),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.primaryTerracotta, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Địa chỉ nhận hàng',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textCharcoal,
                  ),
                ),
                const Spacer(),
                TextButton(
                  key: const Key('btn_change_shipping_address'),
                  onPressed: () => _openAddressSelection(),
                  child: const Text('Thay đổi', style: TextStyle(color: AppColors.primaryTerracotta)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            child: address != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.recipientName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            address.recipientPhone,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF5EE),
                                borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                              ),
                              child: const Text(
                                'Mặc định',
                                style: TextStyle(color: AppColors.secondaryPineGreen, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        address.fullAddress,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textCharcoal),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.statusDanger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chưa có địa chỉ nhận hàng. Vui lòng thêm địa chỉ để tiếp tục.',
                          style: AppTypography.caption.copyWith(color: AppColors.statusDanger),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => context.push(AppRoutes.addresses),
                        child: const Text('Thêm'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _openAddressSelection() {
    context.push(AppRoutes.addresses).then((_) {
      // Re-trigger load preview when returning from address book
      ref.read(checkoutViewModelProvider).loadCheckoutPreview(
            source: widget.source,
            cartItemIds: widget.cartItemIds,
            productId: widget.productId,
            quantity: widget.quantity,
          );
    });
  }

  Widget _buildOrderStoreGroup(CheckoutOrderGroupPreviewModel group) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header
          Container(
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            decoration: const BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(DesignTokens.radiusMd),
                topRight: Radius.circular(DesignTokens.radiusMd),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront, color: AppColors.secondaryPineGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.shopName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // Items in this store
          ...group.items.map((item) => Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceMd),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                      child: Container(
                        width: 64,
                        height: 64,
                        color: AppColors.surfaceWarm,
                        child: item.primaryImageUrl != null && item.primaryImageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.primaryImageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
                              )
                            : const Icon(Icons.checkroom_outlined, color: Color(0xFF84664C), size: 26),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              ConditionBadge(condition: item.condition, isCompact: true),
                              const Spacer(),
                              Text('x${item.quantity}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            VndFormatter.format(item.itemSubtotal),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primaryTerracotta,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildOrderNoteCard(CheckoutViewModel vm) {
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
          const Text('Lời nhắn cho Tiệm (Tùy chọn):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'VD: Gói hàng cẩn thận giúp mình nhé...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) => vm.orderNote = v.trim(),
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowTrustCard() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5EE),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: const Color(0xFFBCE3C6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.secondaryPineGreen, size: 22),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cam kết Giữ Tiền Trung Gian Escrow 100%',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryPineGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Khoản tiền này sẽ được izithrift giữ an toàn trong quỹ Escrow và chỉ giải ngân cho Người bán khi bạn xác nhận đã nhận hàng đúng mô tả.',
                  style: AppTypography.caption.copyWith(color: AppColors.secondaryPineGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(CheckoutPreviewModel preview, CheckoutViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: const Border(top: BorderSide(color: AppColors.borderWarm)),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng thanh toán:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(
                  VndFormatter.format(preview.grandTotalAmount),
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.primaryTerracotta,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              key: const Key('btn_place_order'),
              icon: vm.isSubmittingOrder
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code, size: 18),
              label: const Text('Đặt hàng & Thanh toán QR', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTerracotta,
                foregroundColor: AppColors.textLight,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
              ),
              onPressed: vm.isSubmittingOrder
                  ? null
                  : () async {
                      final session = await vm.placeOrder();
                      if (session != null && mounted) {
                        context.push(
                          AppRoutes.paymentQrPath(session.paymentId),
                          extra: session,
                        );
                      } else if (vm.errorMessage != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.statusDanger,
                            content: Text(vm.errorMessage!),
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
