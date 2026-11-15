import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../viewmodels/auth_view_model.dart';

/// M-AU-01: Splash Screen & Bootstrap Initializer
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final authVm = ref.read(authViewModelProvider);
    await authVm.initializeBootstrap();

    if (!mounted) return;

    if (authVm.isAuthenticated) {
      context.go(AppRoutes.home);
    } else if (!authVm.hasSeenOnboarding) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderWarm, width: 2),
                boxShadow: DesignTokens.cardElevation,
              ),
              child: const Icon(
                Icons.checkroom,
                size: 56,
                color: AppColors.primaryTerracotta,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            Text(
              'izithrift',
              style: AppTypography.displayLarge.copyWith(
                color: AppColors.primaryTerracotta,
                fontSize: 36,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(
              'Kho đồ secondhand & vintage tuyển chọn',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.space2xl),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTerracotta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
