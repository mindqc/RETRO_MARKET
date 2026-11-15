import '../../../core/utils/safe_json_parser.dart';

/// Notification item model for In-App Notification Center (M-NT-01)
class NotificationItemModel {
  final int id;
  final int userId;
  final String category; // 'ORDER', 'AUCTION', 'SYSTEM'
  final String title;
  final String body;
  final String? targetType;
  final int? targetId;
  final String? deepLinkRoute;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationItemModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.body,
    this.targetType,
    this.targetId,
    this.deepLinkRoute,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    final rawType = SafeJsonParser.toStringValue(
      json['category'] ?? json['type'] ?? json['target_type'],
      defaultValue: 'SYSTEM',
    ).toUpperCase();

    // Normalize category into ORDER, AUCTION, SYSTEM
    String cat = 'SYSTEM';
    if (rawType.contains('ORDER') || rawType.contains('DELIVERY') || rawType.contains('DISPUTE')) {
      cat = 'ORDER';
    } else if (rawType.contains('AUCTION') || rawType.contains('BID')) {
      cat = 'AUCTION';
    }

    return NotificationItemModel(
      id: SafeJsonParser.toInt(json['id']),
      userId: SafeJsonParser.toInt(json['user_id']),
      category: cat,
      title: SafeJsonParser.toStringValue(json['title'], defaultValue: 'Thông báo izithrift'),
      body: SafeJsonParser.toStringValue(json['body'] ?? json['message']),
      targetType: SafeJsonParser.toNullableString(json['target_type']),
      targetId: SafeJsonParser.toNullableInt(json['target_id']),
      deepLinkRoute: SafeJsonParser.toNullableString(json['deep_link_route']),
      isRead: SafeJsonParser.toBool(json['is_read'], defaultValue: false),
      readAt: SafeJsonParser.toNullableDateTime(json['read_at']),
      createdAt: SafeJsonParser.toNullableDateTime(json['created_at']) ?? DateTime.now(),
    );
  }

  bool get isOrderType => category == 'ORDER';
  bool get isAuctionType => category == 'AUCTION';
  bool get isSystemType => category == 'SYSTEM';

  String get formattedTime {
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m ${createdAt.day}/${createdAt.month}';
  }

  NotificationItemModel copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationItemModel(
      id: id,
      userId: userId,
      category: category,
      title: title,
      body: body,
      targetType: targetType,
      targetId: targetId,
      deepLinkRoute: deepLinkRoute,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': category,
      'title': title,
      'body': body,
      'target_type': targetType,
      'target_id': targetId,
      'deep_link_route': deepLinkRoute,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
