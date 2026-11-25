import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/payment_session_model.dart';

/// M-PM-03: Payment Failure / Expired Screen.
/// Allows the buyer to retry with a new backend-issued payment session.
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
    final reason =
        session?.failureReason ??
        'Phiên thanh toán đã hết hạn hoặc giao dịch không thành công.';
    final retrySession = session?.retrySession;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Thanh toán chưa hoàn tất'),
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
              _buildFailureHero(),
              const SizedBox(height: DesignTokens.spaceLg),
              _buildReasonCard(reason),
              const SizedBox(height: DesignTokens.spaceMd),
              _buildRecoveryNotice(),
              const SizedBox(height: DesignTokens.spaceXl),
              _buildActions(context, retrySession),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailureHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceLg,
        vertical: DesignTokens.spaceXl,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E8),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: const Color(0xFFF0D2C2)),
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDFD1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.primaryTerracotta,
              size: 66,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFC85A32).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
            child: const Text(
              'PAYMENT NOT COMPLETED',
              style: TextStyle(
                color: AppColors.primaryTerracotta,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          Text(
            'Thanh toán chưa thành công',
            textAlign: TextAlign.center,
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.primaryTerracotta,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đơn hàng của bạn vẫn đang chờ thanh toán. Bạn có thể thử lại bằng phiên thanh toán mới.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFF79594A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonCard(String reason) {
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
                Icons.info_outline_rounded,
                color: AppColors.primaryTerracotta,
                size: 21,
              ),
              const SizedBox(width: 8),
              Text('Thông tin giao dịch', style: AppTypography.headingSmall),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3ED),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Text(
              reason,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primaryTerracotta,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5DE),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: const Color(0xFFFFDF9B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFF946200),
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Bạn chưa hoàn tất thanh toán. Hãy sử dụng phiên thanh toán mới nếu có, hoặc quay lại đơn hàng để tiếp tục.',
              style: AppTypography.bodySmall.copyWith(
                color: const Color(0xFF795300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    PaymentSessionModel? retrySession,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            key: const Key('btn_retry_payment'),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(
              retrySession == null
                  ? 'Chưa có phiên thanh toán mới'
                  : 'Tạo mã thanh toán mới',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTerracotta,
              foregroundColor: AppColors.textLight,
              disabledBackgroundColor: AppColors.primaryTerracotta.withValues(
                alpha: 0.4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
            onPressed: () {
              if (retrySession == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Không có phiên thanh toán mới. Vui lòng quay lại đơn hàng để tạo lại phiên.',
                    ),
                  ),
                );
                return;
              }

              context.pushReplacement(
                AppRoutes.paymentQrPath(retrySession.paymentId),
                extra: retrySession,
              );
            },
          ),
        ),
        if (retrySession != null) ...[
          const SizedBox(height: DesignTokens.spaceSm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: AppColors.borderWarm),
            ),
            child: Text(
              'Phiên mới: ${retrySession.paymentCode}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primaryForestGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.spaceSm),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            key: const Key('btn_failure_return_home'),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Về trang chủ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textCharcoal,
              side: const BorderSide(color: AppColors.borderWarm),
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
