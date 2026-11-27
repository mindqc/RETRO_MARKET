import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/izithrift_logo.dart';
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
                const IzithriftLogo.stacked(
                  iconSize: 92,
                  fontSize: 36,
                  showTagline: true,
                  tagline: 'Kho đồ secondhand & vintage tuyển chọn',
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
