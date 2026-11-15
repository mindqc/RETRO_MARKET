import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../viewmodels/auth_view_model.dart';

/// M-AU-02: Onboarding Walkthrough (3 Slides)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      title: 'Kho đồ vintage tuyển chọn',
      description:
          'Hàng ngàn món đồ secondhand độc bản, phong cách hoài cổ được kiểm duyệt kỹ càng và minh bạch tình trạng.',
      icon: Icons.local_mall_outlined,
    ),
    _OnboardingSlide(
      title: 'Đấu giá công bằng Anti-Sniping',
      description:
          'Sàn đấu giá trực tiếp minh bạch. Tự động gia hạn khi có trả giá trong 2 phút cuối, ngăn chặn đầu cơ phút chót.',
      icon: Icons.gavel_outlined,
    ),
    _OnboardingSlide(
      title: 'Bảo vệ người mua 100% qua Escrow',
      description:
          'Tiền thanh toán được giữ an toàn tại tài khoản Ký quỹ Escrow cho đến khi bạn nhận hàng và xác nhận hài lòng.',
      icon: Icons.shield_outlined,
    ),
  ];

  Future<void> _completeOnboarding(String destination) async {
    await ref.read(authViewModelProvider).setHasSeenOnboarding(true);
    if (!mounted) return;
    context.go(destination);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => _completeOnboarding(AppRoutes.home),
            child: Text(
              'Bỏ qua',
              style: AppTypography.buttonMedium.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space2xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(DesignTokens.space2xl),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWarm,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderWarm, width: 2),
                            boxShadow: DesignTokens.cardElevation,
                          ),
                          child: Icon(
                            slide.icon,
                            size: 72,
                            color: AppColors.primaryTerracotta,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space2xl),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: AppTypography.headingLarge,
                        ),
                        const SizedBox(height: DesignTokens.spaceMd),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primaryTerracotta
                        : AppColors.borderWarm,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                ),
              ),
            ),

            const SizedBox(height: DesignTokens.space2xl),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _completeOnboarding(AppRoutes.login),
                      child: const Text('Đăng nhập / Đăng ký'),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _completeOnboarding(AppRoutes.home),
                      child: const Text('Khám phá ngay (Guest)'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceLg),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;

  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
  });
}
