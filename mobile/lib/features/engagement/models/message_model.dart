import '../../../core/utils/safe_json_parser.dart';
import 'chat_context_card_model.dart';

/// Individual message inside a conversation room
class MessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final int? attachedProductId;
  final ChatContextCardModel? attachedProduct;
  final bool isMine;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    this.attachedProductId,
    this.attachedProduct,
    this.isMine = false,
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    final senderId = SafeJsonParser.toInt(json['sender_id']);
    String sName = 'Người dùng';
    String? sAvatar;

    if (json['sender'] is Map) {
      final sMap = json['sender'] as Map;
      sName = SafeJsonParser.toStringValue(sMap['display_name'], defaultValue: sName);
      sAvatar = SafeJsonParser.toNullableString(sMap['avatar_url']);
    }

    final isMine = (currentUserId != null && senderId == currentUserId) ||
        SafeJsonParser.toBool(json['is_mine'], defaultValue: false);

    ChatContextCardModel? attached;
    if (json['attached_product'] is Map) {
      attached = ChatContextCardModel.fromProductJson(Map<String, dynamic>.from(json['attached_product'] as Map));
    }

    return MessageModel(
      id: SafeJsonParser.toInt(json['id']),
      conversationId: SafeJsonParser.toInt(json['conversation_id']),
      senderId: senderId,
      senderName: sName,
      senderAvatarUrl: sAvatar,
      content: SafeJsonParser.toStringValue(json['message_text'] ?? json['content']),
      attachedProductId: SafeJsonParser.toNullableInt(json['attached_product_id']),
      attachedProduct: attached,
      isMine: isMine,
      isRead: SafeJsonParser.toBool(json['is_read'], defaultValue: false),
      createdAt: SafeJsonParser.toNullableDateTime(json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender': {
        'id': senderId,
        'display_name': senderName,
        'avatar_url': senderAvatarUrl,
      },
      'message_text': content,
      'attached_product_id': attachedProductId,
      'attached_product': attachedProduct?.toJson(),
      'is_mine': isMine,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
