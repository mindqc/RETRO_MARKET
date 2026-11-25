import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/retro_design_primitives.dart';
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
      eyebrow: 'THRIFT & COZY',
      title: 'Kho đồ vintage tuyển chọn',
      description:
          'Hàng ngàn món đồ secondhand độc bản, phong cách hoài cổ được kiểm duyệt kỹ càng và minh bạch tình trạng.',
      icon: Icons.local_mall_outlined,
      accentColor: AppColors.pineDeep,
    ),
    _OnboardingSlide(
      eyebrow: 'ĐẤU GIÁ MINH BẠCH',
      title: 'Đấu giá công bằng Anti-Sniping',
      description:
          'Sàn đấu giá trực tiếp minh bạch. Tự động gia hạn khi có trả giá trong 2 phút cuối, ngăn chặn đầu cơ phút chót.',
      icon: Icons.gavel_rounded,
      accentColor: AppColors.ctaTerracotta,
    ),
    _OnboardingSlide(
      eyebrow: 'AN TÂM KÝ QUỸ',
      title: 'Bảo vệ người mua 100% qua Escrow',
      description:
          'Tiền thanh toán được giữ an toàn tại tài khoản Ký quỹ Escrow cho đến khi bạn nhận hàng và xác nhận hài lòng.',
      icon: Icons.verified_user_outlined,
      accentColor: AppColors.verifiedLeaf,
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
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        title: const RetroBrandWordmark(titleText: 'izithrift'),
        actions: [
          TextButton(
            onPressed: () => _completeOnboarding(AppRoutes.home),
            child: Text(
              'Bỏ qua',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
      body: RetroAmbientSnowflakes(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight < 620;
              final outerPaddingV =
                  isCompact ? DesignTokens.spaceSm : DesignTokens.spaceMd;
              final cardPaddingV =
                  isCompact ? DesignTokens.spaceLg : DesignTokens.space2xl;
              final slideGap =
                  isCompact ? DesignTokens.spaceMd : DesignTokens.spaceXl;
              final circleSize = isCompact ? 96.0 : 132.0;
              final iconSize = isCompact ? 46.0 : 62.0;

              return Column(
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
                        return Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: DesignTokens.spaceLg,
                              vertical: outerPaddingV,
                            ),
                            child: RetroSectionContainer(
                              padding: EdgeInsets.symmetric(
                                horizontal: DesignTokens.spaceXl,
                                vertical: cardPaddingV,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.creamBadgeBg,
                                      borderRadius: DesignTokens.borderRadiusFull,
                                      border: Border.all(
                                        color: AppColors.creamBadgeBorder,
                                      ),
                                    ),
                                    child: Text(
                                      slide.eyebrow,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.creamBadgeText,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.7,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: slideGap),
                                  Container(
                                    width: circleSize,
                                    height: circleSize,
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
                                        width: 1.5,
                                      ),
                                      boxShadow: DesignTokens.cardElevation,
                                    ),
                                    child: Icon(
                                      slide.icon,
                                      size: iconSize,
                                      color: slide.accentColor,
                                    ),
                                  ),
                                  SizedBox(height: slideGap),
                                  Text(
                                    slide.title,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.headingLarge.copyWith(
                                      color: AppColors.pineDeep,
                                    ),
                                  ),
                                  const SizedBox(height: DesignTokens.spaceSm),
                                  Text(
                                    slide.description,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textMuted,
                                      height: 1.55,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.ctaTerracotta
                              : AppColors.borderWarm,
                          borderRadius: DesignTokens.borderRadiusFull,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: slideGap),

                  // Bottom Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceLg,
                    ),
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
                  SizedBox(
                    height: isCompact
                        ? DesignTokens.spaceMd
                        : DesignTokens.spaceLg,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const _OnboardingSlide({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });
}
