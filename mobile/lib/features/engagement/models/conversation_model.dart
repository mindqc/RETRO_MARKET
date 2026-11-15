import '../../../core/utils/safe_json_parser.dart';
import 'chat_context_card_model.dart';

class ConversationPartner {
  final int id;
  final String displayName;
  final String? avatarUrl;
  final String? shopSlug;
  final double trustScore;

  const ConversationPartner({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.shopSlug,
    this.trustScore = 100.0,
  });
}

/// Conversation summary item in the inbox (M-CM-01) and chat room (M-CM-02)
class ConversationModel {
  final int id;
  final int partnerId;
  final String partnerName;
  final String? partnerShopSlug;
  final String? partnerAvatarUrl;
  final double partnerTrustScore;
  final bool isOnline;
  final bool isBlocked;
  final int? blockedByUserId;
  final int unreadCount;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final ChatContextCardModel? pinnedContext;

  const ConversationModel({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    this.partnerShopSlug,
    this.partnerAvatarUrl,
    this.partnerTrustScore = 100.0,
    this.isOnline = false,
    this.isBlocked = false,
    this.blockedByUserId,
    this.unreadCount = 0,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.pinnedContext,
  });

  ConversationPartner get otherUser => ConversationPartner(
        id: partnerId,
        displayName: partnerName,
        avatarUrl: partnerAvatarUrl,
        shopSlug: partnerShopSlug,
        trustScore: partnerTrustScore,
      );

  ChatContextCardModel? get contextProduct =>
      pinnedContext?.contextType == 'PRODUCT' ? pinnedContext : null;

  ChatContextCardModel? get contextOrder =>
      pinnedContext?.contextType == 'ORDER' ? pinnedContext : null;

  String get formattedTime {
    if (lastMessageAt == null) return '';
    final h = lastMessageAt!.hour.toString().padLeft(2, '0');
    final m = lastMessageAt!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    int pId = 0;
    String pName = 'Người dùng Retro';
    String? pAvatar;
    String? pSlug;
    double pTrust = 100.0;

    if (json['other_user'] is Map) {
      final oMap = json['other_user'] as Map;
      pId = SafeJsonParser.toInt(oMap['id']);
      pName = SafeJsonParser.toStringValue(oMap['display_name'], defaultValue: pName);
      pAvatar = SafeJsonParser.toNullableString(oMap['avatar_url']);
      pSlug = SafeJsonParser.toNullableString(oMap['shop_slug']);
      pTrust = SafeJsonParser.toDouble(oMap['trust_score'], defaultValue: 100.0);
    } else {
      // Fallback if partner is resolved via user_one_id / user_two_id
      final u1 = SafeJsonParser.toInt(json['user_one_id']);
      final u2 = SafeJsonParser.toInt(json['user_two_id']);
      pId = (currentUserId != null && u1 == currentUserId) ? u2 : u1;
      pName = SafeJsonParser.toStringValue(json['partner_name'], defaultValue: pName);
      pAvatar = SafeJsonParser.toNullableString(json['partner_avatar_url']);
      pSlug = SafeJsonParser.toNullableString(json['partner_shop_slug']);
    }

    ChatContextCardModel? pinned;
    if (json['context_product'] is Map) {
      pinned = ChatContextCardModel.fromProductJson(Map<String, dynamic>.from(json['context_product'] as Map));
    } else if (json['context_order'] is Map) {
      pinned = ChatContextCardModel.fromOrderJson(Map<String, dynamic>.from(json['context_order'] as Map));
    }

    final blockedId = SafeJsonParser.toNullableInt(json['blocked_by_user_id']);
    final isBlocked = SafeJsonParser.toBool(json['is_blocked'], defaultValue: blockedId != null);

    return ConversationModel(
      id: SafeJsonParser.toInt(json['id']),
      partnerId: pId,
      partnerName: pName,
      partnerShopSlug: pSlug,
      partnerAvatarUrl: pAvatar,
      partnerTrustScore: pTrust,
      isOnline: SafeJsonParser.toBool(json['is_online'], defaultValue: false),
      isBlocked: isBlocked,
      blockedByUserId: blockedId,
      unreadCount: SafeJsonParser.toInt(json['unread_count'], defaultValue: 0),
      lastMessagePreview: SafeJsonParser.toNullableString(json['last_message_preview']),
      lastMessageAt: SafeJsonParser.toNullableDateTime(json['last_message_at']),
      pinnedContext: pinned,
    );
  }

  ConversationModel copyWith({
    bool? isBlocked,
    int? blockedByUserId,
    int? unreadCount,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    ChatContextCardModel? pinnedContext,
  }) {
    return ConversationModel(
      id: id,
      partnerId: partnerId,
      partnerName: partnerName,
      partnerShopSlug: partnerShopSlug,
      partnerAvatarUrl: partnerAvatarUrl,
      partnerTrustScore: partnerTrustScore,
      isOnline: isOnline,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedByUserId: blockedByUserId ?? this.blockedByUserId,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      pinnedContext: pinnedContext ?? this.pinnedContext,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'other_user': {
        'id': partnerId,
        'display_name': partnerName,
        'avatar_url': partnerAvatarUrl,
        'shop_slug': partnerShopSlug,
        'trust_score': partnerTrustScore,
      },
      'is_online': isOnline,
      'is_blocked': isBlocked,
      'blocked_by_user_id': blockedByUserId,
      'unread_count': unreadCount,
      'last_message_preview': lastMessagePreview,
      'last_message_at': lastMessageAt?.toIso8601String(),
      if (pinnedContext?.contextType == 'PRODUCT') 'context_product': pinnedContext?.toJson(),
      if (pinnedContext?.contextType == 'ORDER') 'context_order': pinnedContext?.toJson(),
    };
  }
}
