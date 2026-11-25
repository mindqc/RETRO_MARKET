import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/status_pill_badge.dart';
import '../models/payment_session_model.dart';

/// M-PM-02: Payment Success Screen
/// Confirms payment and escrow holding state for the RETRO MARKET demo.
class PaymentSuccessScreen extends StatelessWidget {
  final int paymentId;
  final PaymentSessionModel? session;

  const PaymentSuccessScreen({
    super.key,
    required this.paymentId,
    this.session,
  });

  @override
  Widget build(BuildContext context) {
    final orderCode = session?.orderCode ?? 'ORD-$paymentId';
    final amount = session?.amount ?? 0.0;
    final orderId = session?.orderId ?? paymentId;
    final escrowStatus = session?.escrowStatus ?? 'HELD';

    final escrowHeld = escrowStatus == 'HELD' || escrowStatus == 'ESCROW_HELD';

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Thanh toán thành công'),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: AppColors.backgroundCream,
        foregroundColor: AppColors.textCharcoal,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spaceLg,
            DesignTokens.spaceMd,
            DesignTokens.spaceLg,
            DesignTokens.space3xl,
          ),
          child: Column(
            children: [
              _buildSuccessHero(escrowHeld, amount),
              const SizedBox(height: DesignTokens.spaceLg),
              _buildOrderSummary(orderCode, escrowStatus),
              const SizedBox(height: DesignTokens.spaceMd),
              _buildEscrowNotice(escrowHeld),
              const SizedBox(height: DesignTokens.spaceXl),
              _buildActions(context, orderId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHero(bool escrowHeld, num amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceLg,
        vertical: DesignTokens.spaceXl,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryForestGreen,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F2E7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primaryForestGreen,
              size: 72,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: const Text(
              'PAYMENT SUCCESSFUL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          Text(
            'Thanh toán thành công!',
            textAlign: TextAlign.center,
            style: AppTypography.headingLarge.copyWith(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            escrowHeld
                ? 'Khoản thanh toán đã được ghi nhận và giữ trong Escrow.'
                : 'Kết quả thanh toán đã được ghi nhận.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFFDCE9D9),
            ),
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          const Text(
            'TỔNG THANH TOÁN',
            style: TextStyle(
              color: Color(0xFFDCE9D9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            VndFormatter.format(amount),
            style: AppTypography.headingLarge.copyWith(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(String orderCode, String escrowStatus) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primaryTerracotta,
                size: 21,
              ),
              const SizedBox(width: 8),
              Text('Chi tiết giao dịch', style: AppTypography.headingSmall),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          _buildInfoRow('Mã đơn hàng', orderCode, bold: true),
          const Divider(height: 24, color: AppColors.borderSubtle),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Trạng thái thanh toán',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
              const StatusPillBadge(status: 'PAID', isCompact: true),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Trạng thái Escrow',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
              StatusPillBadge(status: escrowStatus, isCompact: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool bold = false,
    bool highlighted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: highlighted
                  ? AppColors.primaryTerracotta
                  : AppColors.textCharcoal,
              fontSize: highlighted ? 17 : 13,
              fontWeight: bold || highlighted
                  ? FontWeight.w800
                  : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEscrowNotice(bool escrowHeld) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2E8),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: const Color(0xFFB9D9BD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_rounded,
            color: AppColors.primaryForestGreen,
            size: 23,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  escrowHeld
                      ? 'Tiền của bạn đang được bảo vệ'
                      : 'Thông tin bảo vệ giao dịch',
                  style: const TextStyle(
                    color: AppColors.primaryForestGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  escrowHeld
                      ? 'izithrift đang giữ khoản thanh toán trung gian. Tiền chỉ được giải ngân cho Người bán sau khi bạn xác nhận đã nhận hàng đúng mô tả.'
                      : 'Trạng thái giữ tiền trung gian hiện chưa được xác nhận. Bạn có thể kiểm tra chi tiết đơn hàng.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primaryForestGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, int orderId) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            key: const Key('btn_view_order_detail'),
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text(
              'Xem chi tiết đơn mua',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTerracotta,
              foregroundColor: AppColors.textLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
            onPressed: () => context.push(AppRoutes.orderDetailPath(orderId)),
          ),
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            key: const Key('btn_continue_shopping'),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Tiếp tục mua sắm'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryForestGreen,
              side: const BorderSide(color: AppColors.primaryForestGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
            onPressed: () => context.go(AppRoutes.home),
          ),
        ),
      ],
    );
  }
}
