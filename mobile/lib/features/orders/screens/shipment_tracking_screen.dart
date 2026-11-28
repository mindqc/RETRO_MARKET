import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../../core/widgets/status_pill_badge.dart';
import '../models/order_model.dart';
import '../models/shipment_model.dart';
import '../viewmodels/buyer_order_view_model.dart';

/// M-OR-05: Shipment Tracking & Escrow Lifecycle Screen.
class ShipmentTrackingScreen extends ConsumerStatefulWidget {
  final int orderId;
  final OrderModel? initialOrder;

  const ShipmentTrackingScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  ConsumerState<ShipmentTrackingScreen> createState() =>
      _ShipmentTrackingScreenState();
}

class _ShipmentTrackingScreenState
    extends ConsumerState<ShipmentTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(buyerOrderViewModelProvider).loadOrderDetail(widget.orderId);
    });
  }

  @override
  void didUpdateWidget(covariant ShipmentTrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(buyerOrderViewModelProvider).loadOrderDetail(widget.orderId);
      });
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(buyerOrderViewModelProvider);
    final OrderModel? order =
        (vm.selectedOrder != null && vm.selectedOrder!.id == widget.orderId)
            ? vm.selectedOrder
            : (widget.initialOrder != null &&
                    widget.initialOrder!.id == widget.orderId
                ? widget.initialOrder
                : null);

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        title: Text(
          order != null ? 'Vận đơn ${order.orderCode}' : 'Theo dõi vận đơn',
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: vm.isActionLoading && order == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.ctaTerracotta),
              )
            : order != null
                ? RefreshIndicator(
                    color: AppColors.ctaTerracotta,
                    onRefresh: () => ref
                        .read(buyerOrderViewModelProvider)
                        .loadOrderDetail(widget.orderId),
                    child: _buildTrackingBody(order),
                  )
                : RetroErrorRetryView(
                    errorMessage: vm.actionErrorMessage ??
                        'Không tìm thấy thông tin đơn hàng.',
                    onRetry: () => ref
                        .read(buyerOrderViewModelProvider)
                        .loadOrderDetail(widget.orderId),
                  ),
      ),
    );
  }

  Widget _buildTrackingBody(OrderModel order) {
    final carrier = order.shipment?.carrierName ?? 'Đang kết nối vận chuyển';
    final trackingCode = order.shipment?.trackingCode ?? 'CHƯA CẬP NHẬT';
    final events = order.buildFullLifecycleTimeline();

    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      children: [
        // 1. Carrier & Tracking Code Spotlight Card
        RetroPineSpotlightContainer(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.creamBadgeBg.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.creamBadgeBg.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      color: AppColors.creamBadgeBg,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          carrier,
                          style: AppTypography.headingSmall.copyWith(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Mã vận đơn: $trackingCode',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: AppColors.creamBadgeBg,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPillBadge(status: order.orderStatus, isCompact: true),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: DesignTokens.borderRadiusMd,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.starGold,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quỹ Escrow bảo vệ tiền hàng cho đến khi giao phát thành công.',
                        style: TextStyle(
                          color: AppColors.creamBadgeBg,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spaceLg),

        // 2. Timeline Milestones Card
        Container(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: DesignTokens.borderRadiusBanner,
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hành trình đơn hàng & Tiến trình Escrow',
                style: AppTypography.headingSmall.copyWith(
                  fontSize: 15.5,
                  color: AppColors.pineDeep,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              ...List.generate(events.length, (i) {
                final ev = events[i];
                final isLast = i == events.length - 1;
                return _buildTimelineStep(ev, isLast: isLast);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
    ShipmentTimelineEventModel event, {
    required bool isLast,
  }) {
    final color = event.isCompleted ? AppColors.verifiedLeaf : AppColors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: event.isCompleted ? color : AppColors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: event.isCompleted
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 52,
                color: event.isCompleted ? color : AppColors.borderSubtle,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: event.isCompleted
                      ? AppColors.textCharcoal
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                event.description,
                style: AppTypography.bodySmall.copyWith(
                  color: event.isCompleted
                      ? AppColors.textMuted
                      : const Color(0xFFB0A395),
                  fontSize: 12,
                ),
              ),
              if (event.timestamp != null) ...[
                const SizedBox(height: 3),
                Text(
                  _formatTimestamp(event.timestamp!),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.ctaTerracotta,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }
}
