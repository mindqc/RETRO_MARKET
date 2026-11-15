import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Kênh Người Bán'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu_outlined),
            tooltip: 'Sổ cái ví',
            onPressed: () => context.push(AppRoutes.sellerWallet),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryTerracotta,
          onRefresh: () => ref.read(sellerHubViewModelProvider).refresh(),
          child: vm.state.when(
            initial: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
            error: (msg, err) => RetroErrorRetryView(
              errorMessage: msg,
              onRetry: () => ref.read(sellerHubViewModelProvider).loadDashboard(),
            ),
            empty: (msg) => RetroEmptyStateView(
              title: 'Chưa có thông tin',
              message: msg ?? 'Không có thông tin bảng điều khiển.',
              icon: Icons.storefront_outlined,
              actionLabel: 'Tải lại',
              onAction: () => ref.read(sellerHubViewModelProvider).loadDashboard(),
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
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      children: [
        // 1. Shop Info Banner
        _buildShopInfoCard(data),

        const SizedBox(height: DesignTokens.spaceLg),

        // 2. Wallet Card (Forest green gradient)
        _buildWalletCard(data),

        const SizedBox(height: DesignTokens.spaceXl),

        // 3. Prominent CTA Button: Đăng bán sản phẩm mới
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            key: const Key('btn_create_new_listing'),
            icon: const Icon(Icons.add_circle_outline, size: 22),
            label: const Text(
              '+ ĐĂNG BÁN SẢN PHẨM MỚI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTerracotta,
              foregroundColor: AppColors.textLight,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
            onPressed: () => context.push(AppRoutes.sellerCreateListing),
          ),
        ),

        const SizedBox(height: DesignTokens.spaceXl),

        // 4. Action Needed Grid
        _buildSectionTitle('Việc cần xử lý'),
        const SizedBox(height: DesignTokens.spaceSm),
        _buildActionCountersGrid(data),

        const SizedBox(height: DesignTokens.spaceXl),

        // 5. Listings Overview
        _buildSectionTitle('Quản lý bài đăng đồ si', onSeeAll: () => context.push(AppRoutes.sellerListings)),
        const SizedBox(height: DesignTokens.spaceSm),
        _buildListingsOverviewGrid(data),

        const SizedBox(height: DesignTokens.spaceXl),

        // 6. Quick Management Menu
        _buildSectionTitle('Lối tắt quản lý'),
        const SizedBox(height: DesignTokens.spaceSm),
        _buildQuickMenu(data),

        const SizedBox(height: DesignTokens.space2xl),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.headingSmall.copyWith(
            color: AppColors.textCharcoal,
            fontSize: 17,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Xem tất cả',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primaryTerracotta,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.primaryTerracotta),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildShopInfoCard(SellerDashboardModel data) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surfaceWarm,
            child: Icon(Icons.storefront, size: 30, color: AppColors.secondaryPineGreen),
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.shopName,
                  style: AppTypography.headingMedium.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Color(0xFFC5A66B)),
                    const SizedBox(width: 4),
                    Text(
                      '${data.averageRating.toStringAsFixed(1)} (${data.reviewCount} đánh giá)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                        border: Border.all(color: AppColors.borderWarm),
                      ),
                      child: Text(
                        'Điểm uy tín: ${data.trustScore.toStringAsFixed(0)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.secondaryPineGreen,
                          fontWeight: FontWeight.bold,
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
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF294638), Color(0xFF1E352A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: AppColors.textLight, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Số dư ví Tiệm',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textLight.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                key: const Key('btn_open_wallet_ledger'),
                onPressed: () => context.push(AppRoutes.sellerWallet),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textLight,
                  side: const BorderSide(color: AppColors.borderWarm),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                ),
                child: const Text('Chi tiết sổ cái', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            VndFormatter.format(data.walletBalance),
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textLight,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white24, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_clock, size: 16, color: Color(0xFFC5A66B)),
                  const SizedBox(width: 6),
                  Text(
                    'Ký quỹ đang giữ (Escrow):',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textLight.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              Text(
                VndFormatter.format(data.escrowHeldBalance),
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFFC5A66B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCountersGrid(SellerDashboardModel data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - DesignTokens.spaceMd) / 2;
        return Wrap(
          spacing: DesignTokens.spaceMd,
          runSpacing: DesignTokens.spaceMd,
          children: [
            _buildCounterTile(
              width: cardWidth,
              title: 'Chờ giao hàng',
              count: data.paidOrdersCount,
              icon: Icons.local_shipping_outlined,
              iconColor: AppColors.primaryTerracotta,
              onTap: () => context.push(AppRoutes.sellerOrders),
            ),
            _buildCounterTile(
              width: cardWidth,
              title: 'Yêu cầu hủy',
              count: data.preparingOrdersCount,
              icon: Icons.cancel_schedule_send_outlined,
              iconColor: const Color(0xFF84664C),
              onTap: () => context.push(AppRoutes.sellerOrders),
            ),
            _buildCounterTile(
              width: cardWidth,
              title: 'Khiếu nại đang mở',
              count: data.disputedOrdersCount,
              icon: Icons.gavel_outlined,
              iconColor: const Color(0xFFB47800),
              onTap: () => context.push(AppRoutes.sellerOrders),
            ),
            _buildCounterTile(
              width: cardWidth,
              title: 'Bị từ chối kiểm duyệt',
              count: data.rejectedProductsCount,
              icon: Icons.error_outline,
              iconColor: AppColors.statusDanger,
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
        final cardWidth = (constraints.maxWidth - DesignTokens.spaceMd * 2) / 3;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMiniListingStatusTile(
              width: cardWidth,
              title: 'Chờ duyệt',
              count: data.pendingReviewCount,
              color: const Color(0xFFB47800),
              onTap: () => context.push(AppRoutes.sellerListings),
            ),
            _buildMiniListingStatusTile(
              width: cardWidth,
              title: 'Đang bán',
              count: data.activeProductsCount,
              color: AppColors.secondaryPineGreen,
              onTap: () => context.push(AppRoutes.sellerListings),
            ),
            _buildMiniListingStatusTile(
              width: cardWidth,
              title: 'Đã bán',
              count: data.soldProductsCount,
              color: const Color(0xFF84664C),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        decoration: BoxDecoration(
          color: isAlert ? const Color(0xFFFFF0F0) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
            color: isAlert ? AppColors.statusDanger : AppColors.borderWarm,
          ),
          boxShadow: DesignTokens.cardElevation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 24, color: isAlert ? AppColors.statusDanger : iconColor),
                Text(
                  '$count',
                  style: AppTypography.headingMedium.copyWith(
                    color: isAlert ? AppColors.statusDanger : AppColors.textCharcoal,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                color: isAlert ? AppColors.statusDanger : AppColors.textMuted,
                fontWeight: isAlert ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: AppColors.borderWarm),
          boxShadow: DesignTokens.cardElevation,
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: AppTypography.headingMedium.copyWith(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenu(SellerDashboardModel data) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: AppColors.borderWarm),
          boxShadow: DesignTokens.cardElevation,
        ),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined, color: AppColors.secondaryPineGreen),
              title: const Text('Quản lý kho đồ đăng bán', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Xem bài đăng theo 7 trạng thái, ẩn/hiện hoặc gửi duyệt lại'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.sellerListings),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFC5A66B)),
              title: const Text('Sổ cái ví & Giao dịch ký quỹ', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Lịch sử biến động số dư, đối soát giao dịch bán hàng'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.sellerWallet),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.storefront_outlined, color: Color(0xFF84664C)),
              title: const Text('Xem cửa hàng công khai', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Trải nghiệm trang tiệm từ góc nhìn người mua đồ si'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đang hiển thị chế độ xem thử cửa hàng công khai')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
