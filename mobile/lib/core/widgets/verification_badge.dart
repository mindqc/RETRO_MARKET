import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// VerificationBadge displays the authentication/verification status of secondhand items
/// Maps to: HIGH_VALUE_VERIFIED, MODERATOR_REVIEWED, EVIDENCE_PROVIDED (BASIC_CHECKED), UNVERIFIED (NONE)
class VerificationBadge extends StatelessWidget {
  final String status;
  final bool showLabel;
  final bool isCompact;

  const VerificationBadge({
    super.key,
    required this.status,
    this.showLabel = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig(status);

    if (!showLabel) {
      return Tooltip(
        message: config.label,
        child: Icon(
          config.icon,
          size: isCompact ? 15 : 18,
          color: config.iconColor,
        ),
      );
    }

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: isCompact ? 12.5 : 14.5,
            color: config.iconColor,
          ),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: (isCompact ? AppTypography.caption : AppTypography.bodySmall)
                .copyWith(
              color: config.textColor,
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 10.5 : 11.5,
            ),
          ),
        ],
      ),
    );
  }

  static _VerificationConfig _resolveConfig(String rawStatus) {
    switch (rawStatus.toUpperCase()) {
      case 'HIGH_VALUE_VERIFIED':
        return const _VerificationConfig(
          label: 'Xác minh giá trị cao',
          icon: Icons.verified_user,
          iconColor: AppColors.starGold,
          backgroundColor: AppColors.creamBadgeSoft,
          textColor: AppColors.creamBadgeText,
          borderColor: AppColors.creamBadgeBorder,
        );
      case 'MODERATOR_REVIEWED':
        return const _VerificationConfig(
          label: 'Đã kiểm duyệt',
          icon: Icons.verified,
          iconColor: AppColors.verifiedLeaf,
          backgroundColor: AppColors.verifiedLeafBg,
          textColor: AppColors.verifiedLeaf,
          borderColor: Color(0xFFB7DEC4),
        );
      case 'EVIDENCE_PROVIDED':
      case 'BASIC_CHECKED':
        return const _VerificationConfig(
          label: 'Có chứng từ gốc',
          icon: Icons.assignment_turned_in_outlined,
          iconColor: AppColors.pineDeep,
          backgroundColor: Color(0xFFE7F2F8),
          textColor: AppColors.pineDeep,
          borderColor: Color(0xFFB5D8EB),
        );
      case 'NONE':
      case 'UNVERIFIED':
      default:
        return const _VerificationConfig(
          label: 'Chưa kiểm định',
          icon: Icons.help_outline_rounded,
          iconColor: AppColors.textMuted,
          backgroundColor: AppColors.surfaceWarm,
          textColor: AppColors.textMuted,
          borderColor: AppColors.borderWarm,
        );
    }
  }
}

class _VerificationConfig {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const _VerificationConfig({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}
