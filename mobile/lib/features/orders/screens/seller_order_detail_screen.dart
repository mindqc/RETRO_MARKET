import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

/// M-SL-06: Seller Order Detail Screen managing cancellation responses (DEC-06),
/// 100% seller net revenue reconciliation (DEC-04), and shipping pipeline triggers.
class SellerOrderDetailScreen extends ConsumerStatefulWidget {
  final int orderId;
  final OrderModel? initialOrder;

  const SellerOrderDetailScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  ConsumerState<SellerOrderDetailScreen> createState() => _SellerOrderDetailScreenState();
}

class _SellerOrderDetailScreenState extends ConsumerState<SellerOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sellerOrderViewModelProvider).loadOrderDetail(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(sellerOrderViewModelProvider);
    final order = vm.selectedOrder ?? widget.initialOrder;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: Text(order != null ? 'Đơn bán ${order.orderCode}' : 'Chi tiết đơn bán'),
        elevation: 0,
      ),
      bottomNavigationBar: order != null ? _buildBottomPipelineBar(order, vm) : null,
      body: SafeArea(
        child: vm.isActionLoading && order == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondaryPineGreen))
            : order != null
                ? RefreshIndicator(
                    color: AppColors.secondaryPineGreen,
                    onRefresh: () => ref.read(sellerOrderViewModelProvider).loadOrderDetail(widget.orderId),
                    child: _buildBody(order, vm),
                  )
                : RetroErrorRetryView(
                    errorMessage: vm.actionErrorMessage ?? 'Không tìm thấy thông tin đơn bán.',
                    onRetry: () => ref.read(sellerOrderViewModelProvider).loadOrderDetail(widget.orderId),
                  ),
      ),
    );
  }

  Widget _buildBody(OrderModel order, SellerOrderViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      children: [
        // 1. Four State Machines Header Card
        _buildStateSummaryCard(order),

        const SizedBox(height: DesignTokens.spaceMd),

        // 2. Urgent Cancellation Response Card (DEC-06 / DEC-07)
        if (order.cancellationRequested) _buildCancellationDecisionCard(order, vm),

        // 3. Buyer & Address Snapshot
        _buildBuyerAddressCard(order),

        const SizedBox(height: DesignTokens.spaceMd),

        // 4. Products Snapshot
        _buildProductsCard(order),

        const SizedBox(height: DesignTokens.spaceMd),

        // 5. 100% Net Revenue Settlement Card (DEC-04)
        _buildSellerSettlementCard(order),

        const SizedBox(height: 80), // Padding for sticky bottom bar
      ],
    );
  }

  Widget _buildStateSummaryCard(OrderModel order) {
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
          Text('Tiến trình đơn bán: ${order.orderCode}', style: AppTypography.headingSmall.copyWith(fontSize: 15)),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 10),
          _buildRow('Trạng thái đơn hàng', order.orderStatus),
          const SizedBox(height: 8),
          _buildRow('Thanh toán người mua', order.paymentStatus),
          const SizedBox(height: 8),
          _buildRow('Ký quỹ Escrow', order.escrowStatus),
          const SizedBox(height: 8),
          _buildRow('Trạng thái khiếu nại', order.disputeStatus),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        StatusPillBadge(status: status, isCompact: true),
      ],
    );
  }

  Widget _buildCancellationDecisionCard(OrderModel order, SellerOrderViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: const Color(0xFFFFEEBA), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 20),
              SizedBox(width: 8),
              Text(
                'Khách mua gửi yêu cầu xin hủy đơn (DEC-06)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF856404)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lý do từ người mua: "${order.cancellationRequestReason ?? order.cancelReason ?? "Đổi ý không mua nữa"}"',
            style: const TextStyle(fontSize: 12, color: Color(0xFF856404)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('btn_seller_reject_cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF856404),
                    side: const BorderSide(color: Color(0xFF856404)),
                  ),
                  onPressed: () => _showRejectCancelDialog(order, vm),
                  child: const Text('Từ chối hủy (Tiếp tục gửi)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  key: const Key('btn_seller_approve_cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusDanger,
                    foregroundColor: AppColors.textLight,
                  ),
                  onPressed: () => _showApproveCancelDialog(order, vm),
                  child: const Text('Đồng ý hủy & Hoàn tiền'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerAddressCard(OrderModel order) {
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
              Icon(Icons.person_pin_circle_outlined, color: AppColors.secondaryPineGreen, size: 20),
              SizedBox(width: 6),
              Text('Thông tin khách hàng & Địa chỉ giao', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${order.recipientName} • ${order.recipientPhone}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(order.fullAddress, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildProductsCard(OrderModel order) {
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
          Text('Danh sách món đồ đóng gói (${order.items.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 8),
          ...order.items.map((item) {
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
                          ? CachedNetworkImage(imageUrl: item.primaryImageUrl!, fit: BoxFit.cover)
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

  Widget _buildSellerSettlementCard(OrderModel order) {
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
          Text('Đối soát doanh thu đơn bán (DEC-04)', style: AppTypography.headingSmall.copyWith(fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng tiền hàng:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              Text(VndFormatter.format(order.itemSubtotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Chiết khấu phí sàn izithrift:', style: TextStyle(color: AppColors.secondaryPineGreen, fontSize: 13)),
              Text('0% (0đ)', style: TextStyle(color: AppColors.secondaryPineGreen, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tiệm thực nhận 100%:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textCharcoal)),
              Text(
                VndFormatter.format(order.sellerNetPayout),
                style: AppTypography.headingSmall.copyWith(color: AppColors.secondaryPineGreen, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPipelineBar(OrderModel order, SellerOrderViewModel vm) {
    if (order.isPaid) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        color: AppColors.surfaceCard,
        child: ElevatedButton.icon(
          key: const Key('btn_seller_detail_prepare'),
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Bắt đầu chuẩn bị & đóng gói hàng', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTerracotta,
            foregroundColor: AppColors.textLight,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: vm.isActionLoading ? null : () => vm.markPreparing(order.id),
        ),
      );
    }

    if (order.isPreparing) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        color: AppColors.surfaceCard,
        child: ElevatedButton.icon(
          key: const Key('btn_seller_detail_ship'),
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Giao hàng cho đơn vị vận chuyển', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryPineGreen,
            foregroundColor: AppColors.textLight,
            padding: const EdgeInsets.symmetric(vertical: 12),
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
        ),
      );
    }

    if (order.isShipped) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        color: AppColors.surfaceCard,
        child: ElevatedButton.icon(
          key: const Key('btn_seller_detail_deliver'),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Xác nhận đã giao hàng thành công', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusWarning,
            foregroundColor: AppColors.textLight,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: vm.isActionLoading ? null : () => vm.markDelivered(order.id),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showApproveCancelDialog(OrderModel order, SellerOrderViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đồng ý hủy đơn & Hoàn tiền?'),
        content: const Text(
          'Bạn xác nhận đồng ý yêu cầu hủy đơn? 100% tiền sẽ được hoàn lại cho người mua (DEC-07) và đơn hàng chuyển sang trạng thái ĐÃ HỦY.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Đóng')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(context).pop();
              await vm.respondCancelRequest(order.id, action: 'APPROVE');
            },
            child: const Text('Đồng ý hủy'),
          ),
        ],
      ),
    );
  }

  void _showRejectCancelDialog(OrderModel order, SellerOrderViewModel vm) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Từ chối yêu cầu hủy đơn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vui lòng nhập lý do từ chối gửi đến người mua:'),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(hintText: 'Ví dụ: Hàng đã đóng gói và chuẩn bị giao'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusWarning, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(context).pop();
              await vm.respondCancelRequest(order.id, action: 'REJECT', reason: noteController.text.trim());
            },
            child: const Text('Từ chối & Tiếp tục đơn'),
          ),
        ],
      ),
    );
  }
}
