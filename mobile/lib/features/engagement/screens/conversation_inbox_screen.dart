import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/izithrift_global_app_bar.dart';
import '../../../core/widgets/retro_product_image.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/conversation_model.dart';
import '../viewmodels/chat_view_model.dart';

/// M-CM-01: Conversation Inbox Screen (Messages Tab: /messages)
/// Features standardized Global Upper Navigation, live conversation search,
/// online indicators, unread counters, and product context thumbnails.
class ConversationInboxScreen extends ConsumerStatefulWidget {
  const ConversationInboxScreen({super.key});

  @override
  ConsumerState<ConversationInboxScreen> createState() =>
      _ConversationInboxScreenState();
}

class _ConversationInboxScreenState
    extends ConsumerState<ConversationInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatViewModelProvider).loadInbox();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ConversationModel> _filterConversations(List<ConversationModel> items) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((c) {
      final name = c.partnerName.toLowerCase();
      final preview = (c.lastMessagePreview ?? '').toLowerCase();
      final product = (c.contextProduct?.title ?? '').toLowerCase();
      return name.contains(q) || preview.contains(q) || product.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chatVm = ref.watch(chatViewModelProvider);
    final filteredConversations = _filterConversations(chatVm.conversations);

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: const IzithriftGlobalAppBar(
        activeDestination: IzithriftUpperNavDestination.messages,
      ),
      body: Column(
        children: [
          // Clean Header + Conversation Search Bar
          Container(
            color: AppColors.surfaceCard,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Tin nhắn',
                      style: AppTypography.headingMedium.copyWith(
                        fontSize: 20,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    if (chatVm.totalUnreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ctaTerracotta,
                          borderRadius: DesignTokens.borderRadiusFull,
                        ),
                        child: Text(
                          '${chatVm.totalUnreadCount} mới',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: AppTypography.bodyMedium.copyWith(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Tìm người bán, nội dung hoặc món đồ...',
                    hintStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.canvasParchment,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: DesignTokens.borderRadiusFull,
                      borderSide: const BorderSide(color: AppColors.borderWarm),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: DesignTokens.borderRadiusFull,
                      borderSide: const BorderSide(color: AppColors.borderWarm),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: DesignTokens.borderRadiusFull,
                      borderSide: const BorderSide(
                        color: AppColors.pineDeep,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderWarm),

          Expanded(
            child: Builder(
              builder: (context) {
                if (chatVm.isLoading && chatVm.conversations.isEmpty) {
                  return _buildShimmerLoading();
                }

                if (chatVm.isError && chatVm.conversations.isEmpty) {
                  return RetroErrorRetryView(
                    errorMessage:
                        chatVm.errorMessage ?? 'Không thể tải tin nhắn',
                    onRetry: () => chatVm.loadInbox(),
                  );
                }

                if (filteredConversations.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => chatVm.loadInbox(),
                    color: AppColors.pineDeep,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.14,
                        ),
                        RetroEmptyStateView(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: _searchQuery.isNotEmpty
                              ? 'Không tìm thấy cuộc trò chuyện'
                              : 'Chưa có cuộc trò chuyện nào',
                          message: _searchQuery.isNotEmpty
                              ? 'Hãy thử tìm bằng từ khóa hoặc tên shop khác.'
                              : 'Bắt đầu trao đổi với người bán ngay trên món đồ vintage bạn ưng ý!',
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filteredConversations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _buildConversationTile(
                      context,
                      filteredConversations[index],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, ConversationModel item) {
    final otherUser = item.otherUser;
    final hasUnread = item.unreadCount > 0;

    return Material(
      color: AppColors.surfaceCard,
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
                  ? AppColors.pineDeep.withValues(alpha: 0.35)
                  : AppColors.borderWarm,
              width: hasUnread ? 1.3 : 1,
            ),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar + Online / Blocked Status Dot
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
                            : AppColors.borderWarm,
                        width: 1.5,
                      ),
                    ),
                    child: Builder(
                      builder: (_) {
                        final avatarUrl = otherUser.avatarUrl?.trim();
                        final hasValidAvatar = avatarUrl != null &&
                            (avatarUrl.startsWith('http://') ||
                                avatarUrl.startsWith('https://'));
                        return CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryForestGreenLight,
                          backgroundImage:
                              hasValidAvatar ? NetworkImage(avatarUrl) : null,
                          child: !hasValidAvatar
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
                        );
                      },
                    ),
                  ),
                  if (item.isBlocked)
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.statusDanger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.block,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else if (item.isOnline)
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.statusSuccess,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
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
                                ? AppColors.ctaTerracotta
                                : AppColors.textMuted,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.normal,
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
                              color: AppColors.ctaTerracotta,
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
              if (item.contextProduct != null) ...[
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: DesignTokens.borderRadiusSm,
                  child: RetroProductImage(
                    imageUrl: item.contextProduct!.thumbnailUrl,
                    title: item.contextProduct!.title,
                    width: 48,
                    height: 48,
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
