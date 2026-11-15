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
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatViewModelProvider).enterChatRoom(widget.conversationId).then((_) {
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
        backgroundColor: AppColors.backgroundCream,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundCream,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textCharcoal),
            onPressed: () {
              ref.read(chatViewModelProvider).leaveChatRoom();
              context.pop();
            },
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.borderWarm,
                backgroundImage: (otherUser?.avatarUrl != null && otherUser!.avatarUrl!.isNotEmpty)
                    ? NetworkImage(otherUser.avatarUrl!)
                    : null,
                child: (otherUser?.avatarUrl == null || otherUser!.avatarUrl!.isEmpty)
                    ? Text(
                        otherUser?.displayName.isNotEmpty == true
                            ? otherUser!.displayName.substring(0, 1).toUpperCase()
                            : '?',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTerracotta,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: DesignTokens.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser?.displayName ?? 'Đang tải...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    Text(
                      chatVm.isBlocked ? 'Cuộc trò chuyện bị chặn' : 'Đang trực tuyến',
                      style: AppTypography.caption.copyWith(
                        color: chatVm.isBlocked ? AppColors.statusDanger : AppColors.secondaryPineGreen,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textCharcoal),
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
                        Icon(Icons.storefront_outlined, size: 18, color: AppColors.textCharcoal),
                        SizedBox(width: 8),
                        Text('Xem trang tiệm'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 18, color: AppColors.christmasBerryRed),
                      SizedBox(width: 8),
                      Text('Báo cáo & Chặn', style: TextStyle(color: AppColors.christmasBerryRed)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: AppColors.borderWarm,
              height: 1.0,
            ),
          ),
        ),
        body: Column(
          children: [
            // Pinned Context Card (Product or Order)
            if (conversation?.contextProduct != null || conversation?.contextOrder != null)
              _buildPinnedContextCard(context, conversation!),

            // Messages View
            Expanded(
              child: Builder(
                builder: (context) {
                  if (chatVm.isLoading && chatVm.messages.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.secondaryPineGreen),
                    );
                  }

                  if (chatVm.isError && chatVm.messages.isEmpty) {
                    return RetroErrorRetryView(
                      errorMessage: chatVm.errorMessage ?? 'Không thể tải tin nhắn',
                      onRetry: () => chatVm.enterChatRoom(widget.conversationId),
                    );
                  }

                  if (chatVm.messages.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(DesignTokens.spaceLg),
                        child: Text(
                          'Bắt đầu cuộc trò chuyện. Hãy giữ lịch sự và tuân thủ quy tắc cộng đồng izithrift.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceMd,
                      vertical: DesignTokens.spaceMd,
                    ),
                    itemCount: chatVm.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatVm.messages[index];
                      return _buildMessageBubble(context, msg);
                    },
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

  Widget _buildPinnedContextCard(BuildContext context, ConversationModel conversation) {
    if (conversation.contextProduct != null) {
      final p = conversation.contextProduct!;
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceMd,
          vertical: DesignTokens.spaceSm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceWarm,
          border: Border(bottom: BorderSide(color: AppColors.borderWarm)),
        ),
        child: Row(
          children: [
            if (p.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                child: Image.network(
                  p.thumbnailUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 48,
                    height: 48,
                    color: AppColors.borderWarm,
                    child: const Icon(Icons.inventory_2_outlined, size: 24),
                  ),
                ),
              ),
            const SizedBox(width: DesignTokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textCharcoal,
                    ),
                  ),
                  Text(
                    _currencyFormat.format(p.price),
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTerracotta,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.spaceSm),
            ElevatedButton(
              onPressed: () => context.push('/products/${p.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTerracotta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Xem đồ', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (conversation.contextOrder != null) {
      final o = conversation.contextOrder!;
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceMd,
          vertical: DesignTokens.spaceSm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceWarm,
          border: Border(bottom: BorderSide(color: AppColors.borderWarm)),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_outlined, color: AppColors.secondaryPineGreen, size: 32),
            const SizedBox(width: DesignTokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đơn hàng: #${o.orderCode}',
                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${o.orderStatus} • ${_currencyFormat.format(o.totalAmount)}',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.push('/orders/${o.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryPineGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Xem đơn', style: TextStyle(fontSize: 12)),
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
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceMd,
          vertical: DesignTokens.spaceSm + 2,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.secondaryPineGreen : const Color(0xFFE9DDCB),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(DesignTokens.radiusMd),
            topRight: const Radius.circular(DesignTokens.radiusMd),
            bottomLeft: Radius.circular(isMe ? DesignTokens.radiusMd : 2),
            bottomRight: Radius.circular(isMe ? 2 : DesignTokens.radiusMd),
          ),
          border: Border.all(
            color: isMe ? AppColors.secondaryPineGreen : AppColors.borderWarm,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: AppTypography.bodyMedium.copyWith(
                color: isMe ? Colors.white : AppColors.textCharcoal,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : AppColors.textMuted,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 13,
                    color: message.isRead ? AppColors.accentVintageGold : Colors.white70,
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
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        color: const Color(0xFFFDE8E8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 18, color: AppColors.statusDanger),
            const SizedBox(width: DesignTokens.spaceSm),
            Text(
              'Cuộc trò chuyện này đã bị chặn.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.statusDanger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceMd,
        DesignTokens.spaceSm,
        DesignTokens.spaceMd,
        DesignTokens.spaceMd,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(top: BorderSide(color: AppColors.borderWarm)),
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
                  hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.backgroundCream,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceMd,
                    vertical: DesignTokens.spaceSm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                    borderSide: const BorderSide(color: AppColors.borderWarm),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                    borderSide: const BorderSide(color: AppColors.borderWarm),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                    borderSide: const BorderSide(color: AppColors.secondaryPineGreen),
                  ),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.spaceSm),
            IconButton(
              onPressed: chatVm.isSendingMessage ? null : _handleSendMessage,
              icon: chatVm.isSendingMessage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondaryPineGreen),
                    )
                  : const Icon(Icons.send_rounded, color: AppColors.secondaryPineGreen),
            ),
          ],
        ),
      ),
    );
  }
}
