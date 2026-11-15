import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/safe_json_parser.dart';
import '../../catalog/models/product_summary_model.dart';
import '../../catalog/models/review_item_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/notification_item_model.dart';
import '../models/seller_reviews_summary_model.dart';
import '../models/violation_report_payload.dart';

/// Unified Repository managing 1-on-1 Chat, Notifications, Violation Reports, Favorites & Reviews (P7-11)
class CommunicationEngagementRepository {
  final DioClient dioClient;

  CommunicationEngagementRepository({required this.dioClient});

  // ==========================================
  // CHAT & CONVERSATION ENDPOINTS (M-CM-01..03)
  // ==========================================

  /// Lists all conversations for current authenticated user (M-CM-01)
  /// GET /api/v1/conversations
  Future<PaginatedResponse<ConversationModel>> fetchConversations({
    int page = 1,
    int perPage = 15,
    int? currentUserId,
  }) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.conversations,
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );

    return PaginatedResponse.fromJson(
      response.data ?? {},
      (json) => ConversationModel.fromJson(json as Map<String, dynamic>, currentUserId: currentUserId),
    );
  }

  /// Start a new conversation or retrieve existing one with partner and optional context
  /// POST /api/v1/conversations
  Future<ConversationModel> startOrGetConversation({
    required int recipientId,
    int? contextProductId,
    int? contextOrderId,
    String? initialMessage,
    int? currentUserId,
  }) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.conversations,
      data: {
        'recipient_id': recipientId,
        'context_product_id': ?contextProductId,
        'context_order_id': ?contextOrderId,
        'initial_message': ?initialMessage,
      },
    );

    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return ConversationModel.fromJson(data, currentUserId: currentUserId);
  }

  /// Incremental short-polling of conversation messages (ADR-08 / M-CM-02)
  /// GET /api/v1/conversations/{id}/messages?after_id={afterId}
  Future<Map<String, dynamic>> fetchMessages(
    int conversationId, {
    int? afterId,
    int limit = 50,
    int? currentUserId,
  }) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.conversationMessages(conversationId),
      queryParameters: {
        'after_id': ?afterId,
        'limit': limit,
      },
    );

    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    final convData = data['conversation'] as Map<String, dynamic>? ?? {};
    final rawMessages = data['messages'] as List? ?? [];

    final List<MessageModel> messages = [];
    for (final item in rawMessages) {
      if (item is Map<String, dynamic>) {
        messages.add(MessageModel.fromJson(item, currentUserId: currentUserId));
      } else if (item is Map) {
        messages.add(MessageModel.fromJson(Map<String, dynamic>.from(item), currentUserId: currentUserId));
      }
    }

    return {
      'conversation': ConversationModel.fromJson(convData, currentUserId: currentUserId),
      'messages': messages,
    };
  }

  /// Send a message in a conversation room
  /// POST /api/v1/conversations/{id}/messages
  Future<MessageModel> sendMessage(
    int conversationId, {
    required String content,
    int? attachedProductId,
    int? currentUserId,
  }) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.conversationMessages(conversationId),
      data: {
        'message_text': content,
        'attached_product_id': ?attachedProductId,
      },
    );

    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return MessageModel.fromJson(data, currentUserId: currentUserId);
  }

  /// Submit a violation report and optionally block conversation (M-CM-03)
  /// POST /api/v1/reports
  Future<bool> submitReport(ViolationReportPayload payload) async {
    await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.reports,
      data: payload.toJson(),
    );
    return true;
  }

  // ==========================================
  // NOTIFICATIONS ENDPOINTS (M-NT-01)
  // ==========================================

  /// Lists user notifications with category filter (M-NT-01)
  /// GET /api/v1/notifications
  Future<Map<String, dynamic>> fetchNotifications({
    String? category,
    int page = 1,
    int perPage = 15,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      'category': ?category,
    };

    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.notifications,
      queryParameters: queryParams,
    );

    final data = response.data ?? {};
    final rawList = data['data'] as List? ?? [];
    final List<NotificationItemModel> items = [];

    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        items.add(NotificationItemModel.fromJson(item));
      } else if (item is Map) {
        items.add(NotificationItemModel.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    final metaJson = data['meta'] as Map<String, dynamic>?;
    final meta = PaginationMeta.fromJson(metaJson);
    final unreadCount = SafeJsonParser.toInt(data['unread_count'] ?? metaJson?['unread_count'], defaultValue: 0);

    return {
      'items': items,
      'unread_count': unreadCount,
      'meta': meta,
    };
  }

  /// Mark single notification as read
  /// POST /api/v1/notifications/{id}/read
  Future<bool> markNotificationAsRead(int notificationId) async {
    await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.markNotificationRead(notificationId),
    );
    return true;
  }

  /// Mark all notifications as read
  /// POST /api/v1/notifications/read-all
  Future<int> markAllNotificationsAsRead() async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.markAllNotificationsRead,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return SafeJsonParser.toInt(data['marked_count'], defaultValue: 0);
  }

  // ==========================================
  // FAVORITES & ENGAGEMENT ENDPOINTS (M-PF-05)
  // ==========================================

  /// List user's favorite products (M-PF-05)
  /// GET /api/v1/profile/favorites
  Future<PaginatedResponse<ProductSummaryModel>> fetchFavorites({
    int page = 1,
    int perPage = 12,
  }) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.myFavorites,
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );

    return PaginatedResponse.fromJson(
      response.data ?? {},
      (json) => ProductSummaryModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Toggle favorite status of a product (M-PF-05)
  /// POST /api/v1/products/{id}/favorite
  Future<bool> toggleFavorite(int productId) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.toggleFavorite(productId),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return SafeJsonParser.toBool(data['is_favorited'], defaultValue: false);
  }

  /// Toggle follow status of a seller shop (M-PF-05 / BR-AC-02)
  /// POST /api/v1/sellers/{id}/follow
  Future<bool> toggleFollowSeller(int sellerId) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.sellerFollow(sellerId),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return SafeJsonParser.toBool(data['is_following'], defaultValue: false);
  }

  // ==========================================
  // VERIFIED REVIEWS ENDPOINTS (M-RV-01..02)
  // ==========================================

  /// Submit verified review for completed order (M-RV-01 / BR-RV-01)
  /// POST /api/v1/orders/{id}/reviews
  Future<ReviewItemModel> submitVerifiedReview(
    int orderId, {
    required int rating,
    required String comment,
  }) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.submitReview(orderId),
      data: {
        'rating': rating,
        'comment': comment,
      },
    );

    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return ReviewItemModel.fromJson(data);
  }

  /// Fetch seller verified reviews with optional rating filter (M-RV-02)
  /// GET /api/v1/sellers/{id}/reviews
  Future<SellerReviewsSummaryModel> fetchSellerReviews(
    int sellerId, {
    int? ratingFilter,
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.sellerReviews(sellerId),
      queryParameters: {
        'page': page,
        'per_page': perPage,
        'rating': ?ratingFilter,
      },
    );

    final data = response.data ?? {};
    return SellerReviewsSummaryModel.fromJson(data);
  }
}

/// Riverpod provider for CommunicationEngagementRepository
final communicationEngagementRepositoryProvider = Provider<CommunicationEngagementRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CommunicationEngagementRepository(dioClient: dioClient);
});
