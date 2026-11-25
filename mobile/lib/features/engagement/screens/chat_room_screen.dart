import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../viewmodels/chat_view_model.dart';
import 'report_and_block_modal.dart';

/// M-CM-02: 1-on-1 Chat Room Screen with Pinned Context Card & HTTP Short-Polling (ADR-08)
class ChatRoomScreen extends ConsumerStatefulWidget {
  final int conversationId;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatViewModelProvider)
          .enterChatRoom(widget.conversationId)
          .then((_) {
        _scrollToBottom();
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final chatVm = ref.read(chatViewModelProvider);
    final success = await chatVm.sendMessage(text);
    if (success) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatVm = ref.watch(chatViewModelProvider);
    final conversation = chatVm.currentConversation;
    final otherUser = conversation?.otherUser;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(chatViewModelProvider).leaveChatRoom();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.canvasParchment,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceCard,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textCharcoal,
            ),
            onPressed: () {
              ref.read(chatViewModelProvider).leaveChatRoom();
              context.pop();
            },
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.creamBadgeBorder),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.categoryCircleStart,
                  backgroundImage: (otherUser?.avatarUrl != null &&
                          otherUser!.avatarUrl!.isNotEmpty)
                      ? NetworkImage(otherUser.avatarUrl!)
                      : null,
                  child: (otherUser?.avatarUrl == null ||
                          otherUser!.avatarUrl!.isEmpty)
                      ? Text(
                          otherUser?.displayName.isNotEmpty == true
                              ? otherUser!.displayName
                                  .substring(0, 1)
                                  .toUpperCase()
                              : '?',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.pineDeep,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser?.displayName ?? 'Đang tải...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelStrong.copyWith(
                        fontSize: 15,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: chatVm.isBlocked
                                ? AppColors.priceCrimson
                                : AppColors.verifiedLeaf,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          chatVm.isBlocked
                              ? 'Cuộc trò chuyện bị chặn'
                              : 'Đang trực tuyến',
                          style: AppTypography.caption.copyWith(
                            color: chatVm.isBlocked
                                ? AppColors.priceCrimson
                                : AppColors.verifiedLeaf,
                            fontSize: 11,
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
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textCharcoal,
              ),
              color: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: DesignTokens.borderRadiusMd,
                side: const BorderSide(color: AppColors.borderWarm),
              ),
              onSelected: (value) {
                if (value == 'report' && conversation != null) {
                  ReportAndBlockModal.show(
                    context,
                    conversationId: conversation.id,
                    targetUserId: otherUser?.id ?? 0,
                    targetUserName: otherUser?.displayName ?? 'Người dùng',
                  );
                } else if (value == 'view_shop' && otherUser != null) {
                  context.push('/sellers/${otherUser.id}');
                }
              },
              itemBuilder: (context) => [
                if (otherUser != null)
                  const PopupMenuItem(
                    value: 'view_shop',
                    child: Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 18,
                          color: AppColors.pineDeep,
                        ),
                        SizedBox(width: 8),
                        Text('Xem trang tiệm'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 18,
                        color: AppColors.priceCrimson,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Báo cáo & Chặn',
                        style: TextStyle(color: AppColors.priceCrimson),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: AppColors.borderWarm),
          ),
        ),
        body: Column(
          children: [
            // Pinned Context Card (Product or Order)
            if (conversation?.contextProduct != null ||
                conversation?.contextOrder != null)
              _buildPinnedContextCard(context, conversation!),

            // Messages View
            Expanded(
              child: Builder(
                builder: (context) {
                  if (chatVm.isLoading && chatVm.messages.isEmpty) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.pineDeep),
                    );
                  }

                  if (chatVm.isError && chatVm.messages.isEmpty) {
                    return RetroErrorRetryView(
                      errorMessage:
                          chatVm.errorMessage ?? 'Không thể tải tin nhắn',
                      onRetry: () =>
                          chatVm.enterChatRoom(widget.conversationId),
                    );
                  }

                  if (chatVm.messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSection,
                            borderRadius: DesignTokens.borderRadiusLg,
                            border: Border.all(color: AppColors.borderWarm),
                          ),
                          child: Text(
                            'Bắt đầu cuộc trò chuyện. Hãy giữ lịch sự và tuân thủ quy tắc cộng đồng izithrift.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    itemCount: chatVm.messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessageBubble(context, chatVm.messages[index]),
                  );
                },
              ),
            ),

            // Bottom Input Bar
            _buildBottomInputBar(context, chatVm),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedContextCard(
    BuildContext context,
    ConversationModel conversation,
  ) {
    if (conversation.contextProduct != null) {
      final p = conversation.contextProduct!;
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: DesignTokens.borderRadiusLg,
          border: Border.all(color: AppColors.borderWarm),
          boxShadow: DesignTokens.cardElevation,
        ),
        child: Row(
          children: [
            if (p.thumbnailUrl != null) ...[
              ClipRRect(
                borderRadius: DesignTokens.borderRadiusSm,
                child: Image.network(
                  p.thumbnailUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 48,
                    height: 48,
                    color: AppColors.surfaceWarm,
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 22,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelStrong.copyWith(
                      fontSize: 13.5,
                      color: AppColors.textCharcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currencyFormat.format(p.price),
                    style: AppTypography.priceDisplay.copyWith(
                      fontSize: 13.5,
                      color: AppColors.priceCrimson,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => context.push('/products/${p.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ctaTerracotta,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Xem đồ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    if (conversation.contextOrder != null) {
      final o = conversation.contextOrder!;
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: DesignTokens.borderRadiusLg,
          border: Border.all(color: AppColors.borderWarm),
          boxShadow: DesignTokens.cardElevation,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.verifiedLeafBg,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.pineDeep,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đơn hàng: #${o.orderCode}',
                    style: AppTypography.labelStrong.copyWith(fontSize: 13.5),
                  ),
                  Text(
                    '${o.orderStatus} • ${_currencyFormat.format(o.totalAmount)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.push('/orders/${o.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pineDeep,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Xem đơn',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMessageBubble(BuildContext context, MessageModel message) {
    final isMe = message.isMine;
    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.pineDeep : AppColors.surfaceCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: Border.all(
            color: isMe ? AppColors.pineDeep : AppColors.borderWarm,
            width: 0.8,
          ),
          boxShadow: isMe ? null : DesignTokens.cardElevation,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: AppTypography.bodyMedium.copyWith(
                color: isMe ? AppColors.textLight : AppColors.textCharcoal,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? AppColors.creamBadgeBg.withValues(alpha: 0.8)
                        : AppColors.textMuted,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 13,
                    color: message.isRead
                        ? AppColors.starGold
                        : AppColors.creamBadgeBg.withValues(alpha: 0.75),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInputBar(BuildContext context, ChatViewModel chatVm) {
    if (chatVm.isBlocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: AppColors.priceCrimsonSoft,
          border: Border(top: BorderSide(color: AppColors.priceCrimsonBorder)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 18, color: AppColors.priceCrimson),
              const SizedBox(width: 8),
              Text(
                'Cuộc trò chuyện này đã bị chặn.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.priceCrimson,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: DesignTokens.bottomNavElevation,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendMessage(),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn trao đổi...',
                  hintStyle:
                      AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
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
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.pineDeep,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: chatVm.isSendingMessage ? null : _handleSendMessage,
                icon: chatVm.isSendingMessage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: AppColors.creamBadgeBg,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
