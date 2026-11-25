import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/product_image_resolver.dart';
import '../../../core/widgets/retro_product_image.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../viewmodels/chat_view_model.dart';
import 'report_and_block_modal.dart';

/// M-CM-02: 1-on-1 Chat Room Screen
/// Supports:
/// - Text messages + HTTP Short-Polling (?after_id=)
/// - Built-in tactile Emoji picker panel
/// - Image attachments (Gallery / Camera / Demo photos + preview before send + full-screen view)
/// - Video attachments (Gallery / Demo clip + size/type check + thumbnail card + preview dialog)
/// - Pinned product/order context card + Report/Block safety controls
class ChatRoomScreen extends ConsumerStatefulWidget {
  final int conversationId;

  const ChatRoomScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _PendingAttachment {
  final String mediaType; // 'IMAGE' or 'VIDEO'
  final String? mediaPath;
  final Uint8List? mediaBytes;
  final String fileName;
  final String? durationLabel;
  final int? fileSizeBytes;

  const _PendingAttachment({
    required this.mediaType,
    this.mediaPath,
    this.mediaBytes,
    required this.fileName,
    this.durationLabel,
    this.fileSizeBytes,
  });
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );
  final ImagePicker _imagePicker = ImagePicker();

  bool _showEmojiPicker = false;
  _PendingAttachment? _pendingAttachment;

  static const List<String> _curatedEmojis = [
    '😊', '😍', '🥰', '😂', '🤩', '😎', '🙏', '👍',
    '❤️', '🔥', '✨', '🎉', '🎄', '❄️', '🎁', '⭐',
    '🧥', '👜', '👟', '📷', '⌚', '👗', '📦', '🚚',
    '💬', '✅', '💯', '🤝', '💸', '🏷️', '📍', '⏰',
  ];

  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(() {
      if (_inputFocusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatViewModelProvider)
          .enterChatRoom(widget.conversationId)
          .then((_) => _scrollToBottom());
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final start = selection.isValid && selection.start >= 0
        ? selection.start
        : text.length;
    final end = selection.isValid && selection.end >= 0
        ? selection.end
        : text.length;
    final updated = text.replaceRange(start, end, emoji);
    _messageController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  Future<void> _handleSendMessage() async {
    final chatVm = ref.read(chatViewModelProvider);
    final text = _messageController.text.trim();

    if (_pendingAttachment != null) {
      final attachment = _pendingAttachment!;
      _messageController.clear();
      setState(() => _pendingAttachment = null);

      if (attachment.mediaType == 'IMAGE') {
        final ok = await chatVm.sendImageAttachment(
          mediaPath: attachment.mediaPath,
          mediaBytes: attachment.mediaBytes,
          caption: text,
          fileName: attachment.fileName,
        );
        if (ok) _scrollToBottom();
      } else {
        final error = await chatVm.sendVideoAttachment(
          mediaPath: attachment.mediaPath ?? 'demo://video_preview.mp4',
          caption: text,
          fileName: attachment.fileName,
          durationLabel: attachment.durationLabel,
          fileSizeBytes: attachment.fileSizeBytes,
        );
        if (error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.statusDanger,
            ),
          );
        } else {
          _scrollToBottom();
        }
      }
      return;
    }

    if (text.isEmpty) return;
    _messageController.clear();
    final success = await chatVm.sendMessage(text);
    if (success) {
      _scrollToBottom();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _pendingAttachment = _PendingAttachment(
          mediaType: 'IMAGE',
          mediaPath: file.path,
          mediaBytes: bytes,
          fileName: file.name.isNotEmpty ? file.name : 'anh_dinh_kem.jpg',
        );
        _showEmojiPicker = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Thiết bị không hỗ trợ chọn ảnh trực tiếp. Bạn có thể chọn ảnh mẫu từ thư viện demo.',
          ),
        ),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final file = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (file == null || !mounted) return;
      final size = await file.length();
      if (size > ChatViewModel.maxVideoFileSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Video vượt quá giới hạn 25MB. Vui lòng chọn video ngắn hơn.',
            ),
            backgroundColor: AppColors.statusDanger,
          ),
        );
        return;
      }
      setState(() {
        _pendingAttachment = _PendingAttachment(
          mediaType: 'VIDEO',
          mediaPath: file.path,
          fileName: file.name.isNotEmpty ? file.name : 'video_san_pham.mp4',
          durationLabel: 'Video clip',
          fileSizeBytes: size,
        );
        _showEmojiPicker = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể truy cập video thiết bị. Bạn có thể dùng video demo mẫu để trải nghiệm.',
          ),
        ),
      );
    }
  }

  void _openAttachmentPickerSheet() {
    _inputFocusNode.unfocus();
    setState(() => _showEmojiPicker = false);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusXl),
        ),
      ),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đính kèm hình ảnh & video',
                style: AppTypography.headingSmall.copyWith(fontSize: 16.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Gửi ảnh chi tiết tình trạng món đồ hoặc clip ngắn (tối đa 25MB).',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _AttachmentActionTile(
                      icon: Icons.photo_library_outlined,
                      label: 'Ảnh thư viện',
                      color: AppColors.pineDeep,
                      bg: AppColors.primaryForestGreenLight,
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AttachmentActionTile(
                      icon: Icons.camera_alt_outlined,
                      label: 'Chụp ảnh',
                      color: AppColors.ctaTerracotta,
                      bg: AppColors.ctaTerracottaSoft,
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AttachmentActionTile(
                      icon: Icons.videocam_outlined,
                      label: 'Video clip',
                      color: const Color(0xFF9A6B16),
                      bg: AppColors.creamBadgeSoft,
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        _pickVideo();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.borderWarm),
              const SizedBox(height: 10),
              Text(
                'Tùy chọn nhanh (Chế độ Demo)',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(
                      Icons.image_outlined,
                      size: 16,
                      color: AppColors.pineDeep,
                    ),
                    label: const Text('Ảnh cận chất vải'),
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      setState(() {
                        _pendingAttachment = const _PendingAttachment(
                          mediaType: 'IMAGE',
                          mediaPath: ProductImageResolver.assetDenimJeans,
                          fileName: 'can_canh_chat_denim.jpg',
                        );
                      });
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(
                      Icons.play_circle_outline_rounded,
                      size: 16,
                      color: AppColors.ctaTerracotta,
                    ),
                    label: const Text('Video quay 360° (0:14)'),
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      setState(() {
                        _pendingAttachment = const _PendingAttachment(
                          mediaType: 'VIDEO',
                          mediaPath: 'demo://clip_vintage_360.mp4',
                          fileName: 'quay_chi_tiet_san_pham_360.mp4',
                          durationLabel: '0:14',
                          fileSizeBytes: 4200000,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, MessageModel message) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildRawImageWidget(message, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVideoPreviewDialog(BuildContext context, MessageModel message) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.videocam_rounded,
              color: AppColors.ctaTerracotta,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.mediaFileName ?? 'Video đính kèm',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headingSmall.copyWith(fontSize: 15.5),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.pineDeep, Color(0xFF0E2F22)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.ctaTerracotta,
                      shape: BoxShape.circle,
                      boxShadow: DesignTokens.cardElevation,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Thời lượng: ${message.mediaDurationLabel ?? "0:12"}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Xem trước video cục bộ (Demo): video đã được kiểm tra định dạng & dung lượng trên thiết bị. Phát video trực tuyến sẽ kết nối ngay khi server bật upload media cho tin nhắn.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildRawImageWidget(
    MessageModel message, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (message.mediaBytes != null) {
      return Image.memory(
        message.mediaBytes!,
        width: width,
        height: height,
        fit: fit,
      );
    }
    return RetroProductImage(
      imageUrl: message.mediaPath,
      title: message.mediaFileName ?? 'Ảnh đính kèm',
      width: width,
      height: height,
      fit: fit,
    );
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
                  border: Border.all(color: AppColors.borderWarm),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryForestGreenLight,
                  backgroundImage:
                      (otherUser?.avatarUrl != null &&
                          otherUser!.avatarUrl!.isNotEmpty)
                      ? NetworkImage(otherUser.avatarUrl!)
                      : null,
                  child:
                      (otherUser?.avatarUrl == null ||
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
                                ? AppColors.statusDanger
                                : AppColors.statusSuccess,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          chatVm.isBlocked
                              ? 'Cuộc trò chuyện bị chặn'
                              : 'Đang trực tuyến',
                          style: AppTypography.caption.copyWith(
                            color: chatVm.isBlocked
                                ? AppColors.statusDanger
                                : AppColors.statusSuccess,
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
                        color: AppColors.statusDanger,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Báo cáo & Chặn',
                        style: TextStyle(color: AppColors.statusDanger),
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
              child: GestureDetector(
                onTap: () {
                  _inputFocusNode.unfocus();
                  if (_showEmojiPicker) {
                    setState(() => _showEmojiPicker = false);
                  }
                },
                child: Builder(
                  builder: (context) {
                    if (chatVm.isLoading && chatVm.messages.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.pineDeep,
                        ),
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
                              color: AppColors.surfaceCard,
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
            ),

            // Pending Media Attachment Preview Bar
            if (_pendingAttachment != null && !chatVm.isBlocked)
              _buildPendingAttachmentPreview(),

            // Bottom Input Bar
            _buildBottomInputBar(context, chatVm),

            // Curated Tactile Emoji Picker Panel
            if (_showEmojiPicker && !chatVm.isBlocked) _buildEmojiPickerPanel(),
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
            ClipRRect(
              borderRadius: DesignTokens.borderRadiusSm,
              child: RetroProductImage(
                imageUrl: p.thumbnailUrl,
                title: p.title,
                width: 48,
                height: 48,
              ),
            ),
            const SizedBox(width: 10),
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
                      color: AppColors.ctaTerracotta,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryForestGreenLight,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
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
        padding: EdgeInsets.all(message.hasMedia ? 8 : 12),
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
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Image Bubble Content
            if (message.isImage) ...[
              GestureDetector(
                onTap: () => _openFullScreenImage(context, message),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      _buildRawImageWidget(
                        message,
                        width: 210,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: DesignTokens.borderRadiusFull,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.zoom_in_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Xem lớn',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (message.content.isNotEmpty) const SizedBox(height: 6),
            ],

            // Video Bubble Content
            if (message.isVideo) ...[
              GestureDetector(
                onTap: () => _openVideoPreviewDialog(context, message),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.12)
                        : AppColors.canvasParchment,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.22)
                          : AppColors.borderWarm,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.ctaTerracotta,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.mediaFileName ?? 'video_san_pham.mp4',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: isMe
                                    ? Colors.white
                                    : AppColors.textCharcoal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Video • ${message.mediaDurationLabel ?? "0:12"} • Chạm để xem',
                              style: AppTypography.caption.copyWith(
                                fontSize: 10.5,
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.78)
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (message.content.isNotEmpty) const SizedBox(height: 6),
            ],

            // Text / Emoji Content
            if (message.content.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: message.hasMedia ? 4 : 2,
                ),
                child: Text(
                  message.content,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isMe ? AppColors.textLight : AppColors.textCharcoal,
                    height: 1.4,
                  ),
                ),
              ),

            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: message.hasMedia ? 4 : 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.75)
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
                          : Colors.white.withValues(alpha: 0.75),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAttachmentPreview() {
    final pending = _pendingAttachment!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(top: BorderSide(color: AppColors.borderWarm)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: pending.mediaType == 'IMAGE'
                ? (pending.mediaBytes != null
                      ? Image.memory(
                          pending.mediaBytes!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : RetroProductImage(
                          imageUrl: pending.mediaPath,
                          title: pending.fileName,
                          width: 48,
                          height: 48,
                        ))
                : Container(
                    width: 48,
                    height: 48,
                    color: AppColors.ctaTerracottaSoft,
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: AppColors.ctaTerracotta,
                      size: 24,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pending.mediaType == 'IMAGE'
                      ? 'Ảnh sắp gửi'
                      : 'Video sắp gửi (${pending.durationLabel ?? "Clip"})',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.pineDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  pending.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textCharcoal,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Gỡ tệp đính kèm',
            onPressed: () => setState(() => _pendingAttachment = null),
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ],
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
              const Icon(Icons.block, size: 18, color: AppColors.statusDanger),
              const SizedBox(width: 8),
              Text(
                'Cuộc trò chuyện này đã bị chặn.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.statusDanger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(top: BorderSide(color: AppColors.borderWarm)),
      ),
      child: SafeArea(
        top: false,
        bottom: !_showEmojiPicker,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Đính kèm ảnh hoặc video',
              onPressed: _openAttachmentPickerSheet,
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.pineDeep,
                size: 24,
              ),
            ),
            IconButton(
              tooltip: 'Chọn biểu tượng cảm xúc',
              onPressed: () {
                if (!_showEmojiPicker) {
                  _inputFocusNode.unfocus();
                }
                setState(() => _showEmojiPicker = !_showEmojiPicker);
              },
              icon: Icon(
                _showEmojiPicker
                    ? Icons.keyboard_rounded
                    : Icons.sentiment_satisfied_alt_outlined,
                color: _showEmojiPicker
                    ? AppColors.ctaTerracotta
                    : AppColors.textMuted,
                size: 24,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _inputFocusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendMessage(),
                decoration: InputDecoration(
                  hintText: _pendingAttachment != null
                      ? 'Thêm chú thích (tuỳ chọn)...'
                      : 'Nhập tin nhắn trao đổi...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.canvasParchment,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
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
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.ctaTerracotta,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: 'Gửi tin nhắn',
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
                        color: Colors.white,
                        size: 19,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPickerPanel() {
    return Container(
      height: 210,
      color: AppColors.surfaceCard,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Biểu tượng cảm xúc',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _showEmojiPicker = false),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                itemCount: _curatedEmojis.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final emoji = _curatedEmojis[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _insertEmoji(emoji),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _AttachmentActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
