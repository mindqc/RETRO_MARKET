import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../utils/vnd_formatter.dart';

/// Price breakdown.
///
/// DEC-04:
/// Buyer Protection Fee = round(itemSubtotal * 6% + 7.000đ)
///
/// When customBuyerProtectionFee is supplied, it is authoritative
/// and must be used instead of the local fallback calculation.
///
/// When customGrandTotalAmount is supplied, it is authoritative
/// for the displayed grand total.
class PriceBreakdownCard extends StatelessWidget {
  final num itemSubtotal;
  final num shippingFee;
  final num? customBuyerProtectionFee;
  final num? customGrandTotalAmount;
  final bool showSellerNetAmount;

  const PriceBreakdownCard({
    super.key,
    required this.itemSubtotal,
    this.shippingFee = 0,
    this.customBuyerProtectionFee,
    this.customGrandTotalAmount,
    this.showSellerNetAmount = false,
  });

  /// DEC-04 fallback calculation.
  static num calculateBuyerProtectionFee(num subtotal) {
    if (subtotal <= 0) return 0;
    return (subtotal * 0.06 + 7000).round();
  }

  num get buyerProtectionFee =>
      customBuyerProtectionFee ?? calculateBuyerProtectionFee(itemSubtotal);

  num get totalAmount =>
      customGrandTotalAmount ?? itemSubtotal + shippingFee + buyerProtectionFee;

  @override
  Widget build(BuildContext context) {
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
          _buildHeader(),
          const SizedBox(height: DesignTokens.spaceMd),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: DesignTokens.spaceMd),

          _buildRow(
            label: 'Tiền hàng',
            value: VndFormatter.format(itemSubtotal),
            icon: Icons.shopping_bag_outlined,
          ),
          const SizedBox(height: 14),

          _buildRow(
            label: 'Phí vận chuyển',
            value: shippingFee == 0
                ? 'Miễn phí'
                : VndFormatter.format(shippingFee),
            valueColor: shippingFee == 0
                ? AppColors.secondaryPineGreen
                : AppColors.textCharcoal,
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 14),

          _buildProtectionFeeRow(),

          if (showSellerNetAmount) ...[
            const SizedBox(height: 14),
            _buildRow(
              label: 'Thực nhận của người bán',
              value: VndFormatter.format(itemSubtotal),
              valueColor: AppColors.secondaryPineGreen,
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],

          const SizedBox(height: DesignTokens.spaceMd),
          const Divider(height: 1, color: AppColors.borderWarm),
          const SizedBox(height: DesignTokens.spaceMd),

          _buildTotal(),

          const SizedBox(height: DesignTokens.spaceMd),
          _buildEscrowNotice(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF6E5D9),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            size: 21,
            color: AppColors.primaryTerracotta,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiết thanh toán',
                style: AppTypography.headingSmall.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Minh bạch từng khoản phí',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F2E8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 13,
                color: AppColors.secondaryPineGreen,
              ),
              const SizedBox(width: 4),
              Text(
                'An toàn',
                style: AppTypography.caption.copyWith(
                  color: AppColors.secondaryPineGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProtectionFeeRow() {
    return _buildRow(
      label: 'Phí bảo vệ người mua',
      value: VndFormatter.format(buyerProtectionFee),
      icon: Icons.shield_outlined,
      tooltip: 'DEC-04: 6% giá trị hàng + 7.000đ phí giao dịch an toàn ký quỹ Escrow.',
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    Color? valueColor,
    IconData? icon,
    String? tooltip,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: AppColors.textMuted),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
              if (tooltip != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: tooltip,
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textCharcoal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: const Color(0xFFF0D4C1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng thanh toán',
                  style: AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Đã bao gồm các khoản phí',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              VndFormatter.format(totalAmount),
              textAlign: TextAlign.end,
              style: AppTypography.priceLarge.copyWith(
                color: AppColors.primaryTerracotta,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2E8),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: const Color(0xFFB9D9BE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_rounded,
            size: 19,
            color: AppColors.secondaryPineGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tiền thanh toán được giữ trung gian tại '
              'Escrow. Người bán chỉ nhận tiền sau khi '
              'đơn hàng hoàn tất theo quy trình của ứng dụng.',
              style: AppTypography.caption.copyWith(
                color: AppColors.secondaryPineGreen,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
