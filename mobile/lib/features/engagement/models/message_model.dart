import 'dart:typed_data';

import '../../../core/utils/safe_json_parser.dart';
import 'chat_context_card_model.dart';

/// Individual message inside a conversation room.
/// Supports text, emoji, attached products, and image/video attachments
/// (remote URLs or local/demo previews when backend upload is unavailable).
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

  /// Media attachment support: `'TEXT'` | `'IMAGE'` | `'VIDEO'`.
  final String mediaType;
  final String? mediaPath;
  final Uint8List? mediaBytes;
  final String? mediaFileName;
  final String? mediaDurationLabel;
  final bool isLocalDemoAttachment;

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
    this.mediaType = 'TEXT',
    this.mediaPath,
    this.mediaBytes,
    this.mediaFileName,
    this.mediaDurationLabel,
    this.isLocalDemoAttachment = false,
  });

  bool get isImage => mediaType.toUpperCase() == 'IMAGE';
  bool get isVideo => mediaType.toUpperCase() == 'VIDEO';
  bool get hasMedia => isImage || isVideo;

  factory MessageModel.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
  }) {
    final senderId = SafeJsonParser.toInt(json['sender_id']);
    String sName = 'Người dùng';
    String? sAvatar;

    if (json['sender'] is Map) {
      final sMap = json['sender'] as Map;
      sName = SafeJsonParser.toStringValue(
        sMap['display_name'],
        defaultValue: sName,
      );
      sAvatar = SafeJsonParser.toNullableString(sMap['avatar_url']);
    }

    final isMine =
        (currentUserId != null && senderId == currentUserId) ||
        SafeJsonParser.toBool(json['is_mine'], defaultValue: false);

    ChatContextCardModel? attached;
    if (json['attached_product'] is Map) {
      attached = ChatContextCardModel.fromProductJson(
        Map<String, dynamic>.from(json['attached_product'] as Map),
      );
    }

    final mediaType = SafeJsonParser.toStringValue(
      json['media_type'],
      defaultValue: 'TEXT',
    ).toUpperCase();

    return MessageModel(
      id: SafeJsonParser.toInt(json['id']),
      conversationId: SafeJsonParser.toInt(json['conversation_id']),
      senderId: senderId,
      senderName: sName,
      senderAvatarUrl: sAvatar,
      content: SafeJsonParser.toStringValue(
        json['message_text'] ?? json['content'],
      ),
      attachedProductId: SafeJsonParser.toNullableInt(
        json['attached_product_id'],
      ),
      attachedProduct: attached,
      isMine: isMine,
      isRead: SafeJsonParser.toBool(json['is_read'], defaultValue: false),
      createdAt:
          SafeJsonParser.toNullableDateTime(json['created_at']) ??
          DateTime.now(),
      mediaType: mediaType,
      mediaPath: SafeJsonParser.toNullableString(
        json['media_url'] ?? json['media_path'],
      ),
      mediaFileName: SafeJsonParser.toNullableString(json['media_file_name']),
      mediaDurationLabel: SafeJsonParser.toNullableString(
        json['media_duration_label'],
      ),
      isLocalDemoAttachment: SafeJsonParser.toBool(
        json['is_local_demo_attachment'],
        defaultValue: false,
      ),
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
      'media_type': mediaType,
      if (mediaPath != null) 'media_path': mediaPath,
      if (mediaFileName != null) 'media_file_name': mediaFileName,
      if (mediaDurationLabel != null)
        'media_duration_label': mediaDurationLabel,
      if (isLocalDemoAttachment) 'is_local_demo_attachment': true,
    };
  }
}
