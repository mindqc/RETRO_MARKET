import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// ConditionBadge displays Vietnamese secondhand condition ratings
/// Maps standard DB codes: NEW_WITH_TAGS, LIKE_NEW, GOOD, FAIR, VINTAGE_WORN
class ConditionBadge extends StatelessWidget {
  final String condition;
  final bool isCompact;

  const ConditionBadge({
    super.key,
    required this.condition,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final styleConfig = _resolveConditionConfig(condition);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: styleConfig.backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        border: Border.all(color: styleConfig.borderColor, width: 1),
      ),
      child: Text(
        styleConfig.label,
        style: (isCompact ? AppTypography.caption : AppTypography.bodySmall).copyWith(
          color: styleConfig.textColor,
          fontWeight: FontWeight.w600,
          fontSize: isCompact ? 10 : 11,
        ),
      ),
    );
  }

  static _ConditionConfig _resolveConditionConfig(String rawCondition) {
    switch (rawCondition.toUpperCase()) {
      case 'NEW_WITH_TAGS':
        return const _ConditionConfig(
          label: 'Mới còn tag',
          backgroundColor: Color(0xFFEBF5EE),
          textColor: AppColors.secondaryPineGreen,
          borderColor: Color(0xFFBCE3C6),
        );
      case 'LIKE_NEW':
        return const _ConditionConfig(
          label: 'Như mới (99%)',
          backgroundColor: Color(0xFFEBF5EE),
          textColor: AppColors.secondaryPineGreen,
          borderColor: Color(0xFFBCE3C6),
        );
      case 'GOOD':
        return const _ConditionConfig(
          label: 'Tốt (90%)',
          backgroundColor: Color(0xFFFFF9E6),
          textColor: Color(0xFFB47800),
          borderColor: Color(0xFFFFE799),
        );
      case 'FAIR':
        return const _ConditionConfig(
          label: 'Khá (80%)',
          backgroundColor: Color(0xFFFDF0EB),
          textColor: AppColors.primaryTerracotta,
          borderColor: Color(0xFFF7CFBE),
        );
      case 'VINTAGE_WORN':
      default:
        return const _ConditionConfig(
          label: 'Dấu ấn vintage',
          backgroundColor: Color(0xFFF4EFE6),
          textColor: Color(0xFF755B49),
          borderColor: AppColors.borderWarm,
        );
    }
  }
}

class _ConditionConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const _ConditionConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}
