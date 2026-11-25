import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/retro_design_primitives.dart';
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
      backgroundColor: AppColors.canvasParchment,
      body: RetroAmbientSnowflakes(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space2xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [
                        AppColors.categoryCircleStart,
                        AppColors.categoryCircleEnd,
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.creamBadgeBorder, width: 1.5),
                    boxShadow: DesignTokens.cardElevation,
                  ),
                  child: const Icon(
                    Icons.checkroom_rounded,
                    size: 52,
                    color: AppColors.pineDeep,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceLg),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'izithrift',
                      style: AppTypography.brandWordmark.copyWith(
                        color: AppColors.pineDeep,
                        fontSize: 38,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: AppColors.starGold,
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.creamBadgeSoft,
                    borderRadius: DesignTokens.borderRadiusFull,
                    border: Border.all(color: AppColors.creamBadgeBorder),
                  ),
                  child: Text(
                    'Kho đồ secondhand & vintage tuyển chọn',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.creamBadgeText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.space2xl),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.ctaTerracotta),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
