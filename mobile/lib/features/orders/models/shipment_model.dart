import '../../../core/utils/safe_json_parser.dart';

/// Single milestone event along the order & shipment lifecycle (M-OR-05).
class ShipmentTimelineEventModel {
  final String title;
  final String description;
  final DateTime? timestamp;
  final bool isCompleted;

  const ShipmentTimelineEventModel({
    required this.title,
    required this.description,
    this.timestamp,
    this.isCompleted = false,
  });

  factory ShipmentTimelineEventModel.fromJson(Map<String, dynamic> json) {
    return ShipmentTimelineEventModel(
      title: SafeJsonParser.toStringValue(json['title']),
      description: SafeJsonParser.toStringValue(json['description']),
      timestamp: SafeJsonParser.toNullableDateTime(json['timestamp']),
      isCompleted: SafeJsonParser.toBool(json['is_completed'], defaultValue: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp?.toIso8601String(),
      'is_completed': isCompleted,
    };
  }
}

/// Represents shipment tracking details, carrier, and milestone progress (M-OR-05 / M-SL-07).
class ShipmentModel {
  final int id;
  final int orderId;
  final String carrierName;
  final String trackingCode;
  final String? shippingNote;
  final String status;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? estimatedDeliveryAt;
  final List<ShipmentTimelineEventModel> timelineEvents;

  const ShipmentModel({
    required this.id,
    required this.orderId,
    required this.carrierName,
    required this.trackingCode,
    this.shippingNote,
    this.status = 'PENDING',
    this.shippedAt,
    this.deliveredAt,
    this.estimatedDeliveryAt,
    this.timelineEvents = const [],
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['timeline_events'] ?? json['events'];
    final List<ShipmentTimelineEventModel> events = [];
    if (rawEvents is List) {
      for (final e in rawEvents) {
        if (e is Map<String, dynamic>) {
          events.add(ShipmentTimelineEventModel.fromJson(e));
        }
      }
    }

    return ShipmentModel(
      id: SafeJsonParser.toInt(json['id']),
      orderId: SafeJsonParser.toInt(json['order_id']),
      carrierName: SafeJsonParser.toStringValue(json['carrier_name'], defaultValue: 'Đang chuẩn bị vận chuyển'),
      trackingCode: SafeJsonParser.toStringValue(json['tracking_code'], defaultValue: 'CHƯA CẬP NHẬT'),
      shippingNote: SafeJsonParser.toNullableString(json['shipping_note']),
      status: SafeJsonParser.toStringValue(json['status'], defaultValue: 'PENDING').toUpperCase(),
      shippedAt: SafeJsonParser.toNullableDateTime(json['shipped_at']),
      deliveredAt: SafeJsonParser.toNullableDateTime(json['delivered_at']),
      estimatedDeliveryAt: SafeJsonParser.toNullableDateTime(json['estimated_delivery_at']),
      timelineEvents: events,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'carrier_name': carrierName,
      'tracking_code': trackingCode,
      'shipping_note': shippingNote,
      'status': status,
      'shipped_at': shippedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'estimated_delivery_at': estimatedDeliveryAt?.toIso8601String(),
      'timeline_events': timelineEvents.map((e) => e.toJson()).toList(),
    };
  }
}
