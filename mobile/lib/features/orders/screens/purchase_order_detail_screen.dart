import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/server_time_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/condition_badge.dart';
import '../../../core/widgets/price_breakdown_card.dart';
import '../../../core/widgets/server_countdown_timer.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../../core/widgets/status_pill_badge.dart';
import '../models/order_model.dart';
import '../viewmodels/buyer_order_view_model.dart';
import 'order_cancellation_dialog.dart';

/// M-OR-03: Purchase Order Detail Screen displaying 4 independent state machines,
/// immutable order snapshot, auto-complete countdown, and escrow release controls.
class PurchaseOrderDetailScreen extends ConsumerStatefulWidget {
  final int orderId;
  final OrderModel? initialOrder;

  const PurchaseOrderDetailScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  ConsumerState<PurchaseOrderDetailScreen> createState() => _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends ConsumerState<PurchaseOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(buyerOrderViewModelProvider).loadOrderDetail(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(buyerOrderViewModelProvider);
    final order = vm.selectedOrder ?? widget.initialOrder;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: Text(order != null ? 'Đơn hàng ${order.orderCode}' : 'Chi tiết đơn mua'),
        elevation: 0,
      ),
      bottomNavigationBar: order != null ? _buildBottomActionBar(order, vm) : null,
      body: SafeArea(
        child: vm.isActionLoading && order == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta))
            : order != null
                ? RefreshIndicator(
                    color: AppColors.primaryTerracotta,
                    onRefresh: () => ref.read(buyerOrderViewModelProvider).loadOrderDetail(widget.orderId),
                    child: _buildOrderBody(order, vm),
                  )
                : RetroErrorRetryView(
                    errorMessage: vm.actionErrorMessage ?? 'Không tìm thấy thông tin đơn hàng.',
                    onRetry: () => ref.read(buyerOrderViewModelProvider).loadOrderDetail(widget.orderId),
                  ),
      ),
    );
  }

  Widget _buildOrderBody(OrderModel order, BuyerOrderViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      children: [
        // 1. 4 Independent State Machines Card
        _buildFourStateMachinesCard(order),

        const SizedBox(height: DesignTokens.spaceMd),

        // 2. Cancellation Request Alert (DEC-06)
        if (order.cancellationRequested) _buildCancellationAlertBox(order, vm),

        // 3. Auto-Complete Countdown Timer (OF-04)
        if (order.isDelivered && order.autoCompleteAt != null) _buildAutoCompleteTimerBox(order),

        const SizedBox(height: DesignTokens.spaceMd),

        // 4. Shipping Address Snapshot
        _buildAddressSnapshotCard(order),

        const SizedBox(height: DesignTokens.spaceMd),

        // 5. Order Items Snapshot
        _buildItemsSnapshotCard(order),

        const SizedBox(height: DesignTokens.spaceMd),

        // 6. Transparent Price Breakdown (DEC-04)
        PriceBreakdownCard(
          itemSubtotal: order.itemSubtotal,
          shippingFee: order.shippingFee,
          customBuyerProtectionFee: order.buyerProtectionFee,
          showSellerNetAmount: false,
        ),

        const SizedBox(height: DesignTokens.spaceMd),

        // 7. Escrow Guarantee Card
        _buildEscrowSecurityCard(order),

        const SizedBox(height: 80), // Padding for bottom sticky bar
      ],
    );
  }

  Widget _buildFourStateMachinesCard(OrderModel order) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mã đơn: ${order.orderCode}',
                style: AppTypography.headingSmall.copyWith(fontSize: 15),
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.shipmentTrackingPath(order.id)),
                child: Row(
                  children: const [
                    Text('Vận đơn', style: TextStyle(fontSize: 12, color: AppColors.secondaryPineGreen, fontWeight: FontWeight.bold)),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.secondaryPineGreen),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),

          // 4 Independent State Badges Grid
          _buildStateRow('Trạng thái đơn hàng', order.orderStatus),
          const SizedBox(height: 8),
          _buildStateRow('Trạng thái thanh toán', order.paymentStatus),
          const SizedBox(height: 8),
          _buildStateRow('Quỹ ký quỹ Escrow', order.escrowStatus),
          const SizedBox(height: 8),
          _buildStateRow('Trạng thái khiếu nại', order.disputeStatus),
        ],
      ),
    );
  }

  Widget _buildStateRow(String label, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        StatusPillBadge(status: status, isCompact: true),
      ],
    );
  }

  Widget _buildCancellationAlertBox(OrderModel order, BuyerOrderViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: const Color(0xFFFFEEBA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.hourglass_top, color: Color(0xFF856404), size: 18),
              SizedBox(width: 8),
              Text(
                'Yêu cầu xin hủy đơn đang chờ duyệt (DEC-06)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF856404)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lý do: ${order.cancellationRequestReason ?? order.cancelReason ?? "Chờ tiệm phản hồi"}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF856404)),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF856404),
                side: const BorderSide(color: Color(0xFF856404)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: vm.isActionLoading
                  ? null
                  : () async {
                      await vm.withdrawCancel(order.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã rút lại yêu cầu xin hủy đơn thành công!')),
                        );
                      }
                    },
              child: const Text('Rút lại yêu cầu xin hủy', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoCompleteTimerBox(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5EE),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: const Color(0xFFBCE3C6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.secondaryPineGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tự động hoàn tất & giải ngân sau:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondaryPineGreen),
                ),
                ServerCountdownTimer(
                  endsAt: order.autoCompleteAt!,
                  customClock: () => ServerTimeService.instance.now(),
                  onExpired: () => ref.read(buyerOrderViewModelProvider).loadOrderDetail(order.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSnapshotCard(OrderModel order) {
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
            children: const [
              Icon(Icons.location_on_outlined, color: AppColors.primaryTerracotta, size: 18),
              SizedBox(width: 6),
              Text('Địa chỉ nhận hàng (Snapshot)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${order.recipientName} • ${order.recipientPhone}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            order.fullAddress,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSnapshotCard(OrderModel order) {
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
              const Icon(Icons.storefront, size: 18, color: AppColors.secondaryPineGreen),
              const SizedBox(width: 6),
              Text(order.shopName, style: AppTypography.headingSmall.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 8),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    child: Container(
                      width: 56,
                      height: 56,
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
                        Text(item.productTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
          }),
        ],
      ),
    );
  }

  Widget _buildEscrowSecurityCard(OrderModel order) {
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
          const Icon(Icons.shield_outlined, color: AppColors.secondaryPineGreen, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cam Kết Bảo Vệ Escrow izithrift', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryPineGreen, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'Tiền hàng của bạn được bảo vệ trung gian và chỉ giải ngân cho Người bán khi bạn bấm xác nhận đã nhận hàng hoặc hết thời gian chờ tự động hoàn thành mà không có khiếu nại.',
                  style: AppTypography.caption.copyWith(color: AppColors.secondaryPineGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(OrderModel order, BuyerOrderViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: const Border(top: BorderSide(color: AppColors.borderWarm)),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: SafeArea(
        top: false,
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            // Cancel order button
            if (order.canBuyerCancelImmediately || order.canBuyerRequestCancel)
              OutlinedButton(
                key: const Key('btn_cancel_order_cta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusDanger,
                  side: const BorderSide(color: AppColors.statusDanger),
                ),
                onPressed: () => OrderCancellationDialog.show(
                  context,
                  order: order,
                  onConfirmCancel: (reason) => vm.submitCancelOrder(order.id, reason: reason),
                ),
                child: Text(order.isPreparing ? 'Xin hủy đơn' : 'Hủy đơn hàng'),
              ),

            // Open Dispute button
            if (order.canBuyerOpenDispute)
              OutlinedButton.icon(
                key: const Key('btn_open_dispute_cta'),
                icon: const Icon(Icons.report_problem_outlined, size: 16),
                label: const Text('Khiếu nại / Trả hàng'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusWarning,
                  side: const BorderSide(color: AppColors.statusWarning),
                ),
                onPressed: () => context.push(AppRoutes.openDisputePath(order.id)),
              ),

            // View existing active dispute
            if (order.activeDisputeId != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.gavel, size: 16),
                label: const Text('Xem hồ sơ khiếu nại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusWarning,
                  foregroundColor: AppColors.textLight,
                ),
                onPressed: () => context.push(AppRoutes.disputeDetailPath(order.activeDisputeId!)),
              ),

            // Confirm delivery button (releases escrow 100%)
            if (order.canBuyerConfirmDelivery)
              ElevatedButton.icon(
                key: const Key('btn_confirm_delivery_release_escrow'),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Đã nhận được hàng & Hài lòng', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryPineGreen,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: vm.isActionLoading ? null : () => _confirmDeliveryDialog(order, vm),
              ),

            // Payment redirect if unpaid
            if (order.isPendingPayment)
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text('Thanh toán QR ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTerracotta,
                  foregroundColor: AppColors.textLight,
                ),
                onPressed: () => context.push(AppRoutes.paymentQrPath(order.paymentId ?? order.id)),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeliveryDialog(OrderModel order, BuyerOrderViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
        title: const Text('Xác nhận nhận hàng & Giải ngân Escrow?'),
        content: Text(
          'Khi bấm Xác nhận, toàn bộ 100% tiền hàng (${VndFormatter.format(order.sellerNetPayout)}) sẽ được giải ngân ngay lập tức vào Ví Tiệm ${order.shopName} (DEC-04) và bạn không thể mở khiếu nại hoàn tiền được nữa.',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_release_dialog'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryPineGreen,
              foregroundColor: AppColors.textLight,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              final res = await vm.confirmDelivery(order.id);
              if (res != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xác nhận nhận hàng thành công! Tiền đã giải ngân cho tiệm.')),
                );
              }
            },
            child: const Text('Đồng ý & Giải ngân'),
          ),
        ],
      ),
    );
  }
}
