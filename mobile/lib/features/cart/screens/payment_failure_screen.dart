import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/payment_session_model.dart';

/// M-PM-03: Payment Failure / Expired Screen
/// Displays failure reason and allows the buyer to retry payment or return home.
class PaymentFailureScreen extends StatelessWidget {
  final int paymentId;
  final PaymentSessionModel? session;

  const PaymentFailureScreen({
    super.key,
    required this.paymentId,
    this.session,
  });

  @override
  Widget build(BuildContext context) {
    final reason = session?.failureReason ?? 'Phiên thanh toán đã hết hạn hoặc giao dịch không thành công.';

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Thanh toán chưa hoàn tất'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Column(
            children: [
              const SizedBox(height: DesignTokens.spaceMd),

              // Failure Icon Circle
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.statusDanger,
                  size: 68,
                ),
              ),

              const SizedBox(height: DesignTokens.spaceLg),

              Text(
                'Thanh toán chưa thành công',
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.statusDanger,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Đơn hàng của bạn vẫn đang ở trạng thái Chờ thanh toán.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: DesignTokens.spaceXl),

              // Reason Box
              Container(
                width: double.infinity,
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
                    const Text(
                      'Chi tiết thông báo:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textCharcoal),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reason,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.statusDanger),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: DesignTokens.spaceXl),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  key: const Key('btn_retry_payment'),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Thử thanh toán lại / Tạo mã mới', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTerracotta,
                    foregroundColor: AppColors.textLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                  ),
                  onPressed: () {
                    context.pushReplacement(
                      AppRoutes.paymentQrPath(paymentId),
                      extra: session,
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  key: const Key('btn_failure_return_home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textCharcoal,
                    side: const BorderSide(color: AppColors.borderWarm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                  ),
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Về trang chủ'),
                ),
              ),

              const SizedBox(height: DesignTokens.spaceMd),
            ],
          ),
        ),
      ),
    );
  }
}
