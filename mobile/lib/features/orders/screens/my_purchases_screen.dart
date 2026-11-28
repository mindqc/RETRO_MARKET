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

/// M-OR-02: My Purchases Screen with 9 status tabs,
/// order snapshots, and contextual action buttons.
class MyPurchasesScreen extends ConsumerStatefulWidget {
  final String initialTab;

  const MyPurchasesScreen({super.key, this.initialTab = 'ALL'});

  @override
  ConsumerState<MyPurchasesScreen> createState() => _MyPurchasesScreenState();
}

class _MyPurchasesScreenState extends ConsumerState<MyPurchasesScreen>
    with SingleTickerProviderStateMixin {
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

    int initialIndex = _orderTabs.indexWhere(
      (tab) => tab['key'] == widget.initialTab,
    );
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
      ref
          .read(buyerOrderViewModelProvider)
          .loadPurchases(tab: _orderTabs[initialIndex]['key']);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshOnReturn() {
    if (mounted) {
      ref.read(buyerOrderViewModelProvider).loadPurchases(refresh: true);
    }
  }

  void _openOrderDetail(OrderModel order) {
    context
        .push(AppRoutes.orderDetailPath(order.id), extra: order)
        .then((_) => _refreshOnReturn());
  }

  void _openShipmentTracking(OrderModel order) {
    context
        .push(AppRoutes.shipmentTrackingPath(order.id), extra: order)
        .then((_) => _refreshOnReturn());
  }

  void _openPaymentQr(OrderModel order) {
    context
        .push(AppRoutes.paymentQrPath(order.paymentId ?? order.id))
        .then((_) => _refreshOnReturn());
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(buyerOrderViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        surfaceTintColor: Colors.transparent,
        title: const Text('Đơn mua của tôi'),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderWarm)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              labelColor: AppColors.priceCrimson,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.priceCrimson,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: _orderTabs.map((tab) => Tab(text: tab['label'])).toList(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ctaTerracotta,
          onRefresh: () => ref
              .read(buyerOrderViewModelProvider)
              .loadPurchases(refresh: true),
          child: vm.state.when(
            initial: () => const _PurchasesLoadingState(),
            loading: () => const _PurchasesLoadingState(),
            error: (msg, err) => RetroErrorRetryView(
              errorMessage: msg,
              onRetry: () => ref
                  .read(buyerOrderViewModelProvider)
                  .loadPurchases(refresh: true),
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
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceMd,
        DesignTokens.spaceMd,
        DesignTokens.spaceMd,
        28,
      ),
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
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: InkWell(
        borderRadius: DesignTokens.borderRadiusLg,
        onTap: () => _openOrderDetail(order),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderHeader(order),
              if (order.cancellationRequested) ...[
                const SizedBox(height: 10),
                _buildCancellationNotice(),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: const BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                child: Column(
                  children: order.items.map(_buildItemRow).toList(),
                ),
              ),
              const SizedBox(height: 12),
              _buildOrderFooter(order, vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(OrderModel order) {
    return Row(
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
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.shopName,
                style: AppTypography.headingSmall.copyWith(
                  fontSize: 14.5,
                  color: AppColors.pineDeep,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (order.orderCode.isNotEmpty)
                Text(
                  order.orderCode,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        StatusPillBadge(status: order.orderStatus, isCompact: true),
      ],
    );
  }

  Widget _buildCancellationNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.creamBadgeSoft,
        borderRadius: DesignTokens.borderRadiusMd,
        border: Border.all(color: AppColors.creamBadgeBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 15,
            color: AppColors.creamBadgeText,
          ),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'Đang chờ Tiệm duyệt hủy đơn (DEC-06)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.creamBadgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: DesignTokens.borderRadiusMd,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                border: Border.all(color: AppColors.borderSubtle),
                borderRadius: DesignTokens.borderRadiusMd,
              ),
              child: item.primaryImageUrl != null &&
                      item.primaryImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.primaryImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.ctaTerracotta,
                          ),
                        ),
                      ),
                      errorWidget: (_, _, _) => const Icon(
                        Icons.checkroom_rounded,
                        color: AppColors.pineDeep,
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.checkroom_rounded,
                      color: AppColors.pineDeep,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productTitle,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textCharcoal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    ConditionBadge(condition: item.condition, isCompact: true),
                    Text(
                      'x${item.quantity}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  VndFormatter.format(item.unitPrice),
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderFooter(OrderModel order, BuyerOrderViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Tổng thanh toán',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Text(
              VndFormatter.format(order.totalAmount),
              style: AppTypography.priceSmall.copyWith(
                color: AppColors.priceCrimson,
                fontSize: 17,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: _buildContextualButtons(order, vm),
        ),
      ],
    );
  }

  Widget _buildContextualButtons(OrderModel order, BuyerOrderViewModel vm) {
    if (order.isPendingPayment) {
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            style: _outlinedActionStyle(),
            onPressed: () => OrderCancellationDialog.show(
              context,
              order: order,
              onConfirmCancel: (reason) =>
                  vm.submitCancelOrder(order.id, reason: reason),
            ),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: _primaryActionStyle(),
            onPressed: () => _openPaymentQr(order),
            child: const Text(
              'Thanh toán',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    if (order.isShipped || order.isDelivered) {
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            style: _outlinedActionStyle(),
            onPressed: () => _openShipmentTracking(order),
            child: const Text('Vận đơn'),
          ),
          ElevatedButton(
            style: _pineActionStyle(),
            onPressed: () => _showConfirmDeliveryDialog(order, vm),
            child: const Text(
              'Đã nhận hàng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    if (order.isCompleted) {
      return OutlinedButton(
        style: _outlinedActionStyle(),
        onPressed: () => _openOrderDetail(order),
        child: const Text('Xem chi tiết'),
      );
    }

    return OutlinedButton(
      style: _outlinedActionStyle(),
      onPressed: () => _openOrderDetail(order),
      child: const Text('Chi tiết'),
    );
  }

  ButtonStyle _outlinedActionStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.pineDeep,
      side: const BorderSide(color: AppColors.pineDeep),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      minimumSize: const Size(0, 38),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    );
  }

  ButtonStyle _primaryActionStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.ctaTerracotta,
      foregroundColor: AppColors.textLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      minimumSize: const Size(0, 38),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      elevation: 0,
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    );
  }

  ButtonStyle _pineActionStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.pineDeep,
      foregroundColor: AppColors.textLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      minimumSize: const Size(0, 38),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      elevation: 0,
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    );
  }

  void _showConfirmDeliveryDialog(OrderModel order, BuyerOrderViewModel vm) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusBanner,
        ),
        title: Text(
          'Xác nhận đã nhận hàng?',
          style: AppTypography.headingSmall.copyWith(color: AppColors.pineDeep),
        ),
        content: Text(
          'Bạn xác nhận đã nhận đầy đủ sản phẩm và hài lòng? '
          'Toàn bộ 100% tiền hàng (${VndFormatter.format(order.sellerNetPayout)}) '
          'sẽ được giải ngân ngay vào Ví Tiệm ${order.shopName} (DEC-04).',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Xem lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pineDeep,
              foregroundColor: AppColors.textLight,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await vm.confirmDelivery(order.id);
            },
            child: const Text('Xác nhận & Giải ngân'),
          ),
        ],
      ),
    );
  }
}

class _PurchasesLoadingState extends StatelessWidget {
  const _PurchasesLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.ctaTerracotta),
    );
  }
}
