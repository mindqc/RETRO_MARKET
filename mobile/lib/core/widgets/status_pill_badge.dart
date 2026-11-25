import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// StatusPillBadge renders standardized status labels across Product, Auction, and Order states.
class StatusPillBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const StatusPillBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _resolveStatus(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: DesignTokens.borderRadiusFull,
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Text(
        config.label,
        style: (isCompact ? AppTypography.caption : AppTypography.bodySmall)
            .copyWith(
          color: config.textColor,
          fontWeight: FontWeight.w700,
          fontSize: isCompact ? 10.5 : 11.5,
        ),
      ),
    );
  }

  static _StatusConfig _resolveStatus(String rawStatus) {
    switch (rawStatus.toUpperCase()) {
      // Product States
      case 'DRAFT':
        return const _StatusConfig(
          'Bản nháp',
          AppColors.surfaceWarm,
          AppColors.textMuted,
          AppColors.borderWarm,
        );
      case 'PENDING_APPROVAL':
      case 'PENDING_REVIEW':
        return const _StatusConfig(
          'Đang chờ duyệt',
          AppColors.creamBadgeSoft,
          AppColors.creamBadgeText,
          AppColors.creamBadgeBorder,
        );
      case 'APPROVED':
        return const _StatusConfig(
          'Đã duyệt',
          AppColors.verifiedLeafBg,
          AppColors.verifiedLeaf,
          Color(0xFFB7DEC4),
        );
      case 'HIDDEN':
        return const _StatusConfig(
          'Đã ẩn',
          AppColors.surfaceWarm,
          AppColors.textMuted,
          AppColors.borderWarm,
        );
      case 'REJECTED':
        return const _StatusConfig(
          'Bị từ chối',
          AppColors.priceCrimsonSoft,
          AppColors.priceCrimson,
          AppColors.priceCrimsonBorder,
        );
      case 'SUSPENDED':
        return const _StatusConfig(
          'Tạm ngưng',
          AppColors.priceCrimsonSoft,
          AppColors.ctaTerracotta,
          AppColors.priceCrimsonBorder,
        );
      case 'SOLD':
        return const _StatusConfig(
          'Đã bán',
          AppColors.creamBadgeBg,
          AppColors.pineDeep,
          AppColors.creamBadgeBorder,
        );
      case 'ARCHIVED':
        return const _StatusConfig(
          'Đã lưu trữ',
          AppColors.surfaceWarm,
          AppColors.textMuted,
          AppColors.borderWarm,
        );

      // Auction States
      case 'SCHEDULED':
        return const _StatusConfig(
          'Sắp diễn ra',
          AppColors.creamBadgeSoft,
          AppColors.pineDeep,
          AppColors.creamBadgeBorder,
        );
      case 'LIVE':
        return const _StatusConfig(
          'Đang đấu giá',
          AppColors.priceCrimsonSoft,
          AppColors.priceCrimson,
          AppColors.priceCrimsonBorder,
        );
      case 'ENDED_PENDING_PAYMENT':
        return const _StatusConfig(
          'Chờ thanh toán',
          AppColors.creamBadgeSoft,
          AppColors.creamBadgeText,
          AppColors.creamBadgeBorder,
        );
      case 'ENDED_UNSOLD':
        return const _StatusConfig(
          'Không có người mua',
          AppColors.surfaceWarm,
          AppColors.textMuted,
          AppColors.borderWarm,
        );
      case 'WINNER_DEFAULTED':
        return const _StatusConfig(
          'Người thắng bỏ cọc',
          AppColors.priceCrimsonSoft,
          AppColors.priceCrimson,
          AppColors.priceCrimsonBorder,
        );

      // Order States
      case 'PENDING_PAYMENT':
        return const _StatusConfig(
          'Chờ thanh toán',
          AppColors.creamBadgeSoft,
          AppColors.creamBadgeText,
          AppColors.creamBadgeBorder,
        );
      case 'PAID':
        return const _StatusConfig(
          'Đã thanh toán',
          AppColors.verifiedLeafBg,
          AppColors.verifiedLeaf,
          Color(0xFFB7DEC4),
        );
      case 'HELD':
      case 'ESCROW_HELD':
        return const _StatusConfig(
          'Đang giữ ký quỹ',
          AppColors.verifiedLeafBg,
          AppColors.pineDeep,
          Color(0xFFB7DEC4),
        );
      case 'PREPARING':
        return const _StatusConfig(
          'Đang chuẩn bị',
          AppColors.creamBadgeSoft,
          AppColors.primaryVintageBrown,
          AppColors.creamBadgeBorder,
        );
      case 'SHIPPED':
        return const _StatusConfig(
          'Đang giao hàng',
          Color(0xFFE7F2F8),
          Color(0xFF0E6390),
          Color(0xFFB5D8EB),
        );
      case 'DELIVERED':
        return const _StatusConfig(
          'Đã giao hàng',
          AppColors.verifiedLeafBg,
          AppColors.verifiedLeaf,
          Color(0xFFB7DEC4),
        );
      case 'COMPLETED':
        return const _StatusConfig(
          'Đã hoàn thành',
          AppColors.verifiedLeafBg,
          AppColors.verifiedLeaf,
          Color(0xFFB7DEC4),
        );
      case 'CANCELLED':
        return const _StatusConfig(
          'Đã hủy',
          AppColors.surfaceWarm,
          AppColors.textMuted,
          AppColors.borderWarm,
        );
      case 'DISPUTED':
        return const _StatusConfig(
          'Đang khiếu nại',
          AppColors.priceCrimsonSoft,
          AppColors.priceCrimson,
          AppColors.priceCrimsonBorder,
        );

      default:
        return _StatusConfig(
          rawStatus,
          AppColors.surfaceWarm,
          AppColors.textMuted,
          AppColors.borderWarm,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const _StatusConfig(
    this.label,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  );
}
