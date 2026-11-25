import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/seasonal_decor_provider.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../viewmodels/profile_view_model.dart';

/// M-PF-01: Unified Personal Hub Screen (Tab 5 /profile)
class UnifiedPersonalHubScreen extends ConsumerStatefulWidget {
  const UnifiedPersonalHubScreen({super.key});

  @override
  ConsumerState<UnifiedPersonalHubScreen> createState() =>
      _UnifiedPersonalHubScreenState();
}

class _UnifiedPersonalHubScreenState
    extends ConsumerState<UnifiedPersonalHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authViewModelProvider).isAuthenticated) {
        ref.read(profileViewModelProvider).loadProfileSummary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = ref.watch(authViewModelProvider);
    final profileVm = ref.watch(profileViewModelProvider);
    final isSeasonal = ref.watch(seasonalDecorProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        title: RetroBrandWordmark(
          titleText: 'izithrift • Cá nhân',
          showSeasonalAccent: isSeasonal,
        ),
        actions: [
          RetroHeaderIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Cài đặt',
            onPressed: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RetroAmbientSnowflakes(
        enabled: isSeasonal,
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.ctaTerracotta,
            onRefresh: () async {
              if (authVm.isAuthenticated) {
                await ref.read(profileViewModelProvider).loadProfileSummary();
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              child: authVm.isAuthenticated
                  ? _buildAuthenticatedHub(authVm, profileVm)
                  : _buildGuestPrompt(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestPrompt() {
    return Column(
      children: [
        const SizedBox(height: DesignTokens.spaceXl),
        RetroSectionContainer(
          padding: const EdgeInsets.all(DesignTokens.space2xl),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [
                      AppColors.categoryCircleStart,
                      AppColors.categoryCircleEnd,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.creamBadgeBorder),
                  boxShadow: DesignTokens.cardElevation,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 46,
                  color: AppColors.pineDeep,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              Text(
                'Tham gia cộng đồng izithrift',
                textAlign: TextAlign.center,
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.pineDeep,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(
                'Đăng nhập để theo dõi đơn mua, quản lý tiệm bán đồ vintage và tham gia các phiên đấu giá trực tiếp.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceXl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.login),
                  child: const Text('Đăng nhập / Đăng ký'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedHub(
    AuthViewModel authVm,
    ProfileViewModel profileVm,
  ) {
    final summary = profileVm.profileSummary;
    final user = summary?.user ?? authVm.currentUser!;
    final sellerProfile = user.sellerProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. User Info Header Card
        Container(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: DesignTokens.borderRadiusBanner,
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Row(
            children: [
              _buildAvatar(user.profile?.avatarUrl, user.displayName),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.pineDeep,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.creamBadgeSoft,
                            borderRadius: DesignTokens.borderRadiusFull,
                            border: Border.all(
                              color: AppColors.creamBadgeBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: AppColors.starGold,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Uy tín: ${sellerProfile?.trustScore.toStringAsFixed(0) ?? '100'}%',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.creamBadgeText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const RetroVerifiedShopChip(
                          label: 'Tài khoản hợp nhất',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderWarm),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.pineDeep,
                  ),
                  onPressed: () => context.push(AppRoutes.editProfile),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spaceLg),

        // 2. Seller Mode Switch Banner (NAV-DEC-02) — Deep Pine Spotlight
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(AppRoutes.sellerHub),
            borderRadius: DesignTokens.borderRadiusBanner,
            child: RetroPineSpotlightContainer(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.creamBadgeBg.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.creamBadgeBg.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.creamBadgeBg,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Kênh Người bán izithrift',
                                style: AppTypography.headingSmall.copyWith(
                                  color: AppColors.textLight,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('🛍️'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ví: ${VndFormatter.format(sellerProfile?.walletBalance ?? 0)} • Đang giữ Ký quỹ: ${VndFormatter.format(sellerProfile?.escrowHeldBalance ?? 0)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.creamBadgeBg,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.creamBadgeBg,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: DesignTokens.spaceXl),

        // 3. Order Status Counters
        RetroSectionHeader(
          title: 'Đơn mua của tôi',
          icon: Icons.shopping_bag_outlined,
          iconColor: AppColors.ctaTerracotta,
          actionLabel: 'Xem tất cả',
          onAction: () => context.push(AppRoutes.myOrders),
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.spaceMd,
            horizontal: DesignTokens.spaceXs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: DesignTokens.borderRadiusLg,
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrderStatusItem(
                label: 'Chờ thanh toán',
                count: summary?.pendingPaymentCount ?? 0,
                icon: Icons.payment_outlined,
                onTap: () => context.push(AppRoutes.myOrders),
              ),
              _buildOrderStatusItem(
                label: 'Chờ gửi hàng',
                count:
                    (summary?.paidCount ?? 0) + (summary?.preparingCount ?? 0),
                icon: Icons.inventory_2_outlined,
                onTap: () => context.push(AppRoutes.myOrders),
              ),
              _buildOrderStatusItem(
                label: 'Đang giao',
                count: summary?.shippedCount ?? 0,
                icon: Icons.local_shipping_outlined,
                onTap: () => context.push(AppRoutes.myOrders),
              ),
              _buildOrderStatusItem(
                label: 'Khiếu nại',
                count: summary?.disputedCount ?? 0,
                icon: Icons.report_problem_outlined,
                badgeColor: AppColors.priceCrimson,
                onTap: () => context.push(AppRoutes.myOrders),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spaceXl),

        // 4. Menu Items
        const RetroSectionHeader(
          title: 'Tiện ích & Quản lý',
          icon: Icons.auto_awesome_outlined,
          iconColor: AppColors.starGold,
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        Container(
          decoration: BoxDecoration(
            borderRadius: DesignTokens.borderRadiusLg,
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Material(
            color: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusLg,
              side: const BorderSide(color: AppColors.borderWarm),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.gavel_rounded,
                  title: 'Phiên đấu giá đang tham gia',
                  onTap: () => context.push(AppRoutes.auctions),
                ),
                const Divider(
                  height: 1,
                  indent: 64,
                  color: AppColors.borderSubtle,
                ),
                _buildMenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Sổ địa chỉ nhận hàng',
                  onTap: () => context.push(AppRoutes.addresses),
                ),
                const Divider(
                  height: 1,
                  indent: 64,
                  color: AppColors.borderSubtle,
                ),
                _buildMenuItem(
                  icon: Icons.favorite_border_rounded,
                  title: 'Món đồ đã thích (${summary?.favoritesCount ?? 0})',
                  onTap: () => context.push(AppRoutes.favorites),
                ),
                const Divider(
                  height: 1,
                  indent: 64,
                  color: AppColors.borderSubtle,
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Cài đặt ứng dụng & Giao diện',
                  onTap: () => context.push(AppRoutes.settings),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String? url, String displayName) {
    if (url != null && url.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.creamBadgeBorder, width: 1.5),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => _buildFallbackAvatar(displayName),
          ),
        ),
      );
    }
    return _buildFallbackAvatar(displayName);
  }

  Widget _buildFallbackAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [AppColors.categoryCircleStart, AppColors.categoryCircleEnd],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.creamBadgeBorder, width: 1.5),
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.pineDeep,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatusItem({
    required String label,
    required int count,
    required IconData icon,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: DesignTokens.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              backgroundColor: badgeColor ?? AppColors.priceCrimson,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [
                      AppColors.categoryCircleStart,
                      AppColors.categoryCircleEnd,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.creamBadgeBorder),
                ),
                child: Icon(icon, size: 21, color: AppColors.pineDeep),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textCharcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.creamBadgeSoft,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.creamBadgeBorder),
        ),
        child: Icon(icon, color: AppColors.pineDeep, size: 19),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
