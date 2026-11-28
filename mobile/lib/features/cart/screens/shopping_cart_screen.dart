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
import '../../../core/widgets/retro_design_primitives.dart';
import '../../../core/widgets/retro_product_image.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/cart_item_model.dart';
import '../models/cart_model.dart';
import '../models/cart_seller_group_model.dart';
import '../viewmodels/cart_view_model.dart';

/// M-CR-01: Grouped Shopping Cart Screen.
class ShoppingCartScreen extends ConsumerStatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  ConsumerState<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends ConsumerState<ShoppingCartScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartViewModelProvider).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(cartViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: IzithriftGlobalAppBar.subPage(
        activeDestination: IzithriftUpperNavDestination.cart,
        showNotificationsAction: false,
        showCartAction: true,
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Giỏ hàng',
              style: AppTypography.headingSmall.copyWith(
                fontSize: 17,
                color: AppColors.pineDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            vm.state.maybeWhen(
              success: (cart) => cart.isEmpty
                  ? const SizedBox.shrink()
                  : _buildCartCountBadge(cart),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        extraActions: [
          RetroHeaderIconButton(
            tooltip: 'Làm mới giỏ hàng',
            icon: Icons.refresh_rounded,
            onPressed: () {
              ref.read(cartViewModelProvider).loadCart();
            },
          ),
        ],
      ),
      bottomNavigationBar: vm.state.maybeWhen(
        success: (cart) => !cart.isEmpty ? _buildBottomBar(cart, vm) : null,
        orElse: () => null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ctaTerracotta,
          onRefresh: () =>
              ref.read(cartViewModelProvider).loadCart(silent: true),
          child: vm.state.when(
            initial: () => _buildLoading(),
            loading: () => _buildLoading(),
            error: (msg, err) => RetroErrorRetryView(
              errorMessage: msg,
              onRetry: () => ref.read(cartViewModelProvider).loadCart(),
            ),
            empty: (msg) => RetroEmptyStateView(
              title: 'Giỏ hàng đang trống',
              message:
                  msg ??
                  'Những món đồ vintage bạn yêu thích '
                      'sẽ xuất hiện ở đây.',
              icon: Icons.shopping_bag_outlined,
              actionLabel: 'Khám phá ngay',
              onAction: () => context.go(AppRoutes.home),
            ),
            success: (cart) => _buildCartContent(cart, vm),
          ),
        ),
      ),
    );
  }

  Widget _buildCartCountBadge(CartModel cart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.creamBadgeBg,
        borderRadius: DesignTokens.borderRadiusFull,
        border: Border.all(color: AppColors.creamBadgeBorder),
      ),
      child: Text(
        '${cart.sellerGroups.fold<int>(0, (total, group) => total + group.items.length)}',
        style: AppTypography.caption.copyWith(
          color: AppColors.creamBadgeText,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.ctaTerracotta),
    );
  }

  Widget _buildCartContent(CartModel cart, CartViewModel vm) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceMd,
        DesignTokens.spaceSm,
        DesignTokens.spaceMd,
        28,
      ),
      children: [
        _buildCartHero(cart, vm),
        if (vm.selectionErrorMessage != null) ...[
          const SizedBox(height: DesignTokens.spaceSm),
          _buildSelectionErrorBanner(vm),
        ],
        const SizedBox(height: DesignTokens.spaceLg),
        _buildSectionHeading(cart),
        const SizedBox(height: DesignTokens.spaceSm),
        ...cart.sellerGroups.map(
          (group) => Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
            child: _buildSellerGroupCard(group, vm),
          ),
        ),
        _buildShoppingTip(),
      ],
    );
  }

  Widget _buildSectionHeading(CartModel cart) {
    return Row(
      children: [
        const Icon(
          Icons.shopping_bag_outlined,
          size: 18,
          color: AppColors.pineDeep,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Món đồ đã chọn',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.pineDeep,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.creamBadgeSoft,
            borderRadius: DesignTokens.borderRadiusFull,
            border: Border.all(color: AppColors.creamBadgeBorder),
          ),
          child: Text(
            '${cart.sellerGroups.length} cửa hàng',
            style: AppTypography.caption.copyWith(
              color: AppColors.creamBadgeText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartHero(CartModel cart, CartViewModel vm) {
    final selectedCount = cart.computedSelectedCount;
    final totalItems = cart.sellerGroups.fold<int>(
      0,
      (total, group) => total + group.items.length,
    );
    final syncing = vm.isSyncingSelection;

    return RetroPineSpotlightContainer(
      padding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -14,
            child: Icon(
              Icons.shopping_bag_rounded,
              size: 98,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.creamBadgeBg.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.creamBadgeBg.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.creamBadgeBg,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Túi đồ vintage của bạn',
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.textLight,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.starGold,
                    size: 19,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$selectedCount/$totalItems sản phẩm',
                          style: AppTypography.headingLarge.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          syncing
                              ? 'Đang cập nhật lựa chọn...'
                              : selectedCount > 0
                                  ? 'Sẵn sàng cho chuyến săn đồ tiếp theo'
                                  : 'Chọn món đồ bạn muốn sở hữu',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.creamBadgeBg,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (syncing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.creamBadgeBg,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.creamBadgeBg,
                        borderRadius: DesignTokens.borderRadiusFull,
                      ),
                      child: const Text(
                        'PRE-LOVED',
                        style: TextStyle(
                          color: AppColors.creamBadgeText,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionErrorBanner(CartViewModel vm) {
    return Container(
      key: const Key('cart_selection_error_banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.priceCrimsonSoft,
        borderRadius: DesignTokens.borderRadiusMd,
        border: Border.all(color: AppColors.priceCrimsonBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sync_problem_rounded,
            color: AppColors.priceCrimson,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              vm.selectionErrorMessage!,
              style: const TextStyle(
                color: AppColors.priceCrimson,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.priceCrimson,
              size: 17,
            ),
            onPressed: () => vm.clearSelectionError(),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerGroupCard(CartSellerGroupModel group, CartViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(
          color: group.isAllSelected
              ? AppColors.pineDeep.withValues(alpha: 0.45)
              : AppColors.borderWarm,
        ),
        boxShadow: DesignTokens.cardElevation,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildSellerHeader(group, vm),
          ...group.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Column(
              children: [
                if (index > 0)
                  const Divider(
                    height: 1,
                    indent: 14,
                    endIndent: 14,
                    color: AppColors.borderSubtle,
                  ),
                _buildCartItemTile(item, vm),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSellerHeader(CartSellerGroupModel group, CartViewModel vm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 12, 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSection,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Checkbox(
            key: Key('checkbox_seller_${group.sellerId}'),
            value: group.isAllSelected,
            activeColor: AppColors.pineDeep,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            onChanged: (_) => vm.toggleSellerGroupSelection(group.sellerId),
          ),
          Expanded(
            child: InkWell(
              onTap: () =>
                  context.push(AppRoutes.sellerStorefrontPath(group.sellerId)),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
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
                        size: 17,
                        color: AppColors.pineDeep,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.shopName,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.pineDeep,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${group.items.length} món đồ',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(CartItemModel item, CartViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            key: Key('checkbox_item_${item.id}'),
            value: item.isSelected,
            activeColor: AppColors.pineDeep,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            onChanged: item.isAvailable
                ? (_) => vm.toggleItemSelection(item.id)
                : null,
          ),
          _buildProductImage(item),
          const SizedBox(width: 11),
          Expanded(child: _buildProductInformation(item, vm)),
        ],
      ),
    );
  }

  Widget _buildProductImage(CartItemModel item) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: DesignTokens.borderRadiusMd,
          child: Container(
              width: 90,
              height: 108,
              color: AppColors.surfaceWarm,
              child: RetroProductImage(
              imageUrl: item.primaryImageUrl,
              title: item.title,
              productId: item.productId,
              width: 90,
              height: 108,
              fit: BoxFit.cover,
              useStaticPlaceholder: true,
            ),
          ),
        ),
        if (!item.isAvailable)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkFrostOverlay,
                borderRadius: DesignTokens.borderRadiusMd,
              ),
              alignment: Alignment.center,
              child: const Text(
                'HẾT HÀNG',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductInformation(CartItemModel item, CartViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: item.isAvailable
                      ? AppColors.textCharcoal
                      : AppColors.textMuted,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              key: Key('btn_delete_item_${item.id}'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => _confirmRemoveItem(item, vm),
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ConditionBadge(condition: item.condition, isCompact: true),
        const SizedBox(height: 7),
        Text(
          VndFormatter.format(item.unitPrice),
          style: AppTypography.priceSmall.copyWith(
            color: AppColors.priceCrimson,
            fontSize: 15.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildQuantityStepper(item, vm),
            const Spacer(),
            Flexible(
              child: Text(
                item.isAvailable
                    ? 'Kho: ${item.availableQuantity}'
                    : 'Không khả dụng',
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontSize: 10.5,
                  color: item.isAvailable
                      ? AppColors.textMuted
                      : AppColors.priceCrimson,
                  fontWeight:
                      item.isAvailable ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityStepper(CartItemModel item, CartViewModel vm) {
    final canIncrement =
        item.isAvailable && item.quantity < item.availableQuantity;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.creamBadgeSoft,
        borderRadius: DesignTokens.borderRadiusFull,
        border: Border.all(color: AppColors.creamBadgeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            key: Key('btn_qty_minus_${item.id}'),
            borderRadius: DesignTokens.borderRadiusFull,
            onTap: () {
              if (item.quantity == 1) {
                _confirmRemoveItem(item, vm);
              } else {
                vm.updateQuantity(item.id, item.quantity - 1);
              }
            },
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                Icons.remove_rounded,
                size: 15,
                color: AppColors.pineDeep,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 30),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: AppColors.surfaceCard,
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textCharcoal,
              ),
            ),
          ),
          InkWell(
            key: Key('btn_qty_plus_${item.id}'),
            borderRadius: DesignTokens.borderRadiusFull,
            onTap: canIncrement
                ? () => vm.updateQuantity(item.id, item.quantity + 1)
                : null,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                Icons.add_rounded,
                size: 15,
                color: canIncrement
                    ? AppColors.pineDeep
                    : AppColors.textMuted.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingTip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.verifiedLeafBg,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(
          color: AppColors.verifiedLeaf.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.eco_outlined,
            color: AppColors.verifiedLeaf,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mỗi món đồ secondhand là một câu chuyện '
              'được tiếp tục. Cảm ơn bạn đã lựa chọn '
              'mua sắm bền vững.',
              style: AppTypography.caption.copyWith(
                color: AppColors.pineDeep,
                height: 1.45,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveItem(CartItemModel item, CartViewModel vm) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusBanner,
        ),
        title: Text(
          'Xóa sản phẩm?',
          style: AppTypography.headingSmall.copyWith(color: AppColors.pineDeep),
        ),
        content: Text('Bạn muốn bỏ "${item.title}" khỏi giỏ hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Giữ lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.priceCrimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              vm.removeItem(item.id);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CartModel cart, CartViewModel vm) {
    final selectedCount = cart.computedSelectedCount;
    final subtotal = cart.computedSelectedSubtotal;
    final syncing = vm.isSyncingSelection;
    final canCheckout = selectedCount > 0 && !syncing;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppColors.borderWarm)),
        boxShadow: DesignTokens.bottomNavElevation,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Checkbox(
              key: const Key('checkbox_select_all'),
              value: cart.isAllSelected,
              activeColor: AppColors.pineDeep,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (_) => vm.toggleSelectAll(),
            ),
            const Text(
              'Tất cả',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    syncing ? 'Đang đồng bộ' : 'Tạm tính',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      VndFormatter.format(subtotal),
                      style: AppTypography.priceLarge.copyWith(
                        color: AppColors.priceCrimson,
                        fontSize: 17.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                key: const Key('btn_proceed_checkout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaTerracotta,
                  foregroundColor: AppColors.textLight,
                  disabledBackgroundColor:
                      AppColors.ctaTerracotta.withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: const StadiumBorder(),
                  elevation: canCheckout ? 1 : 0,
                ),
                onPressed: canCheckout
                    ? () async {
                        final isSyncOk = await vm.ensureSelectionSynchronized();

                        if (!isSyncOk) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.priceCrimson,
                                content: Text(
                                  vm.selectionErrorMessage ??
                                      'Không thể đồng bộ giỏ hàng. '
                                          'Vui lòng thử lại.',
                                ),
                              ),
                            );
                          }
                          return;
                        }

                        final latestCart = vm.state.data ?? cart;
                        final selectedIds = latestCart.selectedCartItemIds;
                        if (selectedIds.isEmpty) return;

                        if (mounted) {
                          context.push(
                            AppRoutes.checkout,
                            extra: {
                              'source': 'CART',
                              'cartItemIds': selectedIds,
                            },
                          ).then((_) {
                            if (mounted) {
                              ref
                                  .read(cartViewModelProvider)
                                  .loadCart(silent: true);
                            }
                          });
                        }
                      }
                    : null,
                child: Text(
                  syncing ? 'Đang xử lý' : 'Mua ($selectedCount)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
