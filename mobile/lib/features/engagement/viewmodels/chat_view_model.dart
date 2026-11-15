import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/lifecycle_polling_controller.dart';
import '../../../core/state/base_view_model.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/violation_report_payload.dart';
import '../repositories/communication_engagement_repository.dart';

/// ViewModel managing Inbox conversations (M-CM-01), 1-on-1 Chat Room (M-CM-02),
/// HTTP Short-Polling ?after_id= (ADR-08), and Violation Reporting / Blocking (M-CM-03).
class ChatViewModel extends BaseViewModel<List<ConversationModel>> {
  final CommunicationEngagementRepository repository;
  final int? currentUserId;
  final bool enablePolling;

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

  ChatViewModel({
    required this.repository,
    this.currentUserId,
    this.enablePolling = true,
  });

  List<ConversationModel> get conversations => List.unmodifiable(_conversations);
  int get totalUnreadCount => _totalUnreadCount;
  ConversationModel? get currentConversation => _currentConversation;
  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isSendingMessage => _isSendingMessage;
  bool get isBlocked => _isBlocked;
  bool get isReporting => _isReporting;
  LifecyclePollingController? get pollingController => _pollingController;

  // ==========================================
  // INBOX ACTIONS (M-CM-01)
  // ==========================================

  /// Loads inbox conversations and aggregates unread messages
  Future<void> loadInbox() async {
    setLoading();
    try {
      final res = await repository.fetchConversations(currentUserId: currentUserId);
      _conversations.clear();
      _conversations.addAll(res.items);
      _totalUnreadCount = _conversations.fold(0, (sum, c) => sum + c.unreadCount);
      setSuccess(List.unmodifiable(_conversations));
    } catch (e) {
      setError(e.toString());
    }
  }

  // ==========================================
  // ACTIVE CHAT ROOM ACTIONS (M-CM-02)
  // ==========================================

  /// Enters a chat room, fetches initial history, and starts controlled polling
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

      _currentConversation = conv;
      _isBlocked = conv.isBlocked;
      _messages.addAll(msgList);

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
      setError(e.toString());
    }
  }

  /// Incremental polling of new messages (?after_id={lastId}) conforming to ADR-08 & NFR-PER-03
  Future<void> _pollNewMessages(int conversationId) async {
    if (_isBlocked || _currentConversation == null) return;
    final int? lastId = _messages.isNotEmpty ? _messages.last.id : null;

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

  /// Sends a new message in current chat room
  Future<bool> sendMessage(String text, {int? attachedProductId}) async {
    if (_currentConversation == null || _isBlocked) return false;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    _isSendingMessage = true;
    notifyListeners();

    try {
      final newMsg = await repository.sendMessage(
        _currentConversation!.id,
        content: trimmed,
        attachedProductId: attachedProductId,
        currentUserId: currentUserId,
      );

      _messages.add(newMsg);

      // Update local inbox preview
      final idx = _conversations.indexWhere((c) => c.id == _currentConversation!.id);
      if (idx != -1) {
        _conversations[idx] = _conversations[idx].copyWith(
          lastMessagePreview: trimmed,
          lastMessageAt: DateTime.now(),
        );
      }

      _isSendingMessage = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSendingMessage = false;
      notifyListeners();
      return false;
    }
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
        _isBlocked = true;
        _pollingController?.pause();
        if (_currentConversation != null) {
          _currentConversation = _currentConversation!.copyWith(isBlocked: true);
        }
      }

      _isReporting = false;
      notifyListeners();
      return success;
    } catch (_) {
      _isReporting = false;
      notifyListeners();
      return false;
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
final chatViewModelProvider = ChangeNotifierProvider.autoDispose<ChatViewModel>((ref) {
  final repo = ref.watch(communicationEngagementRepositoryProvider);
  final authVm = ref.watch(authViewModelProvider);
  final vm = ChatViewModel(
    repository: repo,
    currentUserId: authVm.currentUser?.id,
  );
  vm.loadInbox();
  return vm;
});
