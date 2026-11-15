import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/conversation_model.dart';
import '../viewmodels/chat_view_model.dart';

/// M-CM-01: Conversation Inbox Screen (Tab 4 Root: /messages)
class ConversationInboxScreen extends ConsumerStatefulWidget {
  const ConversationInboxScreen({super.key});

  @override
  ConsumerState<ConversationInboxScreen> createState() => _ConversationInboxScreenState();
}

class _ConversationInboxScreenState extends ConsumerState<ConversationInboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatViewModelProvider).loadInbox();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatVm = ref.watch(chatViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'izithrift • Tin nhắn',
              style: AppTypography.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textCharcoal,
              ),
            ),
            if (chatVm.totalUnreadCount > 0) ...[
              const SizedBox(width: DesignTokens.spaceSm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.christmasBerryRed,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                ),
                child: Text(
                  '${chatVm.totalUnreadCount}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Thông báo',
            onPressed: () => context.push('/notifications'),
          ),
        ],
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.borderWarm,
            height: 1.0,
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (chatVm.isLoading && chatVm.conversations.isEmpty) {
            return _buildShimmerLoading();
          }

          if (chatVm.isError && chatVm.conversations.isEmpty) {
            return RetroErrorRetryView(
              errorMessage: chatVm.errorMessage ?? 'Không thể tải tin nhắn',
              onRetry: () => chatVm.loadInbox(),
            );
          }

          if (chatVm.conversations.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => chatVm.loadInbox(),
              color: AppColors.secondaryPineGreen,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  const RetroEmptyStateView(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chưa có cuộc trò chuyện nào',
                    message: 'Bắt đầu trao đổi với người bán ngay trên món đồ vintage bạn ưng ý!',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => chatVm.loadInbox(),
            color: AppColors.secondaryPineGreen,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: chatVm.conversations.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.borderWarm,
                indent: 72,
              ),
              itemBuilder: (context, index) {
                final item = chatVm.conversations[index];
                return _buildConversationTile(context, item);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, ConversationModel item) {
    final otherUser = item.otherUser;
    final hasUnread = item.unreadCount > 0;

    return InkWell(
      onTap: () {
        context.push('/messages/${item.id}').then((_) {
          // Refresh inbox upon returning to update unread counts
          if (mounted) {
            ref.read(chatViewModelProvider).loadInbox();
          }
        });
      },
      child: Container(
        color: hasUnread ? AppColors.surfaceWarm.withValues(alpha: 0.5) : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceLg,
          vertical: DesignTokens.spaceMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.borderWarm,
                  backgroundImage: (otherUser.avatarUrl != null && otherUser.avatarUrl!.isNotEmpty)
                      ? NetworkImage(otherUser.avatarUrl!)
                      : null,
                  child: (otherUser.avatarUrl == null || otherUser.avatarUrl!.isEmpty)
                      ? Text(
                          otherUser.displayName.isNotEmpty
                              ? otherUser.displayName.substring(0, 1).toUpperCase()
                              : 'U',
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.primaryTerracotta,
                          ),
                        )
                      : null,
                ),
                if (item.isBlocked)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.statusDanger,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.block, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: DesignTokens.spaceMd),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherUser.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            color: AppColors.textCharcoal,
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spaceSm),
                      Text(
                        item.formattedTime,
                        style: AppTypography.caption.copyWith(
                          color: hasUnread ? AppColors.primaryTerracotta : AppColors.textMuted,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.lastMessagePreview ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: hasUnread ? AppColors.textCharcoal : AppColors.textMuted,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: DesignTokens.spaceSm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.christmasBerryRed,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                          ),
                          child: Text(
                            '${item.unreadCount}',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Pinned Product Context Thumbnail (if present)
            if (item.contextProduct != null && item.contextProduct!.thumbnailUrl != null) ...[
              const SizedBox(width: DesignTokens.spaceSm),
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                child: Image.network(
                  item.contextProduct!.thumbnailUrl!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 44,
                    height: 44,
                    color: AppColors.surfaceWarm,
                    child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.textMuted),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceLg,
            vertical: DesignTokens.spaceMd,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWarm,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
