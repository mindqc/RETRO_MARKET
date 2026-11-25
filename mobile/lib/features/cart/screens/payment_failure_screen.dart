import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/payment_session_model.dart';

/// M-PM-03: Payment Failure / Expired Screen.
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
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        title: const Text('Thanh toán chưa hoàn tất'),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: AppColors.canvasParchment,
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
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusBanner,
        border: Border.all(color: AppColors.priceCrimsonBorder),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: AppColors.priceCrimsonSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.priceCrimson,
              size: 56,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.priceCrimsonSoft,
              borderRadius: DesignTokens.borderRadiusFull,
              border: Border.all(color: AppColors.priceCrimsonBorder),
            ),
            child: const Text(
              'PAYMENT NOT COMPLETED',
              style: TextStyle(
                color: AppColors.priceCrimson,
                fontSize: 10.5,
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
              color: AppColors.priceCrimson,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đơn hàng của bạn vẫn đang chờ thanh toán. Bạn có thể thử lại bằng phiên thanh toán mới.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
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
        borderRadius: DesignTokens.borderRadiusBanner,
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
                color: AppColors.priceCrimson,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Thông tin giao dịch',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.pineDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            decoration: BoxDecoration(
              color: AppColors.priceCrimsonSoft,
              borderRadius: DesignTokens.borderRadiusMd,
              border: Border.all(color: AppColors.priceCrimsonBorder),
            ),
            child: Text(
              reason,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.priceCrimson,
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
        color: AppColors.creamBadgeSoft,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(color: AppColors.creamBadgeBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.creamBadgeText,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Bạn chưa hoàn tất thanh toán. Hãy sử dụng phiên thanh toán mới nếu có, hoặc quay lại đơn hàng để tiếp tục.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.creamBadgeText,
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
              backgroundColor: AppColors.ctaTerracotta,
              foregroundColor: AppColors.textLight,
              disabledBackgroundColor:
                  AppColors.ctaTerracotta.withValues(alpha: 0.4),
              shape: const StadiumBorder(),
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
              color: AppColors.verifiedLeafBg,
              borderRadius: DesignTokens.borderRadiusMd,
              border: Border.all(
                color: AppColors.verifiedLeaf.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Phiên mới: ${retrySession.paymentCode}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.pineDeep,
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
              foregroundColor: AppColors.pineDeep,
              side: const BorderSide(color: AppColors.pineDeep),
              shape: const StadiumBorder(),
            ),
            onPressed: () => context.go(AppRoutes.home),
          ),
        ),
      ],
    );
  }
}
