import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// ConditionBadge displays Vietnamese secondhand condition ratings
/// Styled in the warm cream-gold pill language from the approved Home Page reference.
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
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: styleConfig.backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(color: styleConfig.borderColor, width: 0.9),
      ),
      child: Text(
        styleConfig.label,
        style: (isCompact ? AppTypography.caption : AppTypography.bodySmall)
            .copyWith(
              color: styleConfig.textColor,
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 10 : 11,
              height: 1.15,
            ),
      ),
    );
  }

  static _ConditionConfig _resolveConditionConfig(String rawCondition) {
    switch (rawCondition.toUpperCase()) {
      case 'NEW_WITH_TAGS':
        return const _ConditionConfig(
          label: 'Mới còn tag',
          backgroundColor: AppColors.primaryForestGreenLight,
          textColor: AppColors.pineDeep,
          borderColor: Color(0xFFBBD6C2),
        );
      case 'LIKE_NEW':
        return const _ConditionConfig(
          label: 'Như mới (99%)',
          backgroundColor: AppColors.creamBadgeBg,
          textColor: AppColors.creamBadgeText,
          borderColor: AppColors.creamBadgeBorder,
        );
      case 'GOOD':
        return const _ConditionConfig(
          label: 'Tốt (90%)',
          backgroundColor: AppColors.creamBadgeSoft,
          textColor: AppColors.creamBadgeText,
          borderColor: AppColors.creamBadgeBorder,
        );
      case 'FAIR':
        return const _ConditionConfig(
          label: 'Khá (80%)',
          backgroundColor: Color(0xFFF9E6DC),
          textColor: AppColors.ctaTerracotta,
          borderColor: Color(0xFFEBC8B6),
        );
      case 'VINTAGE_WORN':
      default:
        return const _ConditionConfig(
          label: 'Dấu ấn vintage',
          backgroundColor: AppColors.creamBadgeBg,
          textColor: Color(0xFF5A432C),
          borderColor: AppColors.creamBadgeBorder,
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
