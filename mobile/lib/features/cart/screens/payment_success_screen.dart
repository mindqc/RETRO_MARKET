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
/// Confirms that buyer payment succeeded and escrow funds are securely held (BR-FN-03).
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

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Thanh toán thành công'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Column(
            children: [
              const SizedBox(height: DesignTokens.spaceMd),

              // Success Icon Circle
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF5EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.secondaryPineGreen,
                  size: 68,
                ),
              ),

              const SizedBox(height: DesignTokens.spaceLg),

              Text(
                'Thanh toán thành công!',
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.secondaryPineGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Tiền đã được giữ an toàn trong Escrow',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              ),

              const SizedBox(height: DesignTokens.spaceXl),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceMd),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: AppColors.borderWarm),
                  boxShadow: DesignTokens.cardElevation,
                ),
                child: Column(
                  children: [
                    _buildRow('Mã đơn hàng', orderCode, isBold: true),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildRow('Số tiền thanh toán', VndFormatter.format(amount), isHighlight: true),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Trạng thái đơn hàng', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        StatusPillBadge(status: 'PAID', isCompact: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Trạng thái Ký quỹ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        StatusPillBadge(status: 'APPROVED', isCompact: true), // Escrow held
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: DesignTokens.spaceLg),

              // Escrow Explanation Note
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceMd),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF5EE),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: const Color(0xFFBCE3C6)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.secondaryPineGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tiền của bạn đang được izithrift bảo vệ trung gian và chỉ giải ngân cho Người bán khi bạn xác nhận đã nhận hàng đúng mô tả.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.secondaryPineGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: DesignTokens.spaceXl),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  key: const Key('btn_view_order_detail'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTerracotta,
                    foregroundColor: AppColors.textLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                  ),
                  onPressed: () => context.push(AppRoutes.orderDetailPath(orderId)),
                  child: const Text('Xem chi tiết đơn mua', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  key: const Key('btn_continue_shopping'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textCharcoal,
                    side: const BorderSide(color: AppColors.borderWarm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                  ),
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Tiếp tục mua sắm'),
                ),
              ),

              const SizedBox(height: DesignTokens.spaceMd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? AppColors.primaryTerracotta : AppColors.textCharcoal,
          ),
        ),
      ],
    );
  }
}
