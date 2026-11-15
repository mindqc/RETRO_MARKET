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
import '../viewmodels/seller_order_view_model.dart';
import 'ship_order_form_modal.dart';

/// M-SL-05: Seller Orders Management Screen with pipeline filters, quick actions, and urgent cancellation banners.
class SellerOrdersScreen extends ConsumerStatefulWidget {
  final String initialTab;

  const SellerOrdersScreen({
    super.key,
    this.initialTab = 'ALL',
  });

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<Map<String, String>> _sellerTabs = [
    {'key': 'ALL', 'label': 'Tất cả'},
    {'key': 'PAID', 'label': 'Chờ chuẩn bị'},
    {'key': 'PREPARING', 'label': 'Đang đóng gói'},
    {'key': 'SHIPPED', 'label': 'Đang giao'},
    {'key': 'DELIVERED', 'label': 'Đã giao'},
    {'key': 'CANCEL_REQUESTED', 'label': 'Cần duyệt hủy'},
    {'key': 'COMPLETED', 'label': 'Hoàn tất'},
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = _sellerTabs.indexWhere((t) => t['key'] == widget.initialTab);
    if (initialIndex < 0) initialIndex = 0;

    _tabController = TabController(
      length: _sellerTabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final key = _sellerTabs[_tabController.index]['key']!;
        ref.read(sellerOrderViewModelProvider).switchTab(key);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sellerOrderViewModelProvider).loadSellerOrders(tab: _sellerTabs[initialIndex]['key']);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(sellerOrderViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Quản lý đơn bán của Tiệm'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.secondaryPineGreen,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.secondaryPineGreen,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _sellerTabs.map((t) => Tab(text: t['label'])).toList(),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.secondaryPineGreen,
          onRefresh: () => ref.read(sellerOrderViewModelProvider).loadSellerOrders(refresh: true),
          child: vm.state.when(
            initial: () => const Center(child: CircularProgressIndicator(color: AppColors.secondaryPineGreen)),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.secondaryPineGreen)),
            error: (msg, err) => RetroErrorRetryView(
              errorMessage: msg,
              onRetry: () => ref.read(sellerOrderViewModelProvider).loadSellerOrders(refresh: true),
            ),
            empty: (msg) => RetroEmptyStateView(
              title: 'Không có đơn bán',
              message: msg ?? 'Tiệm của bạn chưa có đơn bán nào trong mục này.',
              actionLabel: 'Làm mới',
              onAction: () => ref.read(sellerOrderViewModelProvider).loadSellerOrders(refresh: true),
            ),
            success: (data) => _buildOrdersList(data.items, vm),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, SellerOrderViewModel vm) {
    if (orders.isEmpty) {
      return RetroEmptyStateView(
        title: 'Không có đơn bán',
        message: 'Tiệm của bạn chưa có đơn bán nào trong mục này.',
        actionLabel: 'Làm mới',
        onAction: () => ref.read(sellerOrderViewModelProvider).loadSellerOrders(refresh: true),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.spaceMd),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildSellerOrderCard(order, vm);
      },
    );
  }

  Widget _buildSellerOrderCard(OrderModel order, SellerOrderViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        onTap: () => context.push(AppRoutes.sellerOrderDetailPath(order.id)),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Buyer & Status Header
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: AppColors.primaryTerracotta),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Khách mua: ${order.buyerName}',
                      style: AppTypography.headingSmall.copyWith(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusPillBadge(status: order.orderStatus, isCompact: true),
                ],
              ),

              // Urgent Cancel Alert
              if (order.cancellationRequested) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    border: Border.all(color: const Color(0xFFFFEEBA)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFF856404)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Khách đã gửi yêu cầu hủy đơn! Vui lòng vào chi tiết để duyệt hoặc từ chối.',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF856404)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 16, color: AppColors.borderSubtle),

              // Products list
              ...order.items.map((item) => _buildProductRow(item)),

              const Divider(height: 16, color: AppColors.borderSubtle),

              // Price & Actions
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thực nhận (100%):', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      Text(
                        VndFormatter.format(order.sellerNetPayout),
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.secondaryPineGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildPipelineActionButtons(order, vm),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow(dynamic item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            child: Container(
              width: 48,
              height: 48,
              color: AppColors.surfaceWarm,
              child: item.primaryImageUrl != null && item.primaryImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.primaryImageUrl!,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.checkroom, color: AppColors.secondaryPineGreen),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ConditionBadge(condition: item.condition, isCompact: true),
                    const Spacer(),
                    Text('${VndFormatter.format(item.unitPrice)} x ${item.quantity}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineActionButtons(OrderModel order, SellerOrderViewModel vm) {
    // 1. If Paid -> Chuẩn bị hàng
    if (order.isPaid) {
      return ElevatedButton.icon(
        key: const Key('btn_seller_prepare_order'),
        icon: const Icon(Icons.inventory_2_outlined, size: 16),
        label: const Text('Chuẩn bị hàng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTerracotta,
          foregroundColor: AppColors.textLight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: vm.isActionLoading ? null : () => vm.markPreparing(order.id),
      );
    }

    // 2. If Preparing -> Gửi hàng
    if (order.isPreparing) {
      return ElevatedButton.icon(
        key: const Key('btn_seller_ship_order'),
        icon: const Icon(Icons.local_shipping_outlined, size: 16),
        label: const Text('Gửi hàng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryPineGreen,
          foregroundColor: AppColors.textLight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: () => ShipOrderFormModal.show(
          context,
          orderId: order.id,
          orderCode: order.orderCode,
          onConfirmShip: ({required carrierName, required trackingCode, shippingNote}) {
            return vm.shipOrder(
              order.id,
              carrierName: carrierName,
              trackingCode: trackingCode,
              shippingNote: shippingNote,
            );
          },
        ),
      );
    }

    // 3. If Shipped -> Xác nhận giao
    if (order.isShipped) {
      return ElevatedButton.icon(
        key: const Key('btn_seller_deliver_order'),
        icon: const Icon(Icons.check_circle_outline, size: 16),
        label: const Text('Xác nhận đã giao', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.statusWarning,
          foregroundColor: AppColors.textLight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: vm.isActionLoading ? null : () => vm.markDelivered(order.id),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () => context.push(AppRoutes.sellerOrderDetailPath(order.id)),
      child: const Text('Chi tiết', style: TextStyle(fontSize: 12)),
    );
  }
}
