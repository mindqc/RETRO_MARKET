import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/condition_badge.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../../core/widgets/status_pill_badge.dart';
import '../models/seller_product_item_model.dart';
import '../viewmodels/seller_listings_view_model.dart';

/// M-SL-02: Seller Listings Manager Screen
/// Supports 7-state tab navigation, condition badges, rejection inspection (DEC-05),
/// auction relisting (DEC-02), and optimistic visibility toggling.
class SellerListingsScreen extends ConsumerStatefulWidget {
  final String? initialStatus;

  const SellerListingsScreen({super.key, this.initialStatus});

  @override
  ConsumerState<SellerListingsScreen> createState() =>
      _SellerListingsScreenState();
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
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Quản lý bài đăng',
          style: AppTypography.headingMedium.copyWith(fontSize: 20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderWarm)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.priceCrimson,
              indicatorWeight: 2.5,
              labelColor: AppColors.priceCrimson,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: AppTypography.labelStrong.copyWith(fontSize: 13),
              unselectedLabelStyle: AppTypography.bodySmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: _tabs.map((tab) => Tab(text: tab.title)).toList(),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab_create_listing'),
        backgroundColor: AppColors.ctaTerracotta,
        foregroundColor: AppColors.textLight,
        elevation: 3,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Đăng bán mới',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => context.push(AppRoutes.sellerCreateListing),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ctaTerracotta,
          onRefresh: () => ref
              .read(sellerListingsViewModelProvider)
              .loadProducts(refresh: true),
          child: vm.state.when(
            initial: () => const Center(
              child: CircularProgressIndicator(color: AppColors.pineDeep),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.pineDeep),
            ),
            error: (msg, err) => RetroErrorRetryView(
              errorMessage: msg,
              onRetry: () => ref
                  .read(sellerListingsViewModelProvider)
                  .loadProducts(refresh: true),
            ),
            empty: (msg) => RetroEmptyStateView(
              title: 'Chưa có sản phẩm',
              message: msg ?? 'Không có sản phẩm nào trong mục này.',
              icon: Icons.inventory_2_outlined,
              actionLabel: 'Tải lại',
              onAction: () => ref
                  .read(sellerListingsViewModelProvider)
                  .loadProducts(refresh: true),
            ),
            success: (items) => _buildProductList(items, vm),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(
    List<SellerProductItemModel> items,
    SellerListingsViewModel vm,
  ) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 92),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildProductCard(items[index], vm),
    );
  }

  Widget _buildProductCard(
    SellerProductItemModel item,
    SellerListingsViewModel vm,
  ) {
    final isAuction = item.listingType == 'AUCTION';
    final isRejected = item.status == 'REJECTED';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(
          color: isRejected
              ? AppColors.priceCrimsonBorder
              : AppColors.borderWarm,
          width: isRejected ? 1.3 : 1,
        ),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rejected warning strip (DEC-05)
          if (isRejected && item.rejectionReason != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: const BoxDecoration(
                color: AppColors.priceCrimsonSoft,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(DesignTokens.radiusLg - 1),
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.priceCrimsonBorder),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 17,
                    color: AppColors.priceCrimson,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lý do từ chối: ${item.rejectionReason}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.priceCrimson,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: DesignTokens.borderRadiusMd,
                  child: Container(
                    width: 86,
                    height: 86,
                    color: AppColors.surfaceWarm,
                    child: item.primaryImageUrl != null &&
                            item.primaryImageUrl!.isNotEmpty
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
                            size: 34,
                            color: AppColors.primaryVintageBrown,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTypography.labelStrong.copyWith(
                          fontSize: 14.5,
                          color: AppColors.textCharcoal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            VndFormatter.format(item.price),
                            style: AppTypography.priceDisplay.copyWith(
                              fontSize: 15.5,
                              color: AppColors.priceCrimson,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isAuction)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pineDeep,
                                borderRadius: DesignTokens.borderRadiusFull,
                              ),
                              child: Text(
                                '🔨 Đấu giá',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.creamBadgeBg,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ConditionBadge(
                            condition: item.condition,
                            isCompact: true,
                          ),
                          StatusPillBadge(
                            status: item.status,
                            isCompact: true,
                          ),
                          if (!isAuction)
                            Text(
                              'Kho: ${item.availableQuantity}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
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

          const Divider(height: 1, color: AppColors.borderSubtle),

          // Contextual Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: _buildContextActions(item, vm),
          ),
        ],
      ),
    );
  }

  Widget _buildContextActions(
    SellerProductItemModel item,
    SellerListingsViewModel vm,
  ) {
    // 1. REJECTED: Inspect reason & resubmit (DEC-05)
    if (item.status == 'REJECTED') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            key: Key('btn_resubmit_${item.id}'),
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Xem lý do & Gửi duyệt lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.priceCrimson,
              foregroundColor: AppColors.textLight,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
              shape: const StadiumBorder(),
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

    // 2. Can Relist (Unsold Auction DEC-02)
    if (item.canRelist) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            key: Key('btn_relist_${item.id}'),
            icon: const Icon(Icons.replay_rounded, size: 16),
            label: const Text('Tái đăng đấu giá'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pineDeep,
              foregroundColor: AppColors.textLight,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              shape: const StadiumBorder(),
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
              foregroundColor: AppColors.priceCrimson,
              side: const BorderSide(color: AppColors.priceCrimsonBorder),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              shape: const StadiumBorder(),
            ),
            onPressed: () => _confirmDeleteDraft(item.id, vm),
            child: const Text('Xóa nháp', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: Key('btn_edit_draft_${item.id}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctaTerracotta,
              foregroundColor: AppColors.textLight,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              context.push(
                AppRoutes.sellerEditListingPath(item.id),
                extra: item,
              );
            },
            child: const Text(
              'Tiếp tục sửa',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
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
            icon: Icon(
              isApproved
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 16,
            ),
            label: Text(isApproved ? 'Ẩn bài' : 'Hiện lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isApproved
                  ? AppColors.primaryVintageBrown
                  : AppColors.verifiedLeaf,
              side: BorderSide(
                color:
                    isApproved ? AppColors.borderWarm : AppColors.verifiedLeaf,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              shape: const StadiumBorder(),
            ),
            onPressed: () async {
              final ok = await vm.toggleVisibility(item.id, item.status);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? (isApproved
                              ? 'Đã ẩn bài đăng thành công'
                              : 'Đã hiện lại bài đăng')
                          : 'Không thể cập nhật trạng thái bài đăng',
                    ),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              shape: const StadiumBorder(
                side: BorderSide(color: AppColors.borderWarm),
              ),
            ),
            child: const Text(
              'Chỉnh sửa',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    // Default for other states (SOLD, ARCHIVED, PENDING_REVIEW)
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
          style: TextButton.styleFrom(
            foregroundColor: AppColors.pineDeep,
            shape: const StadiumBorder(),
          ),
          child: const Text(
            'Xem chi tiết',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteDraft(int productId, SellerListingsViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusBanner,
          side: const BorderSide(color: AppColors.borderWarm),
        ),
        title: Text(
          'Xác nhận xóa bản nháp',
          style: AppTypography.headingSmall.copyWith(fontSize: 17),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa bài đăng nháp này không? Thao tác này không thể hoàn tác.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.priceCrimson,
              foregroundColor: AppColors.textLight,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.deleteDraft(productId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Đã xóa bản nháp' : 'Xóa thất bại'),
                  ),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showRelistConfirmDialog(
    SellerProductItemModel item,
    SellerListingsViewModel vm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusBanner,
          side: const BorderSide(color: AppColors.borderWarm),
        ),
        title: Text(
          'Tái đăng đấu giá',
          style: AppTypography.headingSmall.copyWith(fontSize: 17),
        ),
        content: Text(
          'Bạn có muốn mở lại phiên đấu giá cho sản phẩm "${item.title}" với cấu hình tương tự không?',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pineDeep,
              foregroundColor: AppColors.textLight,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.relistProduct(item.id, {
                'starting_price': item.startingPrice ?? item.price,
                'min_bid_increment': item.bidIncrement ?? 10000,
                'duration_hours': 24,
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Đã tái đăng đấu giá thành công'
                          : 'Lỗi khi tái đăng',
                    ),
                  ),
                );
              }
            },
            child: const Text('Tái đăng ngay'),
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
