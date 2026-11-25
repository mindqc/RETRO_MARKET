import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo/retro_demo_marketplace_store.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/seasonal_decor_provider.dart';
import '../../../core/utils/product_image_resolver.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/izithrift_global_app_bar.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../../core/widgets/retro_product_image.dart';
import '../../../core/widgets/status_pill_badge.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../seller/models/seller_product_item_model.dart';
import '../viewmodels/profile_view_model.dart';

/// M-PF-01: Unified Personal Hub Screen (Profile Tab: /profile)
///
/// Layout:
/// - Global Upper Navigation (`IzithriftGlobalAppBar`)
/// - Upper Profile Info Card (Avatar, Name, @slug/email, Trust Score, Edit & Settings)
/// - Seller Channel Spotlight + Quick Sell / Create Auction CTA
/// - Marketplace Profile Activity Tabs: `Bài đăng` | `Đang bán` | `Đã bán`
///   (plus transparent Pending / Rejected moderation shortcut pill)
/// - Buyer Order Status Counters & Account Management Utilities
class UnifiedPersonalHubScreen extends ConsumerStatefulWidget {
  const UnifiedPersonalHubScreen({super.key});

  @override
  ConsumerState<UnifiedPersonalHubScreen> createState() =>
      _UnifiedPersonalHubScreenState();
}

class _ProfilePostItem {
  final int productId;
  final String title;
  final String caption;
  final double price;
  final String status;
  final String condition;
  final String categoryName;
  final String? imageUrl;
  final String timestampLabel;

  const _ProfilePostItem({
    required this.productId,
    required this.title,
    required this.caption,
    required this.price,
    required this.status,
    required this.condition,
    required this.categoryName,
    required this.imageUrl,
    required this.timestampLabel,
  });
}

class _UnifiedPersonalHubScreenState
    extends ConsumerState<UnifiedPersonalHubScreen> {
  int _selectedActivityTab = 0; // 0: Bài đăng, 1: Đang bán, 2: Đã bán

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
    final demoStore = ref.watch(retroDemoStoreProvider);
    final isSeasonal = ref.watch(seasonalDecorProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: const IzithriftGlobalAppBar(),
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
                  ? _buildAuthenticatedHub(authVm, profileVm, demoStore)
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
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [
                      AppColors.categoryCircleStart,
                      AppColors.categoryCircleEnd,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderWarm),
                  boxShadow: DesignTokens.cardElevation,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 44,
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
                'Đăng nhập để theo dõi đơn mua, quản lý bài đăng đồ si, xem sản phẩm đang bán/đã bán và tham gia đấu giá trực tiếp.',
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
    RetroDemoMarketplaceStore demoStore,
  ) {
    final summary = profileVm.profileSummary;
    final user = summary?.user ?? authVm.currentUser!;
    final sellerProfile = user.sellerProfile;
    final pendingSubmitted = demoStore.demoSubmittedListings
        .where((e) => e.status.toUpperCase() == 'PENDING_REVIEW')
        .toList();

    final activeItems = _resolveActiveListings(demoStore);
    final soldItems = _resolveSoldListings();
    final posts = _resolveMarketplacePosts(pendingSubmitted, activeItems);

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
          child: Column(
            children: [
              Row(
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
                            fontSize: 17,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sellerProfile?.shopSlug != null &&
                                  sellerProfile!.shopSlug!.isNotEmpty
                              ? '@${sellerProfile.shopSlug} • ${user.email}'
                              : user.email,
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.editProfile),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Chỉnh sửa hồ sơ'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.settings),
                    icon: const Icon(Icons.settings_outlined, size: 17),
                    label: const Text('Cài đặt'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spaceMd),

        // 2. Seller Channel Spotlight Banner (NAV-DEC-02)
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
                    width: 46,
                    height: 46,
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
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kênh Người bán izithrift',
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.textLight,
                            fontSize: 15.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ví: ${VndFormatter.format(sellerProfile?.walletBalance ?? 0)} • Ký quỹ: ${VndFormatter.format(sellerProfile?.escrowHeldBalance ?? 0)}',
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

        const SizedBox(height: DesignTokens.spaceSm + 2),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.sellerCreateListing),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaTerracotta,
                  foregroundColor: AppColors.textLight,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 17),
                label: const Text(
                  'Đăng bán đồ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.sellerCreateAuction),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.pineDeep,
                  backgroundColor: AppColors.surfaceCard,
                  side: const BorderSide(color: AppColors.pineDeep),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.gavel_rounded, size: 17),
                label: const Text(
                  'Tạo đấu giá',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.spaceXl),

        // 3. Marketplace Profile Activity Tabs: Bài đăng | Đang bán | Đã bán
        _buildProfileActivitySection(
          posts: posts,
          activeItems: activeItems,
          soldItems: soldItems,
          pendingCount: pendingSubmitted.length,
        ),

        const SizedBox(height: DesignTokens.spaceXl),

        // 4. Buyer Order Status Counters
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
                badgeColor: AppColors.statusDanger,
                onTap: () => context.push(AppRoutes.myOrders),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spaceXl),

        // 5. Utilities & Management
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
                icon: Icons.pending_actions_rounded,
                title: pendingSubmitted.isNotEmpty
                    ? 'Tin đăng chờ duyệt (${pendingSubmitted.length})'
                    : 'Quản lý tin đăng & trạng thái duyệt',
                onTap: () => context.push(
                  AppRoutes.sellerListingsPath('PENDING_REVIEW'),
                ),
              ),
              const Divider(
                height: 1,
                indent: 64,
                color: AppColors.borderSubtle,
              ),
              _buildMenuItem(
                icon: Icons.gavel_rounded,
                title: 'Phiên đấu giá của tôi',
                onTap: () => context.push(AppRoutes.myAuctions),
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

  // ---------------------------------------------------------------------------
  // Marketplace Profile Activity Tabs (`Bài đăng` | `Đang bán` | `Đã bán`)
  // ---------------------------------------------------------------------------

  List<SellerProductItemModel> _resolveActiveListings(
    RetroDemoMarketplaceStore demoStore,
  ) {
    final approvedFromDemo = demoStore.demoCatalogProducts.take(4).map((p) {
      return SellerProductItemModel(
        id: p.id,
        productCode: 'PRD-${p.id}',
        title: p.title,
        description: 'Đồ secondhand tuyển chọn kỹ lưỡng từ tủ cá nhân.',
        slug: 'item-${p.id}',
        listingType: p.listingType,
        condition: p.condition,
        price: p.price,
        availableQuantity: 1,
        status: 'ACTIVE',
        primaryImageUrl: p.primaryImageUrl,
        categoryName: p.categoryName,
      );
    }).toList();
    return approvedFromDemo;
  }

  List<SellerProductItemModel> _resolveSoldListings() {
    return const [
      SellerProductItemModel(
        id: 9401,
        productCode: 'PRD-SOLD-9401',
        title: 'Áo Len Cổ Lọ Vintage Wool Đỏ Đô',
        description: 'Áo len ấm mùa đông đã giao thành công cho người mua.',
        slug: 'ao-len-co-lo-vintage',
        listingType: 'FIXED_PRICE',
        condition: 'LIKE_NEW',
        price: 290000,
        availableQuantity: 0,
        status: 'SOLD',
        primaryImageUrl: ProductImageResolver.assetKnitCardigan,
        categoryName: 'Áo',
      ),
      SellerProductItemModel(
        id: 9402,
        productCode: 'PRD-SOLD-9402',
        title: 'Đồng Hồ Cơ Vintage Dây Da Nâu Nhật Bản',
        description: 'Đồng hồ cơ lên cót tay hoạt động chuẩn xác.',
        slug: 'dong-ho-co-vintage',
        listingType: 'AUCTION',
        condition: 'GOOD',
        price: 1180000,
        availableQuantity: 0,
        status: 'SOLD',
        primaryImageUrl: ProductImageResolver.assetMechanicalWatch,
        categoryName: 'Phụ kiện',
      ),
    ];
  }

  List<_ProfilePostItem> _resolveMarketplacePosts(
    List<SellerProductItemModel> pendingSubmitted,
    List<SellerProductItemModel> activeItems,
  ) {
    final posts = <_ProfilePostItem>[];

    for (final item in pendingSubmitted) {
      final desc = item.description?.trim() ?? '';
      posts.add(
        _ProfilePostItem(
          productId: item.id,
          title: item.title,
          caption: desc.isNotEmpty
              ? desc
              : 'Vừa gửi bài đăng mới lên izithrift — đang chờ quản trị viên phê duyệt.',
          price: item.price,
          status: item.status,
          condition: item.condition,
          categoryName: item.categoryName ?? 'Đồ si',
          imageUrl: item.primaryImageUrl,
          timestampLabel: 'Vừa gửi • Chờ duyệt',
        ),
      );
    }

    for (var i = 0; i < activeItems.length && i < 3; i++) {
      final item = activeItems[i];
      posts.add(
        _ProfilePostItem(
          productId: item.id,
          title: item.title,
          caption: i == 0
              ? 'Dọn tủ mùa đông pass nhanh món vintage giữ gìn kỹ, mặc lên form cực đẹp 🎄'
              : 'Hàng tuyển 1 chiếc duy nhất — hỗ trợ kiểm hàng & nhắn tin xem ảnh cận chất liệu.',
          price: item.price,
          status: item.status,
          condition: item.condition,
          categoryName: item.categoryName ?? 'Vintage',
          imageUrl: item.primaryImageUrl,
          timestampLabel: i == 0 ? '2 giờ trước' : '${i + 1} ngày trước',
        ),
      );
    }

    return posts;
  }

  Widget _buildProfileActivitySection({
    required List<_ProfilePostItem> posts,
    required List<SellerProductItemModel> activeItems,
    required List<SellerProductItemModel> soldItems,
    required int pendingCount,
  }) {
    final tabLabels = [
      'Bài đăng (${posts.length})',
      'Đang bán (${activeItems.length})',
      'Đã bán (${soldItems.length})',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RetroSectionHeader(
          title: 'Hoạt động gian hàng',
          subtitle: 'Bài đăng, món đồ đang bán & lịch sử đã bán',
          icon: Icons.storefront_outlined,
          iconColor: AppColors.pineDeep,
          actionLabel: 'Quản lý',
          onAction: () => context.push(AppRoutes.sellerListings),
        ),
        const SizedBox(height: 10),

        // Moderation status shortcut banner when user has pending listings
        if (pendingCount > 0) ...[
          InkWell(
            onTap: () => context.push(
              AppRoutes.sellerListingsPath('PENDING_REVIEW'),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.creamBadgeSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.creamBadgeBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    size: 18,
                    color: AppColors.statusWarning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn có $pendingCount bài đăng đang chờ duyệt. Chạm để xem trạng thái.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.creamBadgeText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.creamBadgeText,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Segmented Activity Tab Selector
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: DesignTokens.borderRadiusFull,
            border: Border.all(color: AppColors.borderWarm),
          ),
          child: Row(
            children: List.generate(tabLabels.length, (index) {
              final selected = _selectedActivityTab == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedActivityTab = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.pineDeep : Colors.transparent,
                      borderRadius: DesignTokens.borderRadiusFull,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tabLabels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),

        // Active Tab Body
        if (_selectedActivityTab == 0) _buildPostsList(posts),
        if (_selectedActivityTab == 1)
          _buildProfileProductGrid(activeItems, isSold: false),
        if (_selectedActivityTab == 2)
          _buildProfileProductGrid(soldItems, isSold: true),
      ],
    );
  }

  Widget _buildPostsList(List<_ProfilePostItem> posts) {
    if (posts.isEmpty) {
      return _buildEmptyActivityCard(
        icon: Icons.article_outlined,
        title: 'Chưa có bài đăng nào',
        subtitle: 'Bấm nút "+" Đăng bán ở thanh dưới để đăng món đồ đầu tiên!',
      );
    }

    return Column(
      children: posts.map((post) {
        final isPending = post.status.toUpperCase() == 'PENDING_REVIEW';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: DesignTokens.borderRadiusLg,
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: InkWell(
            borderRadius: DesignTokens.borderRadiusLg,
            onTap: () {
              if (isPending) {
                context.push(AppRoutes.sellerListingsPath('PENDING_REVIEW'));
              } else {
                context.push(AppRoutes.productDetailPath(post.productId));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: RetroProductImage(
                      imageUrl: post.imageUrl,
                      title: post.title,
                      categoryName: post.categoryName,
                      width: 78,
                      height: 86,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusPillBadge(status: post.status),
                            const Spacer(),
                            Text(
                              post.timestampLabel,
                              style: AppTypography.caption.copyWith(
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          post.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelStrong.copyWith(
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          post.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.32,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              VndFormatter.format(post.price),
                              style: AppTypography.priceSmall.copyWith(
                                color: AppColors.ctaTerracotta,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Độ mới ${ProductImageResolver.conditionPercentLabel(post.condition)}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.pineDeep,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfileProductGrid(
    List<SellerProductItemModel> items, {
    required bool isSold,
  }) {
    if (items.isEmpty) {
      return _buildEmptyActivityCard(
        icon: isSold ? Icons.inventory_2_outlined : Icons.sell_outlined,
        title: isSold ? 'Chưa có sản phẩm đã bán' : 'Chưa có sản phẩm đang bán',
        subtitle: isSold
            ? 'Những món đồ bạn giao dịch thành công sẽ lưu tại đây.'
            : 'Đăng bán món đồ secondhand để xuất hiện tại gian hàng của bạn.',
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.66,
        crossAxisSpacing: 11,
        mainAxisSpacing: 11,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: AppColors.surfaceCard,
          borderRadius: DesignTokens.borderRadiusLg,
          child: InkWell(
            borderRadius: DesignTokens.borderRadiusLg,
            onTap: () => context.push(AppRoutes.productDetailPath(item.id)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: DesignTokens.borderRadiusLg,
                border: Border.all(color: AppColors.borderWarm),
                boxShadow: DesignTokens.cardElevation,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColorFiltered(
                          colorFilter: isSold
                              ? const ColorFilter.mode(
                                  Color(0x55231F20),
                                  BlendMode.darken,
                                )
                              : const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.dst,
                                ),
                          child: RetroProductImage(
                            imageUrl: item.primaryImageUrl,
                            title: item.title,
                            categoryName: item.categoryName,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isSold
                                  ? AppColors.textCharcoal
                                  : AppColors.pineDeep,
                              borderRadius: DesignTokens.borderRadiusFull,
                            ),
                            child: Text(
                              isSold ? 'Đã bán' : 'Đang bán',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontBody,
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (!isSold)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.creamBadgeBg,
                                borderRadius: DesignTokens.borderRadiusFull,
                              ),
                              child: Text(
                                ProductImageResolver.conditionPercentLabel(
                                  item.condition,
                                ),
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontBody,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.creamBadgeText,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: isSold
                                ? AppColors.textMuted
                                : AppColors.textCharcoal,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                VndFormatter.format(item.price),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.priceSmall.copyWith(
                                  color: isSold
                                      ? AppColors.textMuted
                                      : AppColors.ctaTerracotta,
                                  decoration: isSold
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (item.categoryName != null)
                              Text(
                                item.categoryName!,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10.5,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyActivityCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.labelStrong.copyWith(
              color: AppColors.textCharcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, String displayName) {
    if (url != null && url.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.starGold, width: 1.5),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            width: 58,
            height: 58,
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
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [
            AppColors.categoryCircleStart,
            AppColors.categoryCircleEnd,
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.pineDeep.withValues(alpha: 0.25)),
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
              backgroundColor: badgeColor ?? AppColors.ctaTerracotta,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryForestGreenLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderWarm),
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
          color: AppColors.primaryForestGreenLight,
          shape: BoxShape.circle,
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
