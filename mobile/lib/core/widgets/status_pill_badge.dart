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
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Text(
        config.label,
        style: (isCompact ? AppTypography.caption : AppTypography.bodySmall)
            .copyWith(
              color: config.textColor,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 10 : 11,
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
          Color(0xFFF0EAE1),
          AppColors.textMuted,
          AppColors.borderWarm,
        );
      case 'PENDING_APPROVAL':
      case 'PENDING_REVIEW':
        return const _StatusConfig(
          'Chờ duyệt',
          Color(0xFFFFF9E6),
          Color(0xFFB47800),
          Color(0xFFFFE799),
        );
      case 'APPROVED':
        return const _StatusConfig(
          'Đã duyệt',
          Color(0xFFEBF5EE),
          AppColors.secondaryPineGreen,
          Color(0xFFBCE3C6),
        );
      case 'HIDDEN':
        return const _StatusConfig(
          'Đã ẩn',
          Color(0xFFF0EAE1),
          AppColors.textMuted,
          AppColors.borderWarm,
        );
      case 'REJECTED':
        return const _StatusConfig(
          'Bị từ chối',
          Color(0xFFFDE8E8),
          AppColors.statusDanger,
          Color(0xFFF8B4B4),
        );
      case 'SUSPENDED':
        return const _StatusConfig(
          'Tạm ngưng',
          Color(0xFFFDF0EB),
          AppColors.primaryTerracotta,
          Color(0xFFF7CFBE),
        );
      case 'SOLD':
        return const _StatusConfig(
          'Đã bán',
          Color(0xFFEDE7F6),
          Color(0xFF5E35B1),
          Color(0xFFD1C4E9),
        );
      case 'ARCHIVED':
        return const _StatusConfig(
          'Đã lưu trữ',
          Color(0xFFF0EAE1),
          AppColors.textMuted,
          AppColors.borderWarm,
        );

      // Auction States
      case 'SCHEDULED':
        return const _StatusConfig(
          'Sắp diễn ra',
          Color(0xFFE3F2FD),
          Color(0xFF0277BD),
          Color(0xFF90CAF9),
        );
      case 'LIVE':
        return const _StatusConfig(
          'Đang đấu giá',
          Color(0xFFFDE8E8),
          AppColors.christmasBerryRed,
          Color(0xFFF8B4B4),
        );
      case 'ENDED_PENDING_PAYMENT':
        return const _StatusConfig(
          'Chờ thanh toán',
          Color(0xFFFFF9E6),
          Color(0xFFB47800),
          Color(0xFFFFE799),
        );
      case 'ENDED_UNSOLD':
        return const _StatusConfig(
          'Không có người mua',
          Color(0xFFF0EAE1),
          AppColors.textMuted,
          AppColors.borderWarm,
        );
      case 'WINNER_DEFAULTED':
        return const _StatusConfig(
          'Người thắng bỏ cọc',
          Color(0xFFFDE8E8),
          AppColors.statusDanger,
          Color(0xFFF8B4B4),
        );

      // Order States
      case 'PENDING_PAYMENT':
        return const _StatusConfig(
          'Chờ thanh toán',
          Color(0xFFFFF9E6),
          Color(0xFFB47800),
          Color(0xFFFFE799),
        );
      case 'PAID':
        return const _StatusConfig(
          'Đã thanh toán',
          Color(0xFFEBF5EE),
          AppColors.secondaryPineGreen,
          Color(0xFFBCE3C6),
        );
      case 'HELD':
      case 'ESCROW_HELD':
        return const _StatusConfig(
          'Đang giữ ký quỹ',
          Color(0xFFEBF5EE),
          AppColors.secondaryPineGreen,
          Color(0xFFBCE3C6),
        );
      case 'PREPARING':
        return const _StatusConfig(
          'Đang chuẩn bị',
          Color(0xFFE3F2FD),
          Color(0xFF0277BD),
          Color(0xFF90CAF9),
        );
      case 'SHIPPED':
        return const _StatusConfig(
          'Đang giao hàng',
          Color(0xFFE1F5FE),
          Color(0xFF0288D1),
          Color(0xFF81D4FA),
        );
      case 'DELIVERED':
        return const _StatusConfig(
          'Đã giao hàng',
          Color(0xFFE8F5E9),
          Color(0xFF2E7D32),
          Color(0xFFA5D6A7),
        );
      case 'COMPLETED':
        return const _StatusConfig(
          'Đã hoàn thành',
          Color(0xFFE8F5E9),
          AppColors.statusSuccess,
          Color(0xFFA5D6A7),
        );
      case 'CANCELLED':
        return const _StatusConfig(
          'Đã hủy',
          Color(0xFFF0EAE1),
          AppColors.textMuted,
          AppColors.borderWarm,
        );
      case 'DISPUTED':
        return const _StatusConfig(
          'Đang khiếu nại',
          Color(0xFFFDE8E8),
          AppColors.statusDanger,
          Color(0xFFF8B4B4),
        );

      default:
        return _StatusConfig(
          rawStatus,
          const Color(0xFFF0EAE1),
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
