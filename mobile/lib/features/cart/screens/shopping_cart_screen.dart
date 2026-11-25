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
import '../../../core/widgets/state_feedback_views.dart';
import '../models/cart_item_model.dart';
import '../models/cart_model.dart';
import '../models/cart_seller_group_model.dart';
import '../viewmodels/cart_view_model.dart';

/// M-CR-01: Grouped Shopping Cart Screen.
///
/// UI redesign only.
/// Preserves:
/// - CartViewModel selection synchronization
/// - Optimistic selection updates and rollback
/// - Seller-level / item-level selection
/// - Quantity updates and removal
/// - Stock availability restrictions
/// - Selection synchronization before checkout
/// - Existing widget keys used by tests
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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: DesignTokens.spaceMd,
        title: Row(
          children: [
            const Text('Giỏ hàng'),
            const SizedBox(width: 8),
            vm.state.maybeWhen(
              success: (cart) => cart.isEmpty
                  ? const SizedBox.shrink()
                  : _buildCartCountBadge(cart),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới giỏ hàng',
            icon: const Icon(Icons.refresh_rounded),
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
          color: AppColors.primaryTerracotta,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryTerracotta.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${cart.sellerGroups.fold<int>(0, (total, group) => total + group.items.length)}',
        style: const TextStyle(
          color: AppColors.primaryTerracotta,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryTerracotta),
    );
  }

  Widget _buildCartContent(CartModel cart, CartViewModel vm) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceMd,
        DesignTokens.spaceSm,
        DesignTokens.spaceMd,
        24,
      ),
      children: [
        _buildCartHero(cart, vm),
        if (vm.selectionErrorMessage != null) ...[
          const SizedBox(height: DesignTokens.spaceSm),
          _buildSelectionErrorBanner(vm),
        ],
        const SizedBox(height: DesignTokens.spaceMd),
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
        const Expanded(
          child: Text(
            'Món đồ đã chọn',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textCharcoal,
            ),
          ),
        ),
        Text(
          '${cart.sellerGroups.length} cửa hàng',
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryTerracotta,
            Color(0xFFB94729),
            Color(0xFFD98151),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTerracotta.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -18,
            child: Icon(
              Icons.shopping_bag_rounded,
              size: 105,
              color: Colors.white.withValues(alpha: 0.07),
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
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Túi đồ vintage của bạn',
                      style: AppTypography.headingSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFFFE3A5),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$selectedCount/$totalItems sản phẩm',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          syncing
                              ? 'Đang cập nhật lựa chọn...'
                              : selectedCount > 0
                              ? 'Sẵn sàng cho chuyến săn đồ tiếp theo'
                              : 'Chọn món đồ bạn muốn sở hữu',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 11,
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
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Text(
                        'PRE-LOVED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
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
        color: AppColors.statusDanger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.statusDanger.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sync_problem_rounded,
            color: AppColors.statusDanger,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              vm.selectionErrorMessage!,
              style: const TextStyle(
                color: AppColors.statusDanger,
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
              color: AppColors.statusDanger,
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
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: group.isAllSelected
              ? AppColors.primaryTerracotta.withValues(alpha: 0.30)
              : AppColors.borderWarm,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF49321F).withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
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
                  Divider(
                    height: 1,
                    indent: 12,
                    endIndent: 12,
                    color: AppColors.borderSubtle.withValues(alpha: 0.8),
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
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: const BoxDecoration(color: AppColors.surfaceWarm),
      child: Row(
        children: [
          Checkbox(
            key: Key('checkbox_seller_${group.sellerId}'),
            value: group.isAllSelected,
            activeColor: AppColors.primaryTerracotta,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (_) => vm.toggleSellerGroupSelection(group.sellerId),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE4EBDD),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 18,
              color: AppColors.secondaryPineGreen,
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
                    color: AppColors.textCharcoal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${group.items.length} món đồ',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
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
            activeColor: AppColors.primaryTerracotta,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 92,
            height: 112,
            color: AppColors.surfaceWarm,
            child:
                item.primaryImageUrl != null && item.primaryImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.primaryImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const Center(
                      child: Icon(
                        Icons.checkroom_outlined,
                        color: AppColors.textMuted,
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
                    size: 34,
                  ),
          ),
        ),
        if (!item.isAvailable)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
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
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primaryTerracotta,
            fontWeight: FontWeight.w900,
            fontSize: 15,
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
                  fontSize: 10,
                  color: item.isAvailable
                      ? AppColors.textMuted
                      : AppColors.statusDanger,
                  fontWeight: item.isAvailable
                      ? FontWeight.w400
                      : FontWeight.w600,
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
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            key: Key('btn_qty_minus_${item.id}'),
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (item.quantity == 1) {
                _confirmRemoveItem(item, vm);
              } else {
                vm.updateQuantity(item.id, item.quantity - 1);
              }
            },
            child: const SizedBox(
              width: 34,
              height: 34,
              child: Icon(Icons.remove_rounded, size: 15),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 5),
            color: Colors.white,
            child: Text(
              '${item.quantity}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
          InkWell(
            key: Key('btn_qty_plus_${item.id}'),
            borderRadius: BorderRadius.circular(8),
            onTap: canIncrement
                ? () => vm.updateQuantity(item.id, item.quantity + 1)
                : null,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(
                Icons.add_rounded,
                size: 15,
                color: canIncrement
                    ? AppColors.textCharcoal
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDDF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.eco_outlined,
            color: AppColors.secondaryPineGreen,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Mỗi món đồ secondhand là một câu chuyện '
              'được tiếp tục. Cảm ơn bạn đã lựa chọn '
              'mua sắm bền vững.',
              style: AppTypography.caption.copyWith(
                color: AppColors.secondaryPineGreen,
                height: 1.45,
                fontSize: 11,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xóa sản phẩm?'),
        content: Text('Bạn muốn bỏ "${item.title}" khỏi giỏ hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Giữ lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
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
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: const Border(top: BorderSide(color: AppColors.borderWarm)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Checkbox(
              key: const Key('checkbox_select_all'),
              value: cart.isAllSelected,
              activeColor: AppColors.primaryTerracotta,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (_) => vm.toggleSelectAll(),
            ),
            const Text(
              'Tất cả',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    syncing ? 'Đang đồng bộ' : 'Tạm tính',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      VndFormatter.format(subtotal),
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.primaryTerracotta,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
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
                  backgroundColor: AppColors.primaryTerracotta,
                  foregroundColor: AppColors.textLight,
                  disabledBackgroundColor: AppColors.primaryTerracotta
                      .withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: canCheckout ? 1 : 0,
                ),
                onPressed: canCheckout
                    ? () async {
                        final isSyncOk = await vm.ensureSelectionSynchronized();

                        if (!isSyncOk) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.statusDanger,
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

                        final selectedIds = cart.selectedCartItemIds;

                        if (mounted) {
                          context.push(
                            AppRoutes.checkout,
                            extra: {
                              'source': 'CART',
                              'cartItemIds': selectedIds,
                            },
                          );
                        }
                      }
                    : null,
                child: Text(
                  syncing ? 'Đang xử lý' : 'Mua ($selectedCount)',
                  style: const TextStyle(
                    fontSize: 12,
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
