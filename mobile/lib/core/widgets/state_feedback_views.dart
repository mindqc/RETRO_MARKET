import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// RetroShimmerBox renders a warm skeleton shimmer box for placeholder loading states.
class RetroShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double? radius;

  const RetroShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceWarm,
      highlightColor: AppColors.surfaceCard,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(radius ?? DesignTokens.radiusMd),
        ),
      ),
    );
  }
}

/// RetroEmptyStateView displays empty state feedback with warm vintage editorial styling.
class RetroEmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const RetroEmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inventory_2_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space2xl),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spaceXl),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: DesignTokens.borderRadiusBanner,
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [
                      AppColors.categoryCircleStart,
                      AppColors.categoryCircleEnd,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.creamBadgeBorder,
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 42, color: AppColors.pineDeep),
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headingMedium.copyWith(fontSize: 18),
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: DesignTokens.spaceLg),
                ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// RetroErrorRetryView displays network or server error states with a retry action button.
class RetroErrorRetryView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final IconData icon;

  const RetroErrorRetryView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    this.icon = Icons.wifi_off_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space2xl),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spaceXl),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: DesignTokens.borderRadiusBanner,
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.priceCrimsonSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.priceCrimsonBorder,
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 40, color: AppColors.priceCrimson),
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              Text(
                'Đã xảy ra sự cố',
                style: AppTypography.headingMedium.copyWith(fontSize: 18),
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaTerracotta,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
