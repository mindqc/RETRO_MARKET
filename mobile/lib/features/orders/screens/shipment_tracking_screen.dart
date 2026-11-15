import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
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
  ConsumerState<ShipmentTrackingScreen> createState() => _ShipmentTrackingScreenState();
}

class _ShipmentTrackingScreenState extends ConsumerState<ShipmentTrackingScreen> {
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
        title: Text(order != null ? 'Vận đơn ${order.orderCode}' : 'Theo dõi vận đơn'),
        elevation: 0,
      ),
      body: SafeArea(
        child: vm.isActionLoading && order == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta))
            : order != null
                ? RefreshIndicator(
                    color: AppColors.primaryTerracotta,
                    onRefresh: () => ref.read(buyerOrderViewModelProvider).loadOrderDetail(widget.orderId),
                    child: _buildTrackingBody(order),
                  )
                : RetroErrorRetryView(
                    errorMessage: vm.actionErrorMessage ?? 'Không tìm thấy thông tin đơn hàng.',
                    onRetry: () => ref.read(buyerOrderViewModelProvider).loadOrderDetail(widget.orderId),
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
        // 1. Carrier & Tracking Code Card
        Container(
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
                  const Icon(Icons.local_shipping_outlined, color: AppColors.secondaryPineGreen, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          carrier,
                          style: AppTypography.headingSmall.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mã vận đơn: $trackingCode',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryTerracotta),
                        ),
                      ],
                    ),
                  ),
                  StatusPillBadge(status: order.orderStatus, isCompact: true),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.secondaryPineGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quỹ Escrow bảo vệ tiền hàng cho đến khi giao phát thành công.',
                      style: AppTypography.caption.copyWith(color: AppColors.secondaryPineGreen, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spaceLg),

        // 2. Timeline Milestones
        Text(
          'Hành trình đơn hàng & Tiến trình Escrow',
          style: AppTypography.headingSmall.copyWith(fontSize: 15),
        ),
        const SizedBox(height: DesignTokens.spaceMd),

        ...List.generate(events.length, (i) {
          final ev = events[i];
          final isLast = i == events.length - 1;
          return _buildTimelineStep(ev, isLast: isLast);
        }),
      ],
    );
  }

  Widget _buildTimelineStep(ShipmentTimelineEventModel event, {required bool isLast}) {
    final color = event.isCompleted ? AppColors.secondaryPineGreen : AppColors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: event.isCompleted ? color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: event.isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
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
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: event.isCompleted ? AppColors.textCharcoal : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                event.description,
                style: AppTypography.bodySmall.copyWith(
                  color: event.isCompleted ? AppColors.textMuted : const Color(0xFFB0A395),
                  fontSize: 12,
                ),
              ),
              if (event.timestamp != null) ...[
                const SizedBox(height: 2),
                Text(
                  event.timestamp!.toLocal().toString().substring(0, 16),
                  style: const TextStyle(fontSize: 11, color: AppColors.statusWarning),
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
