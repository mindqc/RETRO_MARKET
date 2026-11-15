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
      highlightColor: const Color(0xFFFAF7F2),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius ?? DesignTokens.radiusSm),
        ),
      ),
    );
  }
}

/// RetroEmptyStateView displays empty state feedback with vintage thrift typography and styling.
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderWarm, width: 1),
              ),
              child: Icon(icon, size: 48, color: AppColors.primaryTerracotta),
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF8B4B4), width: 1),
              ),
              child: Icon(icon, size: 48, color: AppColors.statusDanger),
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            Text(
              'Đã xảy ra sự cố',
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
