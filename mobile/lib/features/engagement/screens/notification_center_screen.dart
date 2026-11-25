import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/notification_item_model.dart';
import '../viewmodels/notification_view_model.dart';

/// M-NT-01: In-App Notification Center Screen with Deep-Link Navigation
class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationViewModelProvider).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifVm = ref.watch(notificationViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textCharcoal,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Thông Báo',
          style: AppTypography.headingMedium.copyWith(fontSize: 20),
        ),
        actions: [
          if (notifVm.unreadCount > 0)
            TextButton(
              onPressed: () => notifVm.markAllAsRead(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.pineDeep,
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Đọc tất cả',
                style: AppTypography.labelStrong.copyWith(
                  color: AppColors.pineDeep,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildFilterTabBar(notifVm),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (notifVm.isLoading && notifVm.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.pineDeep),
            );
          }

          if (notifVm.isError && notifVm.notifications.isEmpty) {
            return RetroErrorRetryView(
              errorMessage: notifVm.errorMessage ?? 'Không thể tải thông báo',
              onRetry: () => notifVm.fetchNotifications(),
            );
          }

          final list = notifVm.filteredNotifications;

          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => notifVm.fetchNotifications(),
              color: AppColors.pineDeep,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                  const RetroEmptyStateView(
                    icon: Icons.notifications_none_rounded,
                    title: 'Chưa có thông báo nào',
                    message:
                        'Các cập nhật về đơn hàng, phòng đấu giá và tin tức hệ thống sẽ hiển thị tại đây.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notifVm.fetchNotifications(),
            color: AppColors.pineDeep,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildNotificationTile(context, list[index], notifVm),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTabBar(NotificationViewModel notifVm) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.canvasParchment,
        border: Border(bottom: BorderSide(color: AppColors.borderWarm)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: NotificationTabFilter.values.map((tab) {
          final isSelected = notifVm.selectedTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                tab.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.creamBadgeBg
                      : AppColors.textCharcoal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.pineDeep,
              backgroundColor: AppColors.surfaceCard,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? AppColors.pineDeep : AppColors.borderWarm,
                ),
              ),
              onSelected: (_) => notifVm.selectTab(tab),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationItemModel item,
    NotificationViewModel notifVm,
  ) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    if (item.isOrderType) {
      icon = Icons.local_shipping_outlined;
      iconColor = AppColors.ctaTerracotta;
      iconBg = AppColors.priceCrimsonSoft;
    } else if (item.isAuctionType) {
      icon = Icons.gavel_rounded;
      iconColor = AppColors.creamBadgeText;
      iconBg = AppColors.creamBadgeSoft;
    } else {
      icon = Icons.campaign_outlined;
      iconColor = AppColors.verifiedLeaf;
      iconBg = AppColors.verifiedLeafBg;
    }

    return Material(
      color: item.isRead ? AppColors.surfaceCard : AppColors.surfaceSection,
      borderRadius: DesignTokens.borderRadiusLg,
      child: InkWell(
        borderRadius: DesignTokens.borderRadiusLg,
        onTap: () => notifVm.handleNotificationTap(context, item),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: DesignTokens.borderRadiusLg,
            border: Border.all(
              color: item.isRead
                  ? AppColors.borderWarm
                  : AppColors.creamBadgeBorder,
              width: item.isRead ? 1 : 1.3,
            ),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor.withValues(alpha: 0.28)),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelStrong.copyWith(
                              fontSize: 14,
                              color: AppColors.textCharcoal,
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.priceCrimson,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.formattedTime,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
