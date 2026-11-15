import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/condition_badge.dart';
import '../../../core/widgets/status_pill_badge.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/seller_product_item_model.dart';
import '../viewmodels/seller_listings_view_model.dart';

/// M-SL-02: Seller Listings Manager Screen
/// Supports 7-state tab navigation, condition badges, rejection inspection (DEC-05),
/// auction relisting (DEC-02), and optimistic visibility toggling.
class SellerListingsScreen extends ConsumerStatefulWidget {
  final String? initialStatus;

  const SellerListingsScreen({super.key, this.initialStatus});

  @override
  ConsumerState<SellerListingsScreen> createState() => _SellerListingsScreenState();
}

class _SellerListingsScreenState extends ConsumerState<SellerListingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<_StatusTabInfo> _tabs = [
    _StatusTabInfo('Tất cả', 'ALL'),
    _StatusTabInfo('Chờ duyệt', 'PENDING_REVIEW'),
    _StatusTabInfo('Đang bán', 'APPROVED'),
    _StatusTabInfo('Bị từ chối', 'REJECTED'),
    _StatusTabInfo('Đã bán', 'SOLD'),
    _StatusTabInfo('Bản nháp', 'DRAFT'),
    _StatusTabInfo('Đã ẩn', 'HIDDEN'),
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialStatus != null) {
      final found = _tabs.indexWhere((t) => t.statusKey == widget.initialStatus);
      if (found != -1) initialIndex = found;
    }

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final status = _tabs[_tabController.index].statusKey;
        ref.read(sellerListingsViewModelProvider).setStatusFilter(status);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialStatus = _tabs[initialIndex].statusKey;
      final vm = ref.read(sellerListingsViewModelProvider);
      vm.setStatusFilter(initialStatus);
      vm.loadProducts(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(sellerListingsViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Quản lý bài đăng'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primaryTerracotta,
          labelColor: AppColors.primaryTerracotta,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tabs.map((tab) => Tab(text: tab.title)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab_create_listing'),
        backgroundColor: AppColors.primaryTerracotta,
        foregroundColor: AppColors.textLight,
        icon: const Icon(Icons.add),
        label: const Text('Đăng bán mới', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => context.push(AppRoutes.sellerCreateListing),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryTerracotta,
          onRefresh: () => ref.read(sellerListingsViewModelProvider).loadProducts(refresh: true),
          child: vm.state.when(
            initial: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
            error: (msg, err) => RetroErrorRetryView(
              errorMessage: msg,
              onRetry: () => ref.read(sellerListingsViewModelProvider).loadProducts(refresh: true),
            ),
            empty: (msg) => RetroEmptyStateView(
              title: 'Chưa có sản phẩm',
              message: msg ?? 'Không có sản phẩm nào trong mục này.',
              icon: Icons.inventory_2_outlined,
              actionLabel: 'Tải lại',
              onAction: () => ref.read(sellerListingsViewModelProvider).loadProducts(refresh: true),
            ),
            success: (items) => _buildProductList(items, vm),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(List<SellerProductItemModel> items, SellerListingsViewModel vm) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: DesignTokens.spaceMd,
        right: DesignTokens.spaceMd,
        top: DesignTokens.spaceMd,
        bottom: 80, // Space for FAB
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.spaceMd),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildProductCard(item, vm);
      },
    );
  }

  Widget _buildProductCard(SellerProductItemModel item, SellerListingsViewModel vm) {
    final isAuction = item.listingType == 'AUCTION';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: item.status == 'REJECTED'
              ? AppColors.statusDanger.withValues(alpha: 0.5)
              : AppColors.borderWarm,
        ),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // If rejected, show top warning strip
          if (item.status == 'REJECTED' && item.rejectionReason != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFFDE8E8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(DesignTokens.radiusMd),
                  topRight: Radius.circular(DesignTokens.radiusMd),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.statusDanger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lý do từ chối: ${item.rejectionReason}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.statusDanger,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  child: Container(
                    width: 88,
                    height: 88,
                    color: AppColors.surfaceWarm,
                    child: item.primaryImageUrl != null && item.primaryImageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.primaryImageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.textMuted,
                            ),
                          )
                        : const Icon(
                            Icons.checkroom_outlined,
                            size: 36,
                            color: Color(0xFF84664C),
                          ),
                  ),
                ),

                const SizedBox(width: DesignTokens.spaceMd),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item.title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textCharcoal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Price & Listing Type
                      Row(
                        children: [
                          Text(
                            VndFormatter.format(item.price),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primaryTerracotta,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isAuction)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE8E8),
                                borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                              ),
                              child: Text(
                                '🔨 Đấu giá',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.statusDanger,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Condition & Status Pills
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          ConditionBadge(condition: item.condition, isCompact: true),
                          StatusPillBadge(status: item.status, isCompact: true),
                          if (!isAuction)
                            Text(
                              'Kho: ${item.availableQuantity}',
                              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderWarm),

          // Contextual Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 8),
            child: _buildContextActions(item, vm),
          ),
        ],
      ),
    );
  }

  Widget _buildContextActions(SellerProductItemModel item, SellerListingsViewModel vm) {
    // 1. REJECTED: Button to inspect reason & resubmit (DEC-05)
    if (item.status == 'REJECTED') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            key: Key('btn_resubmit_${item.id}'),
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Xem lý do & Gửi duyệt lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
            ),
            onPressed: () {
              context.push(
                AppRoutes.sellerEditListingPath(item.id),
                extra: item,
              );
            },
          ),
        ],
      );
    }

    // 2. Can Relist (e.g. Unsold Auction DEC-02)
    if (item.canRelist) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            key: Key('btn_relist_${item.id}'),
            icon: const Icon(Icons.replay, size: 16),
            label: const Text('Tái đăng đấu giá'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryPineGreen,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
            ),
            onPressed: () => _showRelistConfirmDialog(item, vm),
          ),
        ],
      );
    }

    // 3. DRAFT: Edit or Delete
    if (item.status == 'DRAFT') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            key: Key('btn_delete_draft_${item.id}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.statusDanger,
              side: const BorderSide(color: AppColors.statusDanger),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
            ),
            onPressed: () => _confirmDeleteDraft(item.id, vm),
            child: const Text('Xóa nháp', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: Key('btn_edit_draft_${item.id}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTerracotta,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
            ),
            onPressed: () {
              context.push(
                AppRoutes.sellerEditListingPath(item.id),
                extra: item,
              );
            },
            child: const Text('Tiếp tục sửa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    // 4. APPROVED or HIDDEN: Toggle visibility
    if (item.status == 'APPROVED' || item.status == 'HIDDEN') {
      final isApproved = item.status == 'APPROVED';
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            key: Key('btn_toggle_visibility_${item.id}'),
            icon: Icon(isApproved ? Icons.visibility_off : Icons.visibility, size: 16),
            label: Text(isApproved ? 'Ẩn bài' : 'Hiện lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isApproved ? const Color(0xFF84664C) : AppColors.secondaryPineGreen,
              side: BorderSide(
                color: isApproved ? AppColors.borderWarm : AppColors.secondaryPineGreen,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
            ),
            onPressed: () async {
              final ok = await vm.toggleVisibility(item.id, item.status);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? (isApproved ? 'Đã ẩn bài đăng thành công' : 'Đã hiện lại bài đăng')
                        : 'Không thể cập nhật trạng thái bài đăng'),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              context.push(
                AppRoutes.sellerEditListingPath(item.id),
                extra: item,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceWarm,
              foregroundColor: AppColors.textCharcoal,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                side: const BorderSide(color: AppColors.borderWarm),
              ),
            ),
            child: const Text('Chỉnh sửa', style: TextStyle(fontSize: 12)),
          ),
        ],
      );
    }

    // Default for other states (e.g. SOLD, ARCHIVED, PENDING_REVIEW)
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            context.push(
              AppRoutes.sellerEditListingPath(item.id),
              extra: item,
            );
          },
          child: const Text('Xem chi tiết', style: TextStyle(fontSize: 12, color: Color(0xFF84664C))),
        ),
      ],
    );
  }

  void _confirmDeleteDraft(int productId, SellerListingsViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa bản nháp'),
        content: const Text('Bạn có chắc chắn muốn xóa bài đăng nháp này không? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.deleteDraft(productId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Đã xóa bản nháp' : 'Xóa thất bại')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRelistConfirmDialog(SellerProductItemModel item, SellerListingsViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tái đăng đấu giá'),
        content: Text('Bạn có muốn mở lại phiên đấu giá cho sản phẩm "${item.title}" với cấu hình tương tự không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryPineGreen),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.relistProduct(item.id, {
                'starting_price': item.startingPrice ?? item.price,
                'min_bid_increment': item.bidIncrement ?? 10000,
                'duration_hours': 24,
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Đã tái đăng đấu giá thành công' : 'Lỗi khi tái đăng')),
                );
              }
            },
            child: const Text('Tái đăng ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatusTabInfo {
  final String title;
  final String statusKey;

  const _StatusTabInfo(this.title, this.statusKey);
}
