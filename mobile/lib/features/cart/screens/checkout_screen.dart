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
import '../models/cart_item_model.dart';
import '../models/checkout_preview_model.dart';
import '../viewmodels/checkout_view_model.dart';

/// M-OR-01: Order Confirmation & Checkout.
///
/// UI refresh only.
/// Backend preview remains authoritative for pricing.
/// Order creation and payment navigation are unchanged.
class CheckoutScreen extends ConsumerStatefulWidget {
  final String source;
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
      ref
          .read(checkoutViewModelProvider)
          .loadCheckoutPreview(
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
        backgroundColor: AppColors.backgroundCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xác nhận đơn hàng',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              'Kiểm tra trước khi đặt mua',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      bottomNavigationBar: vm.state.maybeWhen(
        success: (preview) => _buildBottomActionBar(preview, vm),
        orElse: () => null,
      ),
      body: SafeArea(
        child: vm.state.when(
          initial: () => _buildLoading(),
          loading: () => _buildLoading(),
          error: (msg, err) => RetroErrorRetryView(
            errorMessage: msg,
            onRetry: () => ref
                .read(checkoutViewModelProvider)
                .loadCheckoutPreview(
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

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryTerracotta),
    );
  }

  // ---------------------------------------------------------------------------
  // Main checkout content
  // ---------------------------------------------------------------------------

  Widget _buildCheckoutBody(
    CheckoutPreviewModel preview,
    CheckoutViewModel vm,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceMd,
        DesignTokens.spaceSm,
        DesignTokens.spaceMd,
        140,
      ),
      children: [
        _buildCheckoutProgress(),

        const SizedBox(height: DesignTokens.spaceLg),

        _buildAddressCard(vm.selectedAddress),

        const SizedBox(height: DesignTokens.spaceLg),

        _buildSectionHeading(
          icon: Icons.shopping_bag_outlined,
          title: 'Sản phẩm đặt mua',
          subtitle: '${preview.orderGroups.length} cửa hàng',
        ),

        const SizedBox(height: DesignTokens.spaceSm),

        ...preview.orderGroups.map(_buildOrderStoreGroup),

        const SizedBox(height: DesignTokens.spaceLg),

        _buildOrderNoteCard(vm),

        const SizedBox(height: DesignTokens.spaceLg),

        PriceBreakdownCard(
          itemSubtotal: preview.totalItemSubtotal,
          shippingFee: preview.totalShippingFee,
          customBuyerProtectionFee: preview.totalBuyerProtectionFee,
          customGrandTotalAmount: preview.grandTotalAmount,
          showSellerNetAmount: false,
        ),

        const SizedBox(height: DesignTokens.spaceMd),

        _buildEscrowTrustCard(),

        const SizedBox(height: DesignTokens.spaceMd),

        _buildDemoPaymentNotice(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Checkout progress
  // ---------------------------------------------------------------------------

  Widget _buildCheckoutProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceSm,
        vertical: DesignTokens.spaceMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Row(
        children: [
          _buildProgressStep(number: '1', title: 'Giỏ hàng', completed: true),
          _buildProgressConnector(completed: true),
          _buildProgressStep(number: '2', title: 'Xác nhận', active: true),
          _buildProgressConnector(),
          _buildProgressStep(number: '3', title: 'Thanh toán'),
        ],
      ),
    );
  }

  Widget _buildProgressStep({
    required String number,
    required String title,
    bool active = false,
    bool completed = false,
  }) {
    final color = active || completed
        ? AppColors.primaryTerracotta
        : AppColors.textMuted;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: completed
                  ? AppColors.secondaryPineGreen
                  : active
                  ? AppColors.primaryTerracotta
                  : AppColors.surfaceWarm,
              shape: BoxShape.circle,
              border: active
                  ? Border.all(
                      color: AppColors.primaryTerracotta.withValues(alpha: 0.2),
                      width: 4,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: completed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
                : Text(
                    number,
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressConnector({bool completed = false}) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: completed ? AppColors.secondaryPineGreen : AppColors.borderWarm,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section heading
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeading({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE9DE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryTerracotta, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (subtitle != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shipping address
  // ---------------------------------------------------------------------------

  Widget _buildAddressCard(UserAddressModel? address) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceMd,
              vertical: 13,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E8),
              border: Border(bottom: BorderSide(color: AppColors.borderWarm)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primaryTerracotta,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Địa chỉ nhận hàng',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
                TextButton(
                  key: const Key('btn_change_shipping_address'),
                  onPressed: _openAddressSelection,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryTerracotta,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    'Thay đổi',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            child: address != null
                ? _buildAddressInformation(address)
                : _buildMissingAddress(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInformation(UserAddressModel address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFECE5D9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.textCharcoal,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 7,
                runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    address.recipientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  if (address.isDefault) _buildDefaultBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                address.recipientPhone,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                address.fullAddress,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textCharcoal,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F1E6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Mặc định',
        style: TextStyle(
          color: AppColors.secondaryPineGreen,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMissingAddress() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.statusDanger,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Chưa có địa chỉ nhận hàng. '
              'Vui lòng thêm địa chỉ để tiếp tục.',
              style: TextStyle(
                color: AppColors.statusDanger,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.addresses),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _openAddressSelection() {
    context.push(AppRoutes.addresses).then((_) {
      ref
          .read(checkoutViewModelProvider)
          .loadCheckoutPreview(
            source: widget.source,
            cartItemIds: widget.cartItemIds,
            productId: widget.productId,
            quantity: widget.quantity,
          );
    });
  }

  // ---------------------------------------------------------------------------
  // Seller / store group
  // ---------------------------------------------------------------------------

  Widget _buildOrderStoreGroup(CheckoutOrderGroupPreviewModel group) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoreHeader(group.shopName),
          ...group.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Column(
              children: [
                if (index > 0)
                  const Divider(height: 1, color: AppColors.borderSubtle),
                _buildCheckoutProduct(item),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStoreHeader(String shopName) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceMd,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWarm,
        border: Border(bottom: BorderSide(color: AppColors.borderWarm)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE4EBDD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.secondaryPineGreen,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              shopName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Checkout product row
  // ---------------------------------------------------------------------------

  Widget _buildCheckoutProduct(CartItemModel item) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 86,
              height: 96,
              color: AppColors.surfaceWarm,
              child:
                  item.primaryImageUrl != null &&
                      item.primaryImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.primaryImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const Center(
                        child: Icon(
                          Icons.checkroom_outlined,
                          color: Color(0xFF84664C),
                          size: 32,
                        ),
                      ),
                      errorWidget: (_, _, _) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textMuted,
                      ),
                    )
                  : const Icon(
                      Icons.checkroom_outlined,
                      color: Color(0xFF84664C),
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: SizedBox(
              height: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 5,
                    children: [
                      ConditionBadge(
                        condition: item.condition,
                        isCompact: true,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'x${item.quantity}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    VndFormatter.format(item.itemSubtotal),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primaryTerracotta,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Order note
  // ---------------------------------------------------------------------------

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
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9DE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primaryTerracotta,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Lời nhắn cho cửa hàng',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              Text(
                'Tùy chọn',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              hintText: 'VD: Gói hàng cẩn thận giúp mình nhé...',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.backgroundCream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                borderSide: const BorderSide(color: AppColors.borderWarm),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                borderSide: const BorderSide(
                  color: AppColors.primaryTerracotta,
                  width: 1.4,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (value) {
              vm.orderNote = value.trim();
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Escrow & demo notices
  // ---------------------------------------------------------------------------

  Widget _buildEscrowTrustCard() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2E8),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: const Color(0xFFB9D9BE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD5E8D7),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.secondaryPineGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: DesignTokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thanh toán an toàn với Escrow',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryPineGreen,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Tiền được giữ trung gian và chỉ giải ngân '
                  'cho người bán khi bạn xác nhận đã nhận hàng.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondaryPineGreen,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoPaymentNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEBD6A9)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF986A25)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Thanh toán QR trong ứng dụng là mô phỏng '
              'phục vụ demo. Không thực hiện giao dịch ngân hàng thật.',
              style: TextStyle(
                color: Color(0xFF805C25),
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sticky order action
  // ---------------------------------------------------------------------------

  Widget _buildBottomActionBar(
    CheckoutPreviewModel preview,
    CheckoutViewModel vm,
  ) {
    final bool hasValidCheckout =
        preview.orderGroups.isNotEmpty &&
        preview.itemsCount > 0 &&
        preview.orderGroups.any((group) => group.items.isNotEmpty) &&
        preview.grandTotalAmount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceMd,
        12,
        DesignTokens.spaceMd,
        10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: const Border(top: BorderSide(color: AppColors.borderWarm)),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng thanh toán',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    VndFormatter.format(preview.grandTotalAmount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.primaryTerracotta,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              key: const Key('btn_place_order'),
              onPressed: vm.isSubmittingOrder || !hasValidCheckout
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTerracotta,
                foregroundColor: AppColors.textLight,
                disabledBackgroundColor: AppColors.primaryTerracotta.withValues(
                  alpha: 0.55,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 14,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vm.isSubmittingOrder)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Icon(Icons.qr_code_2_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    vm.isSubmittingOrder ? 'Đang xử lý' : 'Đặt hàng',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
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
}
