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

/// M-CR-01: Grouped Shopping Cart Screen
/// Displays items grouped per seller store (BR-OR-01), with store-level and item-level selection,
/// quantity controls locked to available stock, and order navigation.
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
        title: const Text('Giỏ hàng vintage'),
        elevation: 0,
      ),
      bottomNavigationBar: vm.state.maybeWhen(
        success: (cart) => !cart.isEmpty ? _buildBottomBar(cart, vm) : null,
        orElse: () => null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryTerracotta,
          onRefresh: () => ref.read(cartViewModelProvider).loadCart(silent: true),
          child: vm.state.when(
            initial: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
            error: (msg, err) => RetroErrorRetryView(
              errorMessage: msg,
              onRetry: () => ref.read(cartViewModelProvider).loadCart(),
            ),
            empty: (msg) => RetroEmptyStateView(
              title: 'Giỏ hàng trống',
              message: msg ?? 'Bạn chưa có món đồ nào trong giỏ hàng.',
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

  Widget _buildCartContent(CartModel cart, CartViewModel vm) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: DesignTokens.spaceMd,
        right: DesignTokens.spaceMd,
        top: DesignTokens.spaceMd,
        bottom: 100, // Space for bottom summary bar
      ),
      itemCount: cart.sellerGroups.length,
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.spaceMd),
      itemBuilder: (context, index) {
        final group = cart.sellerGroups[index];
        return _buildSellerGroupCard(group, vm);
      },
    );
  }

  Widget _buildSellerGroupCard(CartSellerGroupModel group, CartViewModel vm) {
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
          // Store Header with Checkbox (BR-OR-01)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(DesignTokens.radiusMd),
                topRight: Radius.circular(DesignTokens.radiusMd),
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  key: Key('checkbox_seller_${group.sellerId}'),
                  value: group.isAllSelected,
                  activeColor: AppColors.primaryTerracotta,
                  onChanged: (_) => vm.toggleSellerGroupSelection(group.sellerId),
                ),
                const Icon(Icons.storefront_outlined, size: 20, color: AppColors.secondaryPineGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.shopName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textCharcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),

          // Items in Store
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderSubtle),
            itemBuilder: (context, idx) {
              final item = group.items[idx];
              return _buildCartItemTile(item, vm);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(CartItemModel item, CartViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Checkbox
          Checkbox(
            key: Key('checkbox_item_${item.id}'),
            value: item.isSelected,
            activeColor: AppColors.primaryTerracotta,
            onChanged: item.isAvailable ? (_) => vm.toggleItemSelection(item.id) : null,
          ),

          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            child: Container(
              width: 76,
              height: 76,
              color: AppColors.surfaceWarm,
              child: item.primaryImageUrl != null && item.primaryImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.primaryImageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textMuted,
                      ),
                    )
                  : const Icon(Icons.checkroom_outlined, color: Color(0xFF84664C), size: 30),
            ),
          ),

          const SizedBox(width: DesignTokens.spaceMd),

          // Title, Condition, Price & Quantity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textCharcoal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      key: Key('btn_delete_item_${item.id}'),
                      onTap: () => _confirmRemoveItem(item, vm),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                ConditionBadge(condition: item.condition, isCompact: true),
                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      VndFormatter.format(item.unitPrice),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primaryTerracotta,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Quantity Stepper [-] [N] [+]
                    _buildQuantityStepper(item, vm),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityStepper(CartItemModel item, CartViewModel vm) {
    final canIncrement = item.quantity < item.availableQuantity;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            key: Key('btn_qty_minus_${item.id}'),
            onTap: () {
              if (item.quantity == 1) {
                _confirmRemoveItem(item, vm);
              } else {
                vm.updateQuantity(item.id, item.quantity - 1);
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.remove, size: 14, color: AppColors.textCharcoal),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            color: Colors.white,
            child: Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          InkWell(
            key: Key('btn_qty_plus_${item.id}'),
            onTap: canIncrement ? () => vm.updateQuantity(item.id, item.quantity + 1) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(
                Icons.add,
                size: 14,
                color: canIncrement ? AppColors.textCharcoal : AppColors.textMuted.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveItem(CartItemModel item, CartViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc chắn muốn bỏ "${item.title}" khỏi giỏ hàng không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger),
            onPressed: () {
              Navigator.pop(ctx);
              vm.removeItem(item.id);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CartModel cart, CartViewModel vm) {
    final selectedCount = cart.computedSelectedCount;
    final subtotal = cart.computedSelectedSubtotal;

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
            Checkbox(
              key: const Key('checkbox_select_all'),
              value: cart.isAllSelected,
              activeColor: AppColors.primaryTerracotta,
              onChanged: (_) => vm.toggleSelectAll(),
            ),
            const Text('Tất cả', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Tổng thanh toán:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(
                  VndFormatter.format(subtotal),
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.primaryTerracotta,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              key: const Key('btn_proceed_checkout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTerracotta,
                foregroundColor: AppColors.textLight,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
              ),
              onPressed: selectedCount > 0
                  ? () {
                      final selectedIds = cart.selectedCartItemIds;
                      context.push(
                        AppRoutes.checkout,
                        extra: {
                          'source': 'CART',
                          'cartItemIds': selectedIds,
                        },
                      );
                    }
                  : null,
              child: Text(
                'Mua Hàng ($selectedCount)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
