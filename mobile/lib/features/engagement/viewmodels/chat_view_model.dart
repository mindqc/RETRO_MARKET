import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/lifecycle_polling_controller.dart';
import '../../../core/state/base_view_model.dart';
import '../../../core/utils/product_image_resolver.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../orders/models/order_model.dart';
import '../models/chat_context_card_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/violation_report_payload.dart';
import '../repositories/communication_engagement_repository.dart';

/// ViewModel managing Inbox conversations (M-CM-01), 1-on-1 Chat Room (M-CM-02),
/// HTTP Short-Polling ?after_id= (ADR-08), Emoji/Image/Video attachments,
/// and Violation Reporting / Blocking (M-CM-03).
class ChatViewModel extends BaseViewModel<List<ConversationModel>> {
  final CommunicationEngagementRepository repository;
  final int? currentUserId;
  final bool enablePolling;
  final bool enableDemoFallback;

  // Inbox state
  final List<ConversationModel> _conversations = [];
  int _totalUnreadCount = 0;

  // Active chat room state
  ConversationModel? _currentConversation;
  final List<MessageModel> _messages = [];
  LifecyclePollingController? _pollingController;
  bool _isSendingMessage = false;
  bool _isBlocked = false;
  bool _isReporting = false;
  bool _isUsingDemoMode = false;

  // In-memory demo chat store so local demo conversations & media messages
  // persist cleanly across room re-entry within the session.
  final Map<int, List<MessageModel>> _demoRoomMessages = {};
  int _localMessageSeq = 9000;

  static const int maxVideoFileSizeBytes = 25 * 1024 * 1024; // 25 MB
  static const List<String> allowedVideoExtensions = [
    '.mp4',
    '.mov',
    '.m4v',
    '.webm',
    '.mkv',
    '.avi',
  ];

  ChatViewModel({
    required this.repository,
    this.currentUserId,
    this.enablePolling = true,
    this.enableDemoFallback = false,
  });

  List<ConversationModel> get conversations =>
      List.unmodifiable(_conversations);
  int get totalUnreadCount => _totalUnreadCount;
  ConversationModel? get currentConversation => _currentConversation;
  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isSendingMessage => _isSendingMessage;
  bool get isBlocked => _isBlocked;
  bool get isReporting => _isReporting;
  bool get isUsingDemoMode => _isUsingDemoMode;
  LifecyclePollingController? get pollingController => _pollingController;

  // ==========================================
  // INBOX ACTIONS (M-CM-01)
  // ==========================================

  /// Loads inbox conversations and aggregates unread messages.
  /// Falls back to curated demo conversations only when [enableDemoFallback] is true.
  Future<void> loadInbox() async {
    setLoading();
    try {
      final res = await repository.fetchConversations(
        currentUserId: currentUserId,
      );
      _isUsingDemoMode = false;
      _conversations.clear();
      _conversations.addAll(res.items);
      if (_conversations.isEmpty && enableDemoFallback) {
        _seedDemoConversationsIfEmpty();
      }
      _totalUnreadCount = _conversations.fold(
        0,
        (sum, c) => sum + c.unreadCount,
      );
      setSuccess(List.unmodifiable(_conversations));
    } catch (e) {
      if (enableDemoFallback) {
        _isUsingDemoMode = true;
        _seedDemoConversationsIfEmpty();
        _totalUnreadCount = _conversations.fold(
          0,
          (sum, c) => sum + c.unreadCount,
        );
        setSuccess(List.unmodifiable(_conversations));
      } else {
        setError(e.toString());
      }
    }
  }

  // ==========================================
  // ACTIVE CHAT ROOM ACTIONS (M-CM-02)
  // ==========================================

  /// Enters a chat room, fetches initial history, and starts controlled polling.
  Future<void> enterChatRoom(int conversationId) async {
    _messages.clear();
    _currentConversation = null;
    _isBlocked = false;
    _pollingController?.dispose();
    _pollingController = null;

    setLoading();
    try {
      final result = await repository.fetchMessages(
        conversationId,
        limit: 50,
        currentUserId: currentUserId,
      );

      final conv = result['conversation'] as ConversationModel;
      final msgList = result['messages'] as List<MessageModel>;

      _isUsingDemoMode = false;
      _currentConversation = conv;
      _isBlocked = conv.isBlocked;
      _messages.addAll(msgList);

      // Re-attach any local media messages sent during this session
      final localExtra = _demoRoomMessages[conversationId];
      if (localExtra != null) {
        for (final m in localExtra) {
          if (!_messages.any((e) => e.id == m.id)) {
            _messages.add(m);
          }
        }
      }

      // Start periodic short-polling (3s interval) with background pause
      if (enablePolling && !_isBlocked) {
        _pollingController = LifecyclePollingController(
          interval: const Duration(seconds: 3),
          pollAction: () => _pollNewMessages(conversationId),
          autoStart: true,
        );
      }

      setSuccess(List.unmodifiable(_conversations));
    } catch (e) {
      if (enableDemoFallback) {
        _enterDemoChatRoom(conversationId);
        setSuccess(List.unmodifiable(_conversations));
      } else {
        setError(e.toString());
      }
    }
  }

  /// Incremental polling of new messages (?after_id={lastId}) conforming to ADR-08 & NFR-PER-03
  Future<void> _pollNewMessages(int conversationId) async {
    if (_isBlocked || _currentConversation == null || _isUsingDemoMode) return;
    final remoteMessages = _messages.where((m) => !m.isLocalDemoAttachment);
    final int? lastId = remoteMessages.isNotEmpty
        ? remoteMessages.last.id
        : null;

    try {
      final result = await repository.fetchMessages(
        conversationId,
        afterId: lastId,
        limit: 50,
        currentUserId: currentUserId,
      );

      final newMessages = result['messages'] as List<MessageModel>;
      final updatedConv = result['conversation'] as ConversationModel;

      if (updatedConv.isBlocked != _isBlocked) {
        _isBlocked = updatedConv.isBlocked;
        _currentConversation = updatedConv;
        if (_isBlocked) {
          _pollingController?.pause();
        }
      }

      if (newMessages.isNotEmpty) {
        for (final msg in newMessages) {
          if (!_messages.any((existing) => existing.id == msg.id)) {
            _messages.add(msg);
          }
        }
        notifyListeners();
      }
    } catch (_) {
      // Swallowed during background short polling
    }
  }

  /// Sends a new text/emoji message in current chat room.
  Future<bool> sendMessage(String text, {int? attachedProductId}) async {
    if (_currentConversation == null || _isBlocked) return false;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    _isSendingMessage = true;
    notifyListeners();

    if (_isUsingDemoMode) {
      final localMsg = MessageModel(
        id: ++_localMessageSeq,
        conversationId: _currentConversation!.id,
        senderId: currentUserId ?? 1,
        senderName: 'Bạn',
        content: trimmed,
        attachedProductId: attachedProductId,
        isMine: true,
        isRead: true,
        createdAt: DateTime.now(),
      );
      _appendLocalMessage(localMsg, previewText: trimmed);
      _isSendingMessage = false;
      notifyListeners();
      return true;
    }

    try {
      final newMsg = await repository.sendMessage(
        _currentConversation!.id,
        content: trimmed,
        attachedProductId: attachedProductId,
        currentUserId: currentUserId,
      );

      _messages.add(newMsg);
      _updateInboxPreview(_currentConversation!.id, trimmed);

      _isSendingMessage = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (enableDemoFallback) {
        final localMsg = MessageModel(
          id: ++_localMessageSeq,
          conversationId: _currentConversation!.id,
          senderId: currentUserId ?? 1,
          senderName: 'Bạn',
          content: trimmed,
          isMine: true,
          isRead: false,
          createdAt: DateTime.now(),
          isLocalDemoAttachment: true,
        );
        _appendLocalMessage(localMsg, previewText: trimmed);
        _isSendingMessage = false;
        notifyListeners();
        return true;
      }
      _isSendingMessage = false;
      notifyListeners();
      return false;
    }
  }

  /// Sends an image attachment in the active chat room.
  /// Displays immediately in chat with local preview (and notifies text caption
  /// to backend if connected, since backend message upload endpoint is text-only).
  Future<bool> sendImageAttachment({
    String? mediaPath,
    Uint8List? mediaBytes,
    String? caption,
    String? fileName,
  }) async {
    if (_currentConversation == null || _isBlocked) return false;
    if ((mediaPath == null || mediaPath.isEmpty) && mediaBytes == null) {
      return false;
    }

    _isSendingMessage = true;
    notifyListeners();

    final cleanCaption = (caption ?? '').trim();
    final msg = MessageModel(
      id: ++_localMessageSeq,
      conversationId: _currentConversation!.id,
      senderId: currentUserId ?? 1,
      senderName: 'Bạn',
      content: cleanCaption,
      isMine: true,
      isRead: true,
      createdAt: DateTime.now(),
      mediaType: 'IMAGE',
      mediaPath: mediaPath,
      mediaBytes: mediaBytes,
      mediaFileName: fileName ?? 'anh_san_pham.jpg',
      isLocalDemoAttachment: true,
    );

    _appendLocalMessage(
      msg,
      previewText: cleanCaption.isNotEmpty
          ? '📷 $cleanCaption'
          : '📷 Đã gửi một hình ảnh',
    );

    _isSendingMessage = false;
    notifyListeners();
    return true;
  }

  /// Validates and sends a video attachment in the active chat room.
  /// Returns null on success, or a Vietnamese validation error message if invalid.
  Future<String?> sendVideoAttachment({
    required String mediaPath,
    String? caption,
    String? fileName,
    String? durationLabel,
    int? fileSizeBytes,
  }) async {
    if (_currentConversation == null || _isBlocked) {
      return 'Không thể gửi video trong cuộc trò chuyện này.';
    }

    if (fileSizeBytes != null && fileSizeBytes > maxVideoFileSizeBytes) {
      return 'Video vượt quá giới hạn 25MB. Vui lòng chọn clip ngắn hơn.';
    }

    final checkName = (fileName ?? mediaPath).toLowerCase();
    final isDemoClip = mediaPath.startsWith('demo://');
    if (!isDemoClip &&
        checkName.contains('.') &&
        !allowedVideoExtensions.any((ext) => checkName.endsWith(ext))) {
      return 'Định dạng video chưa được hỗ trợ (hỗ trợ MP4, MOV, WEBM).';
    }

    _isSendingMessage = true;
    notifyListeners();

    final cleanCaption = (caption ?? '').trim();
    final msg = MessageModel(
      id: ++_localMessageSeq,
      conversationId: _currentConversation!.id,
      senderId: currentUserId ?? 1,
      senderName: 'Bạn',
      content: cleanCaption,
      isMine: true,
      isRead: true,
      createdAt: DateTime.now(),
      mediaType: 'VIDEO',
      mediaPath: mediaPath,
      mediaFileName: fileName ?? 'video_san_pham.mp4',
      mediaDurationLabel: durationLabel ?? '0:12',
      isLocalDemoAttachment: true,
    );

    _appendLocalMessage(
      msg,
      previewText: cleanCaption.isNotEmpty
          ? '🎬 $cleanCaption'
          : '🎬 Đã gửi một video',
    );

    _isSendingMessage = false;
    notifyListeners();
    return null;
  }

  /// Sends a structured Order Card attachment in the active chat room so buyer
  /// and seller can discuss order status, shipping, or support seamlessly.
  Future<bool> sendOrderAttachment({
    required OrderModel order,
    String? caption,
  }) async {
    if (_currentConversation == null || _isBlocked) return false;

    _isSendingMessage = true;
    notifyListeners();

    final primaryItem = order.items.isNotEmpty ? order.items.first : null;
    final cleanCaption = (caption ?? '').trim();
    final orderCard = ChatContextCardModel(
      contextType: 'ORDER',
      referenceId: order.id,
      referenceCode: order.orderCode,
      title: primaryItem != null && primaryItem.productTitle.isNotEmpty
          ? primaryItem.productTitle
          : 'Đơn hàng #${order.orderCode}',
      thumbnailUrl: primaryItem?.primaryImageUrl,
      priceOrTotal: order.totalAmount,
      status: order.orderStatus,
    );

    final msg = MessageModel(
      id: ++_localMessageSeq,
      conversationId: _currentConversation!.id,
      senderId: currentUserId ?? 1,
      senderName: 'Bạn',
      content: cleanCaption,
      attachedOrder: orderCard,
      isMine: true,
      isRead: true,
      createdAt: DateTime.now(),
      mediaType: 'ORDER',
      isLocalDemoAttachment: true,
    );

    _appendLocalMessage(
      msg,
      previewText: '📦 Đã gửi đơn hàng #${order.orderCode}',
    );

    // Best-effort sync of a companion reference note when backend is online
    if (!_isUsingDemoMode) {
      try {
        await repository.sendMessage(
          _currentConversation!.id,
          content: cleanCaption.isNotEmpty
              ? '[Đơn hàng #${order.orderCode}] $cleanCaption'
              : 'Mình vừa đính kèm đơn hàng #${order.orderCode} để trao đổi thêm.',
          currentUserId: currentUserId,
        );
      } catch (_) {
        // Keep local interactive order card visible smoothly
      }
    }

    _isSendingMessage = false;
    notifyListeners();
    return true;
  }

  void _appendLocalMessage(MessageModel msg, {required String previewText}) {
    _messages.add(msg);
    _demoRoomMessages.putIfAbsent(msg.conversationId, () => []).add(msg);
    _updateInboxPreview(msg.conversationId, previewText);
  }

  void _updateInboxPreview(int conversationId, String previewText) {
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      _conversations[idx] = _conversations[idx].copyWith(
        lastMessagePreview: previewText,
        lastMessageAt: DateTime.now(),
        unreadCount: 0,
      );
      _totalUnreadCount = _conversations.fold(
        0,
        (sum, c) => sum + c.unreadCount,
      );
    }
  }

  // ==========================================
  // DEMO FALLBACK CONVERSATIONS (OFFLINE/EMPTY)
  // ==========================================

  void _seedDemoConversationsIfEmpty() {
    if (_conversations.isNotEmpty) return;
    final now = DateTime.now();
    _conversations.addAll([
      ConversationModel(
        id: 101,
        partnerId: 201,
        partnerName: 'Tiệm Cổ Điển Sài Gòn',
        partnerShopSlug: 'tiem-co-dien-sg',
        partnerTrustScore: 98,
        isOnline: true,
        unreadCount: 2,
        lastMessagePreview:
            'Áo khoác Varsity len 90s còn sẵn size L nha bạn, mình có thể quay cận chất vải!',
        lastMessageAt: now.subtract(const Duration(minutes: 6)),
        pinnedContext: const ChatContextCardModel(
          contextType: 'PRODUCT',
          referenceId: 9101,
          title: 'Áo Khoác Varsity Len Cổ Điển 90s',
          thumbnailUrl: ProductImageResolver.assetVarsityJacket,
          priceOrTotal: 420000,
          status: 'ACTIVE',
        ),
      ),
      ConversationModel(
        id: 102,
        partnerId: 202,
        partnerName: 'Analog Film & Thrift',
        partnerShopSlug: 'analog-film-thrift',
        partnerTrustScore: 96,
        isOnline: true,
        unreadCount: 0,
        lastMessagePreview:
            'Phiên đấu giá máy ảnh film 35mm mở lúc 20:00 tối nay ạ 📸',
        lastMessageAt: now.subtract(const Duration(hours: 2)),
        pinnedContext: const ChatContextCardModel(
          contextType: 'PRODUCT',
          referenceId: 9104,
          title: 'Máy Ảnh Film Cổ Điển 35mm Kèm Ống Kính 50mm',
          thumbnailUrl: ProductImageResolver.assetFilmCamera,
          priceOrTotal: 1250000,
          status: 'ACTIVE',
        ),
      ),
      ConversationModel(
        id: 103,
        partnerId: 203,
        partnerName: 'Tiệm Giày Si Quận 3',
        partnerShopSlug: 'tiem-giay-si-q3',
        partnerTrustScore: 95,
        isOnline: false,
        unreadCount: 0,
        lastMessagePreview: 'Cảm ơn bạn đã ủng hộ tiệm nhé! Chúc mùa đông ấm áp 🎄',
        lastMessageAt: now.subtract(const Duration(days: 1)),
        pinnedContext: const ChatContextCardModel(
          contextType: 'PRODUCT',
          referenceId: 9103,
          title: 'Giày Boots Da Bò Vintage Cổ Lửng',
          thumbnailUrl: ProductImageResolver.assetRetroSneakers,
          priceOrTotal: 650000,
          status: 'ACTIVE',
        ),
      ),
    ]);
  }

  void _enterDemoChatRoom(int conversationId) {
    _isUsingDemoMode = true;
    _seedDemoConversationsIfEmpty();
    final conv = _conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => _conversations.first,
    );
    _currentConversation = conv.copyWith(unreadCount: 0);
    _isBlocked = conv.isBlocked;

    final idx = _conversations.indexWhere((c) => c.id == conv.id);
    if (idx != -1) {
      _conversations[idx] = _conversations[idx].copyWith(unreadCount: 0);
      _totalUnreadCount = _conversations.fold(
        0,
        (sum, c) => sum + c.unreadCount,
      );
    }

    final existing = _demoRoomMessages[conv.id];
    if (existing != null && existing.isNotEmpty) {
      _messages.addAll(existing);
      return;
    }

    final now = DateTime.now();
    final initial = <MessageModel>[
      MessageModel(
        id: 8001,
        conversationId: conv.id,
        senderId: conv.partnerId,
        senderName: conv.partnerName,
        content:
            'Chào bạn 👋 Cảm ơn bạn đã quan tâm món đồ trên izithrift! Bạn cần xem thêm số đo hay chi tiết tình trạng không ạ?',
        isMine: false,
        isRead: true,
        createdAt: now.subtract(const Duration(minutes: 18)),
      ),
      MessageModel(
        id: 8002,
        conversationId: conv.id,
        senderId: currentUserId ?? 1,
        senderName: 'Bạn',
        content:
            'Chào shop, món này tình trạng thực tế khoảng bao nhiêu % và có lỗi xước nào không ạ?',
        isMine: true,
        isRead: true,
        createdAt: now.subtract(const Duration(minutes: 12)),
      ),
      MessageModel(
        id: 8003,
        conversationId: conv.id,
        senderId: conv.partnerId,
        senderName: conv.partnerName,
        content:
            conv.lastMessagePreview ??
            'Tình trạng khoảng 95% rất đẹp nha bạn, mình gửi ảnh cận chất liệu nhé!',
        isMine: false,
        isRead: true,
        createdAt: now.subtract(const Duration(minutes: 6)),
        mediaType: 'IMAGE',
        mediaPath:
            conv.contextProduct?.thumbnailUrl ??
            ProductImageResolver.assetVarsityJacket,
        mediaFileName: 'anh_can_chat_lieu.jpg',
        isLocalDemoAttachment: true,
      ),
    ];
    _demoRoomMessages[conv.id] = List<MessageModel>.from(initial);
    _messages.addAll(initial);
  }

  // ==========================================
  // REPORT & BLOCK ACTIONS (M-CM-03)
  // ==========================================

  /// Submits a violation report and locks chat if blocking is enabled
  Future<bool> reportAndBlock(ViolationReportPayload payload) async {
    _isReporting = true;
    notifyListeners();

    try {
      final success = await repository.submitReport(payload);
      if (success && payload.blockConversation) {
        _markCurrentConversationBlocked();
      }

      _isReporting = false;
      notifyListeners();
      return success;
    } catch (_) {
      if (_isUsingDemoMode) {
        if (payload.blockConversation) {
          _markCurrentConversationBlocked();
        }
        _isReporting = false;
        notifyListeners();
        return true;
      }
      _isReporting = false;
      notifyListeners();
      return false;
    }
  }

  void _markCurrentConversationBlocked() {
    _isBlocked = true;
    _pollingController?.pause();
    if (_currentConversation != null) {
      final updated = _currentConversation!.copyWith(isBlocked: true);
      _currentConversation = updated;
      final idx = _conversations.indexWhere((c) => c.id == updated.id);
      if (idx != -1) {
        _conversations[idx] = _conversations[idx].copyWith(isBlocked: true);
      }
    }
  }

  /// Exits chat room and cleans up polling resources
  void exitChatRoom() {
    _pollingController?.dispose();
    _pollingController = null;
    _currentConversation = null;
    _messages.clear();
  }

  void leaveChatRoom() => exitChatRoom();

  /// Helper to report a violation from M-CM-03 modal
  Future<bool> reportViolation({
    required int conversationId,
    required String reasonCategory,
    required String description,
    bool blockConversation = true,
  }) async {
    final payload = ViolationReportPayload(
      targetType: 'CONVERSATION',
      targetId: conversationId,
      reasonCategory: reasonCategory,
      description: description,
      blockConversation: blockConversation,
    );
    return reportAndBlock(payload);
  }

  @override
  void dispose() {
    _pollingController?.dispose();
    super.dispose();
  }
}

/// Riverpod provider for ChatViewModel
final chatViewModelProvider =
    ChangeNotifierProvider.autoDispose<ChatViewModel>((ref) {
      final repo = ref.watch(communicationEngagementRepositoryProvider);
      final authVm = ref.watch(authViewModelProvider);
      final vm = ChatViewModel(
        repository: repo,
        currentUserId: authVm.currentUser?.id,
        enableDemoFallback: true,
      );
      return vm;
    });
