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

class PurchaseOrderDetailScreen extends ConsumerStatefulWidget {
  final int orderId;
  final OrderModel? initialOrder;

  const PurchaseOrderDetailScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  ConsumerState<PurchaseOrderDetailScreen> createState() =>
      _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState
    extends ConsumerState<PurchaseOrderDetailScreen> {
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
        title: Text(
          order != null ? 'Đơn hàng ${order.orderCode}' : 'Chi tiết đơn mua',
        ),
        elevation: 0,
      ),
      bottomNavigationBar: order != null
          ? _buildBottomActionBar(order, vm)
          : null,
      body: SafeArea(
        child: vm.isActionLoading && order == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryTerracotta,
                ),
              )
            : order != null
            ? RefreshIndicator(
                color: AppColors.primaryTerracotta,
                onRefresh: () => ref
                    .read(buyerOrderViewModelProvider)
                    .loadOrderDetail(widget.orderId),
                child: _buildOrderBody(order, vm),
              )
            : RetroErrorRetryView(
                errorMessage:
                    vm.actionErrorMessage ??
                    'Không tìm thấy thông tin đơn hàng.',
                onRetry: () => ref
                    .read(buyerOrderViewModelProvider)
                    .loadOrderDetail(widget.orderId),
              ),
      ),
    );
  }

  Widget _buildOrderBody(OrderModel order, BuyerOrderViewModel vm) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceMd,
        DesignTokens.spaceSm,
        DesignTokens.spaceMd,
        DesignTokens.spaceMd,
      ),
      children: [
        _buildOrderHero(order),
        const SizedBox(height: DesignTokens.spaceMd),

        _buildShipmentTimeline(order),
        const SizedBox(height: DesignTokens.spaceMd),

        _buildFourStateMachinesCard(order),
        const SizedBox(height: DesignTokens.spaceMd),

        if (order.cancellationRequested) _buildCancellationAlertBox(order, vm),

        if (order.isDelivered && order.autoCompleteAt != null)
          _buildAutoCompleteTimerBox(order),

        _buildAddressSnapshotCard(order),
        const SizedBox(height: DesignTokens.spaceMd),

        _buildItemsSnapshotCard(order),
        const SizedBox(height: DesignTokens.spaceMd),

        PriceBreakdownCard(
          itemSubtotal: order.itemSubtotal,
          shippingFee: order.shippingFee,
          customBuyerProtectionFee: order.buyerProtectionFee,
          showSellerNetAmount: false,
        ),
        const SizedBox(height: DesignTokens.spaceMd),

        _buildEscrowSecurityCard(order),
        const SizedBox(height: 100),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ORDER HERO
  // ---------------------------------------------------------------------------

  Widget _buildOrderHero(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondaryPineGreen, Color(0xFF21452F)],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHI TIẾT ĐƠN HÀNG',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mã đơn: ${order.orderCode}',
                      style: AppTypography.headingSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => context.push(AppRoutes.shipmentTrackingPath(order.id)),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.secondaryPineGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Xem hành trình vận đơn',
                    style: TextStyle(
                      color: AppColors.secondaryPineGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.secondaryPineGreen,
                    size: 18,
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
  // SHIPMENT TIMELINE — only use backend-provided timeline events
  // ---------------------------------------------------------------------------

  Widget _buildShipmentTimeline(OrderModel order) {
    final shipment = order.shipment;
    final events = shipment?.timelineEvents ?? [];

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.route_outlined,
            title: 'Hành trình đơn hàng',
            subtitle: 'Cập nhật từ vận chuyển',
          ),
          if (shipment != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shipment.carrierName.isNotEmpty)
                    _infoLine(
                      Icons.local_shipping_outlined,
                      'Đơn vị vận chuyển',
                      shipment.carrierName,
                    ),
                  if (shipment.trackingCode.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _infoLine(
                      Icons.qr_code_2_rounded,
                      'Mã vận đơn',
                      shipment.trackingCode,
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (events.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...List.generate(events.length, (index) {
              final event = events[index];
              final isLast = index == events.length - 1;

              return _timelineEvent(
                title: event.title,
                description: event.description,
                completed: event.isCompleted,
                isLast: isLast,
              );
            }),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              'Thông tin hành trình sẽ được cập nhật khi đơn hàng có tiến trình vận chuyển.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timelineEvent({
    required String title,
    required String description,
    required bool completed,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: completed
                    ? AppColors.secondaryPineGreen
                    : AppColors.textMuted,
                size: 20,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 42,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  color: completed
                      ? AppColors.secondaryPineGreen.withValues(alpha: 0.35)
                      : AppColors.borderWarm,
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: completed ? FontWeight.w700 : FontWeight.w500,
                    color: completed ? Colors.black87 : AppColors.textMuted,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FOUR STATE MACHINES
  // ---------------------------------------------------------------------------

  Widget _buildFourStateMachinesCard(OrderModel order) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.fact_check_outlined,
            title: 'Trạng thái giao dịch',
            subtitle: 'Theo dõi từng trạng thái riêng biệt',
          ),
          const SizedBox(height: 14),
          _buildStateRow('Trạng thái đơn hàng', order.orderStatus),
          const SizedBox(height: 10),
          _buildStateRow('Trạng thái thanh toán', order.paymentStatus),
          const SizedBox(height: 10),
          _buildStateRow('Quỹ ký quỹ Escrow', order.escrowStatus),
          const SizedBox(height: 10),
          _buildStateRow('Trạng thái khiếu nại', order.disputeStatus),
        ],
      ),
    );
  }

  Widget _buildStateRow(String label, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          StatusPillBadge(status: status, isCompact: true),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CANCELLATION REQUEST
  // ---------------------------------------------------------------------------

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
              Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFF856404),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Yêu cầu xin hủy đơn đang chờ duyệt (DEC-06)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF856404),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lý do: ${order.cancellationRequestReason ?? order.cancelReason ?? "Chờ tiệm phản hồi"}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF856404)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF856404),
                side: const BorderSide(color: Color(0xFF856404)),
              ),
              onPressed: vm.isActionLoading
                  ? null
                  : () async {
                      await vm.withdrawCancel(order.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đã rút lại yêu cầu xin hủy đơn thành công!',
                            ),
                          ),
                        );
                      }
                    },
              child: const Text('Rút lại yêu cầu xin hủy'),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AUTO-COMPLETE COUNTDOWN
  // ---------------------------------------------------------------------------

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.timer_outlined,
            color: AppColors.secondaryPineGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thời gian bảo vệ đơn hàng',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryPineGreen,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Đơn hàng sẽ tự động hoàn tất và giải ngân nếu không có khiếu nại.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryPineGreen,
                  ),
                ),
                const SizedBox(height: 8),
                ServerCountdownTimer(
                  endsAt: order.autoCompleteAt!,
                  customClock: () => ServerTimeService.instance.now(),
                  onExpired: () => ref
                      .read(buyerOrderViewModelProvider)
                      .loadOrderDetail(order.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHIPPING ADDRESS
  // ---------------------------------------------------------------------------

  Widget _buildAddressSnapshotCard(OrderModel order) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.location_on_outlined,
            title: 'Địa chỉ nhận hàng',
            subtitle: 'Thông tin tại thời điểm đặt đơn',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.recipientName} • ${order.recipientPhone}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 17,
                      color: AppColors.primaryTerracotta,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.fullAddress,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
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

  // ---------------------------------------------------------------------------
  // PRODUCT SNAPSHOT
  // ---------------------------------------------------------------------------

  Widget _buildItemsSnapshotCard(OrderModel order) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.storefront_outlined,
            title: order.shopName,
            subtitle: 'Thông tin sản phẩm đã mua',
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 8),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    child: SizedBox(
                      width: 84,
                      height: 100,
                      child:
                          item.primaryImageUrl != null &&
                              item.primaryImageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.primaryImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const ColoredBox(
                                color: AppColors.surfaceWarm,
                                child: Icon(
                                  Icons.checkroom_outlined,
                                  color: AppColors.secondaryPineGreen,
                                ),
                              ),
                              errorWidget: (_, _, _) => const ColoredBox(
                                color: AppColors.surfaceWarm,
                                child: Icon(
                                  Icons.checkroom_outlined,
                                  color: AppColors.secondaryPineGreen,
                                ),
                              ),
                            )
                          : const ColoredBox(
                              color: AppColors.surfaceWarm,
                              child: Icon(
                                Icons.checkroom_outlined,
                                color: AppColors.secondaryPineGreen,
                              ),
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
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ConditionBadge(
                          condition: item.condition,
                          isCompact: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${VndFormatter.format(item.unitPrice)} × ${item.quantity}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (item.defectInfo != null &&
                            item.defectInfo!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusSm,
                              ),
                            ),
                            child: Text(
                              'Tình trạng sản phẩm: ${item.defectInfo}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF856404),
                              ),
                            ),
                          ),
                        ],
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

  // ---------------------------------------------------------------------------
  // ESCROW
  // ---------------------------------------------------------------------------

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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.secondaryPineGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cam Kết Bảo Vệ Escrow izithrift',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryPineGreen,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tiền hàng của bạn được bảo vệ trung gian và chỉ giải ngân cho Người bán khi bạn bấm xác nhận đã nhận hàng hoặc hết thời gian chờ tự động hoàn thành mà không có khiếu nại.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondaryPineGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STICKY ACTION BAR
  // ---------------------------------------------------------------------------

  Widget _buildBottomActionBar(OrderModel order, BuyerOrderViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceMd,
        vertical: 10,
      ),
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
                  onConfirmCancel: (reason) =>
                      vm.submitCancelOrder(order.id, reason: reason),
                ),
                child: Text(order.isPreparing ? 'Xin hủy đơn' : 'Hủy đơn hàng'),
              ),

            if (order.canBuyerOpenDispute)
              OutlinedButton.icon(
                key: const Key('btn_open_dispute_cta'),
                icon: const Icon(Icons.report_problem_outlined, size: 16),
                label: const Text('Khiếu nại / Trả hàng'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusWarning,
                  side: const BorderSide(color: AppColors.statusWarning),
                ),
                onPressed: () =>
                    context.push(AppRoutes.openDisputePath(order.id)),
              ),

            if (order.activeDisputeId != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.gavel, size: 16),
                label: const Text('Xem hồ sơ khiếu nại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusWarning,
                  foregroundColor: AppColors.textLight,
                ),
                onPressed: () => context.push(
                  AppRoutes.disputeDetailPath(order.activeDisputeId!),
                ),
              ),

            if (order.canReview)
              ElevatedButton.icon(
                key: const Key('btn_review_order_cta'),
                icon: const Icon(Icons.star_outline_rounded, size: 18),
                label: const Text('Đánh giá sản phẩm & Tiệm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF3F3210),
                ),
                onPressed: () =>
                    context.push(AppRoutes.orderReviewPath(order.id)),
              ),

            if (order.canBuyerConfirmDelivery)
              ElevatedButton.icon(
                key: const Key('btn_confirm_delivery_release_escrow'),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text(
                  'Đã nhận được hàng & Hài lòng',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryPineGreen,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                onPressed: vm.isActionLoading
                    ? null
                    : () => _confirmDeliveryDialog(order, vm),
              ),

            if (order.isPendingPayment)
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text(
                  'Thanh toán QR ngay',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTerracotta,
                  foregroundColor: AppColors.textLight,
                ),
                onPressed: () => context.push(
                  AppRoutes.paymentQrPath(order.paymentId ?? order.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONFIRM DELIVERY DIALOG — preserve original business logic
  // ---------------------------------------------------------------------------

  void _confirmDeliveryDialog(OrderModel order, BuyerOrderViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
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
                  const SnackBar(
                    content: Text(
                      'Xác nhận nhận hàng thành công! Tiền đã giải ngân cho tiệm.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Đồng ý & Giải ngân'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE UI HELPERS
  // ---------------------------------------------------------------------------

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
          child: Icon(icon, color: AppColors.secondaryPineGreen, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.headingSmall.copyWith(fontSize: 14),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoLine(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryPineGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
