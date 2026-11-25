import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/conversation_model.dart';
import '../viewmodels/chat_view_model.dart';

/// M-CM-01: Conversation Inbox Screen (Tab 4 Root: /messages)
class ConversationInboxScreen extends ConsumerStatefulWidget {
  const ConversationInboxScreen({super.key});

  @override
  ConsumerState<ConversationInboxScreen> createState() =>
      _ConversationInboxScreenState();
}

class _ConversationInboxScreenState
    extends ConsumerState<ConversationInboxScreen> {
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
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const Flexible(
              child: RetroBrandWordmark(titleText: 'izithrift • Tin nhắn'),
            ),
            if (chatVm.totalUnreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.priceCrimson,
                  borderRadius: DesignTokens.borderRadiusFull,
                ),
                child: Text(
                  '${chatVm.totalUnreadCount}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          RetroHeaderIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Thông báo',
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 4),
        ],
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
              color: AppColors.pineDeep,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                  const RetroEmptyStateView(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Chưa có cuộc trò chuyện nào',
                    message:
                        'Bắt đầu trao đổi với người bán ngay trên món đồ vintage bạn ưng ý!',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => chatVm.loadInbox(),
            color: AppColors.pineDeep,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: chatVm.conversations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildConversationTile(context, chatVm.conversations[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, ConversationModel item) {
    final otherUser = item.otherUser;
    final hasUnread = item.unreadCount > 0;

    return Material(
      color: hasUnread ? AppColors.surfaceSection : AppColors.surfaceCard,
      borderRadius: DesignTokens.borderRadiusLg,
      child: InkWell(
        borderRadius: DesignTokens.borderRadiusLg,
        onTap: () {
          context.push('/messages/${item.id}').then((_) {
            if (mounted) {
              ref.read(chatViewModelProvider).loadInbox();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: DesignTokens.borderRadiusLg,
            border: Border.all(
              color: hasUnread
                  ? AppColors.creamBadgeBorder
                  : AppColors.borderWarm,
              width: hasUnread ? 1.3 : 1,
            ),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasUnread
                            ? AppColors.ctaTerracotta
                            : AppColors.creamBadgeBorder,
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.categoryCircleStart,
                      backgroundImage: (otherUser.avatarUrl != null &&
                              otherUser.avatarUrl!.isNotEmpty)
                          ? NetworkImage(otherUser.avatarUrl!)
                          : null,
                      child: (otherUser.avatarUrl == null ||
                              otherUser.avatarUrl!.isEmpty)
                          ? Text(
                              otherUser.displayName.isNotEmpty
                                  ? otherUser.displayName
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : 'U',
                              style: AppTypography.headingSmall.copyWith(
                                color: AppColors.pineDeep,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (item.isBlocked)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.priceCrimson,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.block,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
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
                            otherUser.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelStrong.copyWith(
                              fontSize: 14.5,
                              color: AppColors.textCharcoal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.formattedTime,
                          style: AppTypography.caption.copyWith(
                            color: hasUnread
                                ? AppColors.priceCrimson
                                : AppColors.textMuted,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.lastMessagePreview ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: hasUnread
                                  ? AppColors.textCharcoal
                                  : AppColors.textMuted,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.priceCrimson,
                              borderRadius: DesignTokens.borderRadiusFull,
                            ),
                            child: Text(
                              '${item.unreadCount}',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Pinned Product Context Thumbnail
              if (item.contextProduct != null &&
                  item.contextProduct!.thumbnailUrl != null) ...[
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: DesignTokens.borderRadiusSm,
                  child: Image.network(
                    item.contextProduct!.thumbnailUrl!,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 46,
                      height: 46,
                      color: AppColors.surfaceWarm,
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: DesignTokens.borderRadiusLg,
            border: Border.all(color: AppColors.borderWarm),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWarm,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: DesignTokens.borderRadiusXs,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: DesignTokens.borderRadiusXs,
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
