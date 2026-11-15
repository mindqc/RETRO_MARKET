import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../viewmodels/profile_view_model.dart';

/// M-PF-01: Unified Personal Hub Screen (Tab 5 /profile)
class UnifiedPersonalHubScreen extends ConsumerStatefulWidget {
  const UnifiedPersonalHubScreen({super.key});

  @override
  ConsumerState<UnifiedPersonalHubScreen> createState() => _UnifiedPersonalHubScreenState();
}

class _UnifiedPersonalHubScreenState extends ConsumerState<UnifiedPersonalHubScreen> {
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

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('izithrift • Cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryTerracotta,
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
    );
  }

  Widget _buildGuestPrompt() {
    return Column(
      children: [
        const SizedBox(height: DesignTokens.space2xl),
        Container(
          padding: const EdgeInsets.all(DesignTokens.space2xl),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWarm,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, size: 56, color: AppColors.primaryTerracotta),
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              Text(
                'Tham gia cộng đồng izithrift',
                textAlign: TextAlign.center,
                style: AppTypography.headingLarge,
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(
                'Đăng nhập để theo dõi đơn mua, quản lý tiệm bán đồ vintage và tham gia các phiên đấu giá trực tiếp.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
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

  Widget _buildAuthenticatedHub(AuthViewModel authVm, ProfileViewModel profileVm) {
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
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
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
                      style: AppTypography.headingSmall,
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                            border: Border.all(color: const Color(0xFFFFE799)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: Color(0xFFB47800)),
                              const SizedBox(width: 3),
                              Text(
                                'Uy tín: ${sellerProfile?.trustScore.toStringAsFixed(0) ?? '100'}%',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB47800),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textMuted),
                onPressed: () => context.push(AppRoutes.editProfile),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spaceLg),

        // 2. Seller Mode Switch Banner (NAV-DEC-02)
        InkWell(
          onTap: () => context.push(AppRoutes.sellerHub),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF294638), Color(0xFF1E352A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              boxShadow: DesignTokens.cardElevation,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceSm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront, color: AppColors.textLight, size: 24),
                ),
                const SizedBox(width: DesignTokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Kênh Người bán izithrift',
                            style: AppTypography.headingSmall.copyWith(
                              color: AppColors.textLight,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('🛍️'),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ví: ${VndFormatter.format(sellerProfile?.walletBalance ?? 0)} • Đang giữ Ký quỹ: ${VndFormatter.format(sellerProfile?.escrowHeldBalance ?? 0)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textLight.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppColors.textLight, size: 14),
              ],
            ),
          ),
        ),

        const SizedBox(height: DesignTokens.spaceXl),

        // 3. Order Status Counters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Đơn mua của tôi', style: AppTypography.headingSmall),
            TextButton(
              onPressed: () => context.push(AppRoutes.myOrders),
              child: Text(
                'Xem tất cả',
                style: AppTypography.caption.copyWith(color: AppColors.primaryTerracotta, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        Container(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: AppColors.borderWarm),
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
                count: (summary?.paidCount ?? 0) + (summary?.preparingCount ?? 0),
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
                badgeColor: AppColors.statusDanger,
                onTap: () => context.push(AppRoutes.myOrders),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spaceXl),

        // 4. Menu Items
        Text('Tiện ích & Quản lý', style: AppTypography.headingSmall),
        const SizedBox(height: DesignTokens.spaceSm),
        Material(
          color: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            side: const BorderSide(color: AppColors.borderWarm),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.gavel_outlined,
                title: 'Phiên đấu giá đang tham gia',
                onTap: () => context.push(AppRoutes.auctions),
              ),
              const Divider(height: 1, indent: 56),
              _buildMenuItem(
                icon: Icons.location_on_outlined,
                title: 'Sổ địa chỉ nhận hàng',
                onTap: () => context.push(AppRoutes.addresses),
              ),
              const Divider(height: 1, indent: 56),
              _buildMenuItem(
                icon: Icons.favorite_border,
                title: 'Món đồ đã thích (${summary?.favoritesCount ?? 0})',
                onTap: () => context.push(AppRoutes.favorites),
              ),
              const Divider(height: 1, indent: 56),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'Cài đặt ứng dụng & Giao diện',
                onTap: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String? url, String displayName) {
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _buildFallbackAvatar(displayName),
        ),
      );
    }
    return _buildFallbackAvatar(displayName);
  }

  Widget _buildFallbackAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.primaryTerracotta.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryTerracotta, width: 1.5),
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTypography.headingMedium.copyWith(color: AppColors.primaryTerracotta),
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
      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              backgroundColor: badgeColor ?? AppColors.primaryTerracotta,
              child: Icon(icon, size: 24, color: AppColors.textCharcoal),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(fontSize: 11),
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
      leading: Icon(icon, color: AppColors.primaryTerracotta, size: 22),
      title: Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
