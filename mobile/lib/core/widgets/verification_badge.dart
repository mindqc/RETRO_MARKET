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
          size: isCompact ? 14 : 18,
          color: config.iconColor,
        ),
      );
    }

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: isCompact ? 12 : 14,
            color: config.iconColor,
          ),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: (isCompact ? AppTypography.caption : AppTypography.bodySmall).copyWith(
              color: config.textColor,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 10 : 11,
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
          iconColor: AppColors.accentVintageGold,
          backgroundColor: Color(0xFFFFFBEB),
          textColor: Color(0xFF946200),
          borderColor: Color(0xFFFFE082),
        );
      case 'MODERATOR_REVIEWED':
        return const _VerificationConfig(
          label: 'Đã kiểm duyệt',
          icon: Icons.verified,
          iconColor: AppColors.secondaryPineGreen,
          backgroundColor: Color(0xFFEBF5EE),
          textColor: AppColors.secondaryPineGreen,
          borderColor: Color(0xFFBCE3C6),
        );
      case 'EVIDENCE_PROVIDED':
      case 'BASIC_CHECKED':
        return const _VerificationConfig(
          label: 'Có chứng từ gốc',
          icon: Icons.assignment_turned_in_outlined,
          iconColor: AppColors.statusInfo,
          backgroundColor: Color(0xFFE3F2FD),
          textColor: Color(0xFF0277BD),
          borderColor: Color(0xFF90CAF9),
        );
      case 'NONE':
      case 'UNVERIFIED':
      default:
        return const _VerificationConfig(
          label: 'Chưa kiểm định',
          icon: Icons.help_outline,
          iconColor: AppColors.textMuted,
          backgroundColor: Color(0xFFF4EFE6),
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
