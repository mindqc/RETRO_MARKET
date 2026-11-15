import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// DefectAuthenticityBox displays secondhand defect disclosures (BR-PR-03)
/// and moderation rejection reasons (DEC-05).
class DefectAuthenticityBox extends StatelessWidget {
  final String? defectInfo;
  final String? rejectionReason;

  const DefectAuthenticityBox({
    super.key,
    this.defectInfo,
    this.rejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    final hasDefect = defectInfo != null && defectInfo!.trim().isNotEmpty;
    final hasRejection = rejectionReason != null && rejectionReason!.trim().isNotEmpty;

    if (!hasDefect && !hasRejection) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasRejection) ...[
          _buildAlert(
            title: 'Lý do từ chối duyệt (DEC-05)',
            description: rejectionReason!,
            icon: Icons.cancel_outlined,
            backgroundColor: const Color(0xFFFDE8E8),
            borderColor: const Color(0xFFF8B4B4),
            primaryColor: AppColors.statusDanger,
          ),
          if (hasDefect) const SizedBox(height: DesignTokens.spaceMd),
        ],
        if (hasDefect)
          _buildAlert(
            title: 'Lưu ý khuyết tật & hao mòn vintage (BR-PR-03)',
            description: defectInfo!,
            icon: Icons.info_outline,
            backgroundColor: const Color(0xFFFFF9E6),
            borderColor: const Color(0xFFFFE799),
            primaryColor: const Color(0xFFB47800),
          ),
      ],
    );
  }

  Widget _buildAlert({
    required String title,
    required String description,
    required IconData icon,
    required Color backgroundColor,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: DesignTokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textCharcoal,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
