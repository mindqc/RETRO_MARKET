import '../../../core/utils/safe_json_parser.dart';

/// Pinned context card at the top of a 1-on-1 chat room (Product or Order)
class ChatContextCardModel {
  final String contextType; // 'PRODUCT' or 'ORDER'
  final int referenceId;
  final String? referenceCode;
  final String title;
  final String? thumbnailUrl;
  final double priceOrTotal;
  final String? status;

  const ChatContextCardModel({
    required this.contextType,
    required this.referenceId,
    this.referenceCode,
    required this.title,
    this.thumbnailUrl,
    required this.priceOrTotal,
    this.status,
  });

  int get id => referenceId;
  double get price => priceOrTotal;
  double get totalAmount => priceOrTotal;
  String get orderCode => referenceCode ?? referenceId.toString();
  String get orderStatus => status ?? '';

  factory ChatContextCardModel.fromProductJson(Map<String, dynamic> json) {
    return ChatContextCardModel(
      contextType: 'PRODUCT',
      referenceId: SafeJsonParser.toInt(json['id']),
      title: SafeJsonParser.toStringValue(json['title'], defaultValue: 'Sản phẩm vintage'),
      thumbnailUrl: SafeJsonParser.toNullableString(json['primary_image_url'] ?? json['image_url']),
      priceOrTotal: SafeJsonParser.toDouble(json['price'], defaultValue: 0.0),
      status: SafeJsonParser.toNullableString(json['status']),
    );
  }

  factory ChatContextCardModel.fromOrderJson(Map<String, dynamic> json) {
    return ChatContextCardModel(
      contextType: 'ORDER',
      referenceId: SafeJsonParser.toInt(json['id']),
      referenceCode: SafeJsonParser.toNullableString(json['order_code']),
      title: 'Đơn hàng #${SafeJsonParser.toStringValue(json['order_code'], defaultValue: json['id'].toString())}',
      priceOrTotal: SafeJsonParser.toDouble(json['total_amount'], defaultValue: 0.0),
      status: SafeJsonParser.toNullableString(json['order_status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'context_type': contextType,
      'reference_id': referenceId,
      'reference_code': referenceCode,
      'title': title,
      'thumbnail_url': thumbnailUrl,
      'price_or_total': priceOrTotal,
      'status': status,
    };
  }
}
