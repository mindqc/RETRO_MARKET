import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../viewmodels/auth_view_model.dart';

/// Represents the destination a guest user attempted to reach before being
/// prompted to sign in, so the app continues seamlessly after authentication.
class PendingNavigationTarget {
  final String route;
  final Object? extra;
  final bool useGo;
  final bool openSellSheet;
  final bool returnToCaller;

  const PendingNavigationTarget({
    required this.route,
    this.extra,
    this.useGo = false,
    this.openSellSheet = false,
    this.returnToCaller = false,
  });
}

/// Holds the pending post-login navigation target across the login flow.
final pendingAuthRedirectProvider =
    StateProvider<PendingNavigationTarget?>((ref) => null);

/// Checks if the current user is authenticated. If not, presents the modern
/// dismissible [AuthLoginBottomSheet] and stores [intendedTarget] so login
/// resumes the originally requested action automatically.
bool requireAuthOrPrompt(
  BuildContext context,
  WidgetRef ref, {
  required String featureTitle,
  required String description,
  required PendingNavigationTarget intendedTarget,
  IconData icon = Icons.lock_outline_rounded,
  String primaryButtonLabel = 'Đăng nhập ngay',
}) {
  final authVm = ref.read(authViewModelProvider);
  if (authVm.isAuthenticated) {
    return true;
  }

  showAuthLoginBottomSheet(
    context,
    ref: ref,
    featureTitle: featureTitle,
    description: description,
    intendedTarget: intendedTarget,
    icon: icon,
    primaryButtonLabel: primaryButtonLabel,
  );
  return false;
}

/// Presents a modern, warm-vintage Login Bottom Sheet when a logged-out user
/// accesses a restricted marketplace feature (Chat, Sell, Auctions, Cart, Checkout).
///
/// Users can dismiss freely using the back arrow, close button, "Để sau", or
/// tapping outside without being forced to log in.
Future<void> showAuthLoginBottomSheet(
  BuildContext context, {
  WidgetRef? ref,
  Ref? providerRef,
  required String featureTitle,
  required String description,
  PendingNavigationTarget? intendedTarget,
  IconData icon = Icons.lock_outline_rounded,
  String primaryButtonLabel = 'Đăng nhập ngay',
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceCard,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.radius2xl),
      ),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with Back arrow & drag handle pill
              Row(
                children: [
                  Material(
                    color: AppColors.canvasParchment,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Quay lại',
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: AppColors.textCharcoal,
                      ),
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderWarm,
                      borderRadius: DesignTokens.borderRadiusFull,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: AppColors.canvasParchment,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Đóng',
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: AppColors.textMuted,
                      ),
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Feature badge + headline
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.categoryCircleStart,
                          AppColors.categoryCircleEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppColors.pineDeep.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.pineDeep,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.creamBadgeSoft,
                            borderRadius: DesignTokens.borderRadiusFull,
                            border: Border.all(
                              color: AppColors.creamBadgeBorder,
                            ),
                          ),
                          child: Text(
                            'Yêu cầu đăng nhập',
                            style: AppTypography.caption.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.creamBadgeText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          featureTitle,
                          style: AppTypography.headingSmall.copyWith(
                            fontSize: 18,
                            color: AppColors.pineDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                description,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),

              // Post-login continuation callout
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.canvasParchment,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderWarm),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 16,
                      color: AppColors.pineDeep,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sau khi đăng nhập, bạn sẽ tiếp tục ngay tại tính năng vừa chọn.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textCharcoal,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Primary Login CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaTerracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.login_rounded, size: 19),
                  label: Text(
                    primaryButtonLabel,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  onPressed: () {
                    if (intendedTarget != null) {
                      if (ref != null) {
                        ref.read(pendingAuthRedirectProvider.notifier).state =
                            intendedTarget;
                      } else if (providerRef != null) {
                        providerRef
                            .read(pendingAuthRedirectProvider.notifier)
                            .state = intendedTarget;
                      }
                    }
                    Navigator.of(sheetCtx).pop();
                    if (context.mounted) {
                      context.push(AppRoutes.login);
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Dismissible Secondary Option
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => Navigator.of(sheetCtx).pop(),
                  child: Text(
                    'Để sau',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
