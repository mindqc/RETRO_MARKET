import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../utils/vnd_formatter.dart';

/// PriceBreakdownCard calculates and displays detailed order financial breakdown
/// Enforces Decision DEC-04: Buyer Protection Fee = round(itemSubtotal * 6% + 7.000đ)
/// Features 100% Escrow refund guarantee notice and optional seller net amount display.
class PriceBreakdownCard extends StatelessWidget {
  final num itemSubtotal;
  final num shippingFee;
  final num? customBuyerProtectionFee;
  final bool showSellerNetAmount;

  const PriceBreakdownCard({
    super.key,
    required this.itemSubtotal,
    this.shippingFee = 0,
    this.customBuyerProtectionFee,
    this.showSellerNetAmount = false,
  });

  /// Computes Buyer Protection Fee per DEC-04
  static num calculateBuyerProtectionFee(num subtotal) {
    if (subtotal <= 0) return 0;
    return (subtotal * 0.06 + 7000).round();
  }

  num get buyerProtectionFee =>
      customBuyerProtectionFee ?? calculateBuyerProtectionFee(itemSubtotal);

  num get totalAmount => itemSubtotal + shippingFee + buyerProtectionFee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm, width: DesignTokens.borderThin),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 20, color: AppColors.primaryTerracotta),
              const SizedBox(width: DesignTokens.spaceSm),
              Text(
                'Chi tiết thanh toán',
                style: AppTypography.headingSmall.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: DesignTokens.spaceMd),

          // 1. Tiền hàng
          _buildRow('Tiền hàng', VndFormatter.format(itemSubtotal)),
          const SizedBox(height: DesignTokens.spaceSm),

          // 2. Phí vận chuyển
          _buildRow(
            'Phí vận chuyển',
            shippingFee == 0 ? 'Miễn phí' : VndFormatter.format(shippingFee),
            valueColor: shippingFee == 0 ? AppColors.secondaryPineGreen : AppColors.textCharcoal,
          ),
          const SizedBox(height: DesignTokens.spaceSm),

          // 3. Phí bảo vệ người mua (DEC-04)
          _buildRow(
            'Phí bảo vệ người mua (DEC-04)',
            VndFormatter.format(buyerProtectionFee),
            tooltip: '6% giá trị hàng + 7.000đ phí giao dịch an toàn ký quỹ Escrow',
          ),

          if (showSellerNetAmount) ...[
            const SizedBox(height: DesignTokens.spaceSm),
            _buildRow(
              'Thực nhận của người bán',
              VndFormatter.format(itemSubtotal),
              valueColor: AppColors.secondaryPineGreen,
              tooltip: '0% chiết khấu đơn bán – Người bán nhận trọn 100% tiền hàng sau khi đơn hoàn tất',
            ),
          ],

          const SizedBox(height: DesignTokens.spaceMd),
          const Divider(height: 1, color: AppColors.borderWarm),
          const SizedBox(height: DesignTokens.spaceMd),

          // Tổng thanh toán
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng thanh toán', style: AppTypography.headingSmall),
              Text(
                VndFormatter.format(totalAmount),
                style: AppTypography.priceLarge,
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.spaceMd),

          // Escrow protection guarantee box
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceMd,
              vertical: DesignTokens.spaceSm,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5EE),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              border: Border.all(color: const Color(0xFFBCE3C6), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 18, color: AppColors.secondaryPineGreen),
                const SizedBox(width: DesignTokens.spaceSm),
                Expanded(
                  child: Text(
                    'Bảo vệ người mua 100% – Tiền được giữ an toàn tại tài khoản Ký quỹ Escrow cho đến khi bạn xác nhận hài lòng.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondaryPineGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    Color? valueColor,
    String? tooltip,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
            if (tooltip != null) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: tooltip,
                child: const Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textCharcoal,
          ),
        ),
      ],
    );
  }
}
