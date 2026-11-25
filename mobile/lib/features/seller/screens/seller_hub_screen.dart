import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/seller_dashboard_model.dart';
import '../viewmodels/seller_hub_view_model.dart';

/// M-SL-01: Seller Channel Hub Screen
/// Displays seller shop profile, wallet balance overview, action counters, and navigation links.
class SellerHubScreen extends ConsumerStatefulWidget {
  const SellerHubScreen({super.key});

  @override
  ConsumerState<SellerHubScreen> createState() => _SellerHubScreenState();
}

class _SellerHubScreenState extends ConsumerState<SellerHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sellerHubViewModelProvider).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(sellerHubViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Kênh Người Bán',
          style: AppTypography.headingMedium.copyWith(fontSize: 20),
        ),
        actions: [
          RetroHeaderIconButton(
            icon: Icons.history_edu_outlined,
            tooltip: 'Sổ cái ví',
            onPressed: () => context.push(AppRoutes.sellerWallet),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ctaTerracotta,
          onRefresh: () => ref.read(sellerHubViewModelProvider).refresh(),
          child: vm.state.when(
            initial: () => const Center(
              child: CircularProgressIndicator(color: AppColors.pineDeep),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.pineDeep),
            ),
            error: (msg, err) => RetroErrorRetryView(
              errorMessage: msg,
              onRetry: () =>
                  ref.read(sellerHubViewModelProvider).loadDashboard(),
            ),
            empty: (msg) => RetroEmptyStateView(
              title: 'Chưa có thông tin',
              message: msg ?? 'Không có thông tin bảng điều khiển.',
              icon: Icons.storefront_outlined,
              actionLabel: 'Tải lại',
              onAction: () =>
                  ref.read(sellerHubViewModelProvider).loadDashboard(),
            ),
            success: (data) => _buildHubContent(data),
          ),
        ),
      ),
    );
  }

  Widget _buildHubContent(SellerDashboardModel data) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // 1. Shop Info Banner
        _buildShopInfoCard(data),
        const SizedBox(height: 14),

        // 2. Deep Pine Spotlight Wallet Card
        _buildWalletCard(data),
        const SizedBox(height: 16),

        // 3. Prominent Stadium CTA: Đăng bán sản phẩm mới
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            key: const Key('btn_create_new_listing'),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
            label: const Text(
              '+ ĐĂNG BÁN SẢN PHẨM MỚI',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctaTerracotta,
              foregroundColor: AppColors.textLight,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            onPressed: () => context.push(AppRoutes.sellerCreateListing),
          ),
        ),
        const SizedBox(height: 22),

        // 4. Action Needed Grid
        const RetroSectionHeader(
          title: 'Việc cần xử lý',
          subtitle: 'Đơn hàng, yêu cầu hủy và kiểm duyệt cần chú ý',
          icon: Icons.bolt_rounded,
          iconColor: AppColors.ctaTerracotta,
        ),
        const SizedBox(height: 12),
        _buildActionCountersGrid(data),
        const SizedBox(height: 22),

        // 5. Listings Overview
        RetroSectionHeader(
          title: 'Quản lý bài đăng đồ si',
          subtitle: 'Tổng quan kho sản phẩm đang hoạt động',
          icon: Icons.checkroom_outlined,
          iconColor: AppColors.pineDeep,
          actionLabel: 'Xem tất cả',
          onAction: () => context.push(AppRoutes.sellerListings),
        ),
        const SizedBox(height: 12),
        _buildListingsOverviewGrid(data),
        const SizedBox(height: 22),

        // 6. Quick Management Menu
        const RetroSectionHeader(
          title: 'Lối tắt quản lý',
          icon: Icons.dashboard_customize_outlined,
          iconColor: AppColors.starGold,
        ),
        const SizedBox(height: 12),
        _buildQuickMenu(data),
      ],
    );
  }

  Widget _buildShopInfoCard(SellerDashboardModel data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusBanner,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  AppColors.categoryCircleStart,
                  AppColors.categoryCircleEnd,
                ],
              ),
              border: Border.all(color: AppColors.creamBadgeBorder, width: 1.5),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 27,
              color: AppColors.pineDeep,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.shopName,
                  style: AppTypography.headingMedium.copyWith(fontSize: 17.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.starGold,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${data.averageRating.toStringAsFixed(1)} (${data.reviewCount} đánh giá)',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.verifiedLeafBg,
                        borderRadius: DesignTokens.borderRadiusFull,
                      ),
                      child: Text(
                        'Điểm uy tín: ${data.trustScore.toStringAsFixed(0)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.verifiedLeaf,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(SellerDashboardModel data) {
    return RetroPineSpotlightContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.creamBadgeBg.withValues(alpha: 0.16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.creamBadgeBg,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Số dư ví Tiệm',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.creamBadgeBg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton(
                key: const Key('btn_open_wallet_ledger'),
                onPressed: () => context.push(AppRoutes.sellerWallet),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.creamBadgeBg,
                  side: BorderSide(
                    color: AppColors.creamBadgeBg.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Chi tiết sổ cái',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            VndFormatter.format(data.walletBalance),
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textLight,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: DesignTokens.borderRadiusMd,
              border: Border.all(
                color: AppColors.creamBadgeBg.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_clock_outlined,
                      size: 16,
                      color: AppColors.creamBadgeBg,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ký quỹ đang giữ (Escrow):',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textLight.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
                Text(
                  VndFormatter.format(data.escrowHeldBalance),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.creamBadgeBg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCountersGrid(SellerDashboardModel data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildCounterTile(
              width: cardWidth,
              title: 'Chờ giao hàng',
              count: data.paidOrdersCount,
              icon: Icons.local_shipping_outlined,
              iconColor: AppColors.ctaTerracotta,
              onTap: () => context.push(AppRoutes.sellerOrders),
            ),
            _buildCounterTile(
              width: cardWidth,
              title: 'Yêu cầu hủy',
              count: data.preparingOrdersCount,
              icon: Icons.cancel_schedule_send_outlined,
              iconColor: AppColors.primaryVintageBrown,
              onTap: () => context.push(AppRoutes.sellerOrders),
            ),
            _buildCounterTile(
              width: cardWidth,
              title: 'Khiếu nại đang mở',
              count: data.disputedOrdersCount,
              icon: Icons.gavel_outlined,
              iconColor: AppColors.starGold,
              onTap: () => context.push(AppRoutes.sellerOrders),
            ),
            _buildCounterTile(
              width: cardWidth,
              title: 'Bị từ chối kiểm duyệt',
              count: data.rejectedProductsCount,
              icon: Icons.error_outline_rounded,
              iconColor: AppColors.priceCrimson,
              isAlert: data.rejectedProductsCount > 0,
              onTap: () => context.push(AppRoutes.sellerListings),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListingsOverviewGrid(SellerDashboardModel data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 20) / 3;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMiniListingStatusTile(
              width: cardWidth,
              title: 'Chờ duyệt',
              count: data.pendingReviewCount,
              color: AppColors.starGold,
              onTap: () => context.push(AppRoutes.sellerListings),
            ),
            _buildMiniListingStatusTile(
              width: cardWidth,
              title: 'Đang bán',
              count: data.activeProductsCount,
              color: AppColors.verifiedLeaf,
              onTap: () => context.push(AppRoutes.sellerListings),
            ),
            _buildMiniListingStatusTile(
              width: cardWidth,
              title: 'Đã bán',
              count: data.soldProductsCount,
              color: AppColors.primaryVintageBrown,
              onTap: () => context.push(AppRoutes.sellerListings),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCounterTile({
    required double width,
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
    bool isAlert = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: isAlert ? AppColors.priceCrimsonSoft : AppColors.surfaceCard,
      borderRadius: DesignTokens.borderRadiusLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: DesignTokens.borderRadiusLg,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: DesignTokens.borderRadiusLg,
            border: Border.all(
              color: isAlert
                  ? AppColors.priceCrimsonBorder
                  : AppColors.borderWarm,
            ),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAlert
                          ? AppColors.surfaceCard
                          : AppColors.surfaceWarm,
                      border: Border.all(
                        color: isAlert
                            ? AppColors.priceCrimsonBorder
                            : AppColors.borderWarm,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 19,
                      color: isAlert ? AppColors.priceCrimson : iconColor,
                    ),
                  ),
                  Text(
                    '$count',
                    style: AppTypography.headingMedium.copyWith(
                      color: isAlert
                          ? AppColors.priceCrimson
                          : AppColors.textCharcoal,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: isAlert
                      ? AppColors.priceCrimson
                      : AppColors.textCharcoal,
                  fontWeight: isAlert ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniListingStatusTile({
    required double width,
    required String title,
    required int count,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: DesignTokens.borderRadiusLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: DesignTokens.borderRadiusLg,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: DesignTokens.borderRadiusLg,
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: AppTypography.headingMedium.copyWith(
                  color: color,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMenu(SellerDashboardModel data) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: DesignTokens.borderRadiusBanner,
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Material(
        color: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusBanner,
          side: const BorderSide(color: AppColors.borderWarm),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildQuickMenuTile(
              icon: Icons.inventory_2_outlined,
              title: 'Quản lý kho đồ đăng bán',
              subtitle:
                  'Xem bài đăng theo 7 trạng thái, ẩn/hiện hoặc gửi duyệt lại',
              onTap: () => context.push(AppRoutes.sellerListings),
            ),
            const Divider(height: 1, indent: 64, color: AppColors.borderSubtle),
            _buildQuickMenuTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Sổ cái ví & Giao dịch ký quỹ',
              subtitle: 'Lịch sử biến động số dư, đối soát giao dịch bán hàng',
              onTap: () => context.push(AppRoutes.sellerWallet),
            ),
            const Divider(height: 1, indent: 64, color: AppColors.borderSubtle),
            _buildQuickMenuTile(
              icon: Icons.storefront_outlined,
              title: 'Xem cửa hàng công khai',
              subtitle: 'Trải nghiệm trang tiệm từ góc nhìn người mua đồ si',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Đang hiển thị chế độ xem thử cửa hàng công khai',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              AppColors.categoryCircleStart,
              AppColors.categoryCircleEnd,
            ],
          ),
          border: Border.all(color: AppColors.creamBadgeBorder),
        ),
        child: Icon(icon, color: AppColors.pineDeep, size: 19),
      ),
      title: Text(
        title,
        style: AppTypography.labelStrong.copyWith(fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
