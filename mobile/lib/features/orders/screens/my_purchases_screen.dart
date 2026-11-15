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
import '../../../core/widgets/status_pill_badge.dart';
import '../models/order_model.dart';
import '../viewmodels/buyer_order_view_model.dart';
import 'order_cancellation_dialog.dart';

/// M-OR-02: My Purchases Screen with 9 status tabs, order snapshots, and contextual action buttons.
class MyPurchasesScreen extends ConsumerStatefulWidget {
  final String initialTab;

  const MyPurchasesScreen({
    super.key,
    this.initialTab = 'ALL',
  });

  @override
  ConsumerState<MyPurchasesScreen> createState() => _MyPurchasesScreenState();
}

class _MyPurchasesScreenState extends ConsumerState<MyPurchasesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<Map<String, String>> _orderTabs = [
    {'key': 'ALL', 'label': 'Tất cả'},
    {'key': 'PENDING_PAYMENT', 'label': 'Chờ thanh toán'},
    {'key': 'PAID', 'label': 'Đã thanh toán'},
    {'key': 'PREPARING', 'label': 'Đang chuẩn bị'},
    {'key': 'SHIPPED', 'label': 'Đang giao'},
    {'key': 'DELIVERED', 'label': 'Đã giao'},
    {'key': 'COMPLETED', 'label': 'Hoàn thành'},
    {'key': 'CANCELLED', 'label': 'Đã hủy'},
    {'key': 'DISPUTED', 'label': 'Khiếu nại'},
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = _orderTabs.indexWhere((t) => t['key'] == widget.initialTab);
    if (initialIndex < 0) initialIndex = 0;

    _tabController = TabController(
      length: _orderTabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final key = _orderTabs[_tabController.index]['key']!;
        ref.read(buyerOrderViewModelProvider).switchTab(key);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(buyerOrderViewModelProvider).loadPurchases(tab: _orderTabs[initialIndex]['key']);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(buyerOrderViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Đơn mua của tôi'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primaryTerracotta,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryTerracotta,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _orderTabs.map((t) => Tab(text: t['label'])).toList(),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryTerracotta,
          onRefresh: () => ref.read(buyerOrderViewModelProvider).loadPurchases(refresh: true),
          child: vm.state.when(
            initial: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
            error: (msg, err) => RetroErrorRetryView(
              errorMessage: msg,
              onRetry: () => ref.read(buyerOrderViewModelProvider).loadPurchases(refresh: true),
            ),
            empty: (msg) => RetroEmptyStateView(
              title: 'Không có đơn mua',
              message: msg ?? 'Bạn chưa có đơn mua nào trong mục này.',
              actionLabel: 'Khám phá ngay',
              onAction: () => context.go(AppRoutes.home),
            ),
            success: (data) => _buildOrdersList(data.items, vm),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, BuyerOrderViewModel vm) {
    if (orders.isEmpty) {
      return RetroEmptyStateView(
        title: 'Không có đơn mua',
        message: 'Bạn chưa có đơn mua nào trong mục này.',
        actionLabel: 'Khám phá ngay',
        onAction: () => context.go(AppRoutes.home),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.spaceMd),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, vm);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, BuyerOrderViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        onTap: () => context.push(AppRoutes.orderDetailPath(order.id)),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Header & Status Badges
              Row(
                children: [
                  const Icon(Icons.storefront, size: 18, color: AppColors.secondaryPineGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.shopName,
                      style: AppTypography.headingSmall.copyWith(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusPillBadge(status: order.orderStatus, isCompact: true),
                ],
              ),

              if (order.cancellationRequested) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    border: Border.all(color: const Color(0xFFFFEEBA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.hourglass_empty, size: 12, color: Color(0xFF856404)),
                      SizedBox(width: 4),
                      Text(
                        'Đang chờ Tiệm duyệt hủy đơn (DEC-06)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF856404)),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 16, color: AppColors.borderSubtle),

              // Items Snapshot Preview
              ...order.items.map((item) => _buildItemRow(item)),

              const Divider(height: 16, color: AppColors.borderSubtle),

              // Bottom Price & Actions Row
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng thanh toán:',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      Text(
                        VndFormatter.format(order.totalAmount),
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.primaryTerracotta,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildContextualButtons(order, vm),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            child: Container(
              width: 52,
              height: 52,
              color: AppColors.surfaceWarm,
              child: item.primaryImageUrl != null && item.primaryImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.primaryImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTerracotta),
                      ),
                      errorWidget: (_, _, _) => const Icon(Icons.checkroom, color: AppColors.secondaryPineGreen),
                    )
                  : const Icon(Icons.checkroom, color: AppColors.secondaryPineGreen),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productTitle,
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ConditionBadge(condition: item.condition, isCompact: true),
                    const Spacer(),
                    Text(
                      '${VndFormatter.format(item.unitPrice)} x ${item.quantity}',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextualButtons(OrderModel order, BuyerOrderViewModel vm) {
    if (order.isPendingPayment) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => OrderCancellationDialog.show(
              context,
              order: order,
              onConfirmCancel: (reason) => vm.submitCancelOrder(order.id, reason: reason),
            ),
            child: const Text('Hủy', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTerracotta,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => context.push(AppRoutes.paymentQrPath(order.paymentId ?? order.id)),
            child: const Text('Thanh toán', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    if (order.isShipped || order.isDelivered) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => context.push(AppRoutes.shipmentTrackingPath(order.id)),
            child: const Text('Vận đơn', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryPineGreen,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _showConfirmDeliveryDialog(order, vm),
            child: const Text('Đã nhận hàng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    if (order.isCompleted) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => context.push(AppRoutes.orderDetailPath(order.id)),
        child: const Text('Xem chi tiết', style: TextStyle(fontSize: 12)),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => context.push(AppRoutes.orderDetailPath(order.id)),
      child: const Text('Chi tiết', style: TextStyle(fontSize: 12)),
    );
  }

  void _showConfirmDeliveryDialog(OrderModel order, BuyerOrderViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
        title: const Text('Xác nhận đã nhận hàng?'),
        content: Text(
          'Bạn xác nhận đã nhận đầy đủ sản phẩm và hài lòng? Toàn bộ 100% tiền hàng (${VndFormatter.format(order.sellerNetPayout)}) sẽ được giải ngân ngay vào Ví Tiệm ${order.shopName} (DEC-04).',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Xem lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryPineGreen,
              foregroundColor: AppColors.textLight,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await vm.confirmDelivery(order.id);
            },
            child: const Text('Xác nhận & Giải ngân'),
          ),
        ],
      ),
    );
  }
}
