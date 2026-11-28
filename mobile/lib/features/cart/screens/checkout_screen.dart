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
import '../viewmodels/cart_view_model.dart';
import '../viewmodels/checkout_view_model.dart';

/// M-OR-01: Order Confirmation & Checkout.
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
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xác nhận đơn hàng',
              style: AppTypography.headingSmall.copyWith(
                fontSize: 18,
                color: AppColors.pineDeep,
              ),
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
      child: CircularProgressIndicator(color: AppColors.ctaTerracotta),
    );
  }

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

  Widget _buildCheckoutProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceSm,
        vertical: DesignTokens.spaceMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
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
    final color = active
        ? AppColors.ctaTerracotta
        : completed
            ? AppColors.pineDeep
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
                  ? AppColors.pineDeep
                  : active
                      ? AppColors.ctaTerracotta
                      : AppColors.surfaceWarm,
              shape: BoxShape.circle,
              border: active
                  ? Border.all(
                      color: AppColors.ctaTerracotta.withValues(alpha: 0.22),
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
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
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
        color: completed ? AppColors.pineDeep : AppColors.borderWarm,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

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
            color: AppColors.creamBadgeSoft,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.creamBadgeBorder),
          ),
          child: Icon(icon, color: AppColors.pineDeep, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.pineDeep,
              fontSize: 16,
            ),
          ),
        ),
        if (subtitle != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.creamBadgeSoft,
              borderRadius: DesignTokens.borderRadiusFull,
              border: Border.all(color: AppColors.creamBadgeBorder),
            ),
            child: Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.creamBadgeText,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddressCard(UserAddressModel? address) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusLg,
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
              vertical: 12,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSection,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.ctaTerracotta,
                  size: 19,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Địa chỉ nhận hàng',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.pineDeep,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('btn_change_shipping_address'),
                  onPressed: _openAddressSelection,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ctaTerracotta,
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.creamBadgeSoft,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.creamBadgeBorder),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.pineDeep,
            size: 20,
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
                      fontSize: 14.5,
                      color: AppColors.textCharcoal,
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
              const SizedBox(height: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.creamBadgeBg,
        borderRadius: DesignTokens.borderRadiusFull,
        border: Border.all(color: AppColors.creamBadgeBorder),
      ),
      child: const Text(
        'Mặc định',
        style: TextStyle(
          color: AppColors.creamBadgeText,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMissingAddress() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.priceCrimsonSoft,
        borderRadius: DesignTokens.borderRadiusMd,
        border: Border.all(color: AppColors.priceCrimsonBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.priceCrimson,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Chưa có địa chỉ nhận hàng. '
              'Vui lòng thêm địa chỉ để tiếp tục.',
              style: TextStyle(
                color: AppColors.priceCrimson,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _openAddressSelection,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddressSelection() async {
    final selected = await context.push<UserAddressModel>(
      '${AppRoutes.addresses}?select=true',
    );
    if (!mounted) return;
    final vm = ref.read(checkoutViewModelProvider);
    if (selected != null) {
      vm.updateShippingAddress(selected);
    } else {
      await vm.loadCheckoutPreview(
        source: widget.source,
        cartItemIds: widget.cartItemIds,
        productId: widget.productId,
        quantity: widget.quantity,
        refreshAddressFromServer: true,
      );
    }
  }

  Widget _buildOrderStoreGroup(CheckoutOrderGroupPreviewModel group) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusLg,
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
        color: AppColors.surfaceSection,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [
                  AppColors.categoryCircleStart,
                  AppColors.categoryCircleEnd,
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.creamBadgeBorder),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.pineDeep,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              shopName,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: AppColors.pineDeep,
              ),
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

  Widget _buildCheckoutProduct(CartItemModel item) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: DesignTokens.borderRadiusMd,
            child: Container(
              width: 84,
              height: 94,
              color: AppColors.surfaceWarm,
              child: item.primaryImageUrl != null &&
                      item.primaryImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.primaryImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const Center(
                        child: Icon(
                          Icons.checkroom_outlined,
                          color: AppColors.primaryVintageBrown,
                          size: 30,
                        ),
                      ),
                      errorWidget: (_, _, _) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textMuted,
                      ),
                    )
                  : const Icon(
                      Icons.checkroom_outlined,
                      color: AppColors.primaryVintageBrown,
                      size: 30,
                    ),
            ),
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: SizedBox(
              height: 94,
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
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          borderRadius: DesignTokens.borderRadiusFull,
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
                    style: AppTypography.priceSmall.copyWith(
                      color: AppColors.priceCrimson,
                      fontSize: 15,
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

  Widget _buildOrderNoteCard(CheckoutViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusLg,
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
                  color: AppColors.creamBadgeSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.creamBadgeBorder),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.pineDeep,
                  size: 17,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Lời nhắn cho cửa hàng',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppColors.pineDeep,
                  ),
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
              fillColor: AppColors.canvasParchment,
              border: OutlineInputBorder(
                borderRadius: DesignTokens.borderRadiusMd,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: DesignTokens.borderRadiusMd,
                borderSide: const BorderSide(color: AppColors.borderWarm),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: DesignTokens.borderRadiusMd,
                borderSide: const BorderSide(
                  color: AppColors.pineDeep,
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

  Widget _buildEscrowTrustCard() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.verifiedLeafBg,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(
          color: AppColors.verifiedLeaf.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.surfaceCard,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.verifiedLeaf,
              size: 20,
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
                    color: AppColors.pineDeep,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tiền được giữ trung gian và chỉ giải ngân '
                  'cho người bán khi bạn xác nhận đã nhận hàng.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.pineBanner,
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
        color: AppColors.creamBadgeSoft,
        borderRadius: DesignTokens.borderRadiusMd,
        border: Border.all(color: AppColors.creamBadgeBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.creamBadgeText,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Thanh toán QR trong ứng dụng là mô phỏng '
              'phục vụ demo. Không thực hiện giao dịch ngân hàng thật.',
              style: TextStyle(
                color: AppColors.creamBadgeText,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppColors.borderWarm)),
        boxShadow: DesignTokens.bottomNavElevation,
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
                  const SizedBox(height: 3),
                  Text(
                    VndFormatter.format(preview.grandTotalAmount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.priceLarge.copyWith(
                      color: AppColors.priceCrimson,
                      fontSize: 19,
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

                        if (session != null &&
                            session.paymentId > 0 &&
                            mounted) {
                          if (widget.source.toUpperCase() == 'CART') {
                            try {
                              ref
                                  .read(cartViewModelProvider)
                                  .loadCart(silent: true);
                            } catch (_) {}
                          }
                          context.pushReplacement(
                            AppRoutes.paymentQrPath(session.paymentId),
                            extra: session,
                          );
                        } else if (mounted) {
                          final errText = vm.errorMessage ??
                              'Không thể khởi tạo phiên thanh toán QR. Vui lòng thử lại.';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.priceCrimson,
                              content: Text(errText),
                            ),
                          );
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ctaTerracotta,
                foregroundColor: AppColors.textLight,
                disabledBackgroundColor:
                    AppColors.ctaTerracotta.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                elevation: 0,
                shape: const StadiumBorder(),
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
                    const Icon(Icons.qr_code_2_rounded, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    vm.isSubmittingOrder ? 'Đang xử lý' : 'Đặt hàng',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
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
