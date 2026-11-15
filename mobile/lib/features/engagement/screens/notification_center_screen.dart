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
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textCharcoal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Thông Báo',
          style: AppTypography.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textCharcoal,
          ),
        ),
        actions: [
          if (notifVm.unreadCount > 0)
            TextButton(
              onPressed: () => notifVm.markAllAsRead(),
              child: Text(
                'Đọc tất cả',
                style: AppTypography.button.copyWith(
                  color: AppColors.secondaryPineGreen,
                  fontSize: 13,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildFilterTabBar(notifVm),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (notifVm.isLoading && notifVm.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryPineGreen),
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
              color: AppColors.secondaryPineGreen,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  const RetroEmptyStateView(
                    icon: Icons.notifications_none_outlined,
                    title: 'Chưa có thông báo nào',
                    message: 'Các cập nhật về đơn hàng, phòng đấu giá và tin tức hệ thống sẽ hiển thị tại đây.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notifVm.fetchNotifications(),
            color: AppColors.secondaryPineGreen,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.borderWarm,
                indent: 68,
              ),
              itemBuilder: (context, index) {
                final item = list[index];
                return _buildNotificationTile(context, item, notifVm);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTabBar(NotificationViewModel notifVm) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCream,
        border: Border(bottom: BorderSide(color: AppColors.borderWarm)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: NotificationTabFilter.values.map((tab) {
          final isSelected = notifVm.selectedTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: DesignTokens.spaceSm),
            child: ChoiceChip(
              label: Text(
                tab.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textCharcoal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.secondaryPineGreen,
              backgroundColor: AppColors.surfaceWarm,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                side: BorderSide(
                  color: isSelected ? AppColors.secondaryPineGreen : AppColors.borderWarm,
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
      iconColor = AppColors.primaryTerracotta;
      iconBg = const Color(0xFFFBECE6);
    } else if (item.isAuctionType) {
      icon = Icons.gavel_rounded;
      iconColor = AppColors.accentVintageGold;
      iconBg = const Color(0xFFFDF8E8);
    } else {
      icon = Icons.campaign_outlined;
      iconColor = AppColors.secondaryPineGreen;
      iconBg = const Color(0xFFEBF1EC);
    }

    return InkWell(
      onTap: () => notifVm.handleNotificationTap(context, item),
      child: Container(
        color: item.isRead ? Colors.transparent : AppColors.surfaceWarm.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceLg,
          vertical: DesignTokens.spaceMd,
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
                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: DesignTokens.spaceMd),

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
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                            color: AppColors.textCharcoal,
                          ),
                        ),
                      ),
                      if (!item.isRead) ...[
                        const SizedBox(width: DesignTokens.spaceSm),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.christmasBerryRed,
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
                      height: 1.35,
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
    );
  }
}
