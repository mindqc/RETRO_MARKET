import '../../../core/utils/safe_json_parser.dart';

/// Immutable snapshot of an order item at checkout time (Order Snapshot Pattern).
class OrderItemSnapshotModel {
  final int id;
  final int productId;
  final String productCode;
  final String productTitle;
  final String? primaryImageUrl;
  final String condition;
  final String? defectInfo;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  const OrderItemSnapshotModel({
    required this.id,
    required this.productId,
    required this.productCode,
    required this.productTitle,
    this.primaryImageUrl,
    required this.condition,
    this.defectInfo,
    required this.unitPrice,
    this.quantity = 1,
    required this.subtotal,
  });

  factory OrderItemSnapshotModel.fromJson(Map<String, dynamic> json) {
    final double price = SafeJsonParser.toDouble(
      json['unit_price'] ?? json['unit_price_snapshot'] ?? json['price'],
    );
    final int qty = SafeJsonParser.toInt(json['quantity'], defaultValue: 1);
    final double lineTotal = SafeJsonParser.toDouble(
      json['line_total'] ?? json['subtotal'] ?? json['item_subtotal'],
      defaultValue: price * qty,
    );

    return OrderItemSnapshotModel(
      id: SafeJsonParser.toInt(json['id']),
      productId: SafeJsonParser.toInt(json['product_id']),
      productCode: SafeJsonParser.toStringValue(
        json['product_code_snapshot'] ?? json['product_code'],
        defaultValue: 'PRD-SN',
      ),
      productTitle: SafeJsonParser.toStringValue(
        json['product_title_snapshot'] ?? json['product_title'] ?? json['title'],
        defaultValue: 'Sản phẩm vintage',
      ),
      primaryImageUrl: SafeJsonParser.toNullableString(
        json['primary_image_snapshot'] ?? json['primary_image_url'] ?? json['image_url'],
      ),
      condition: SafeJsonParser.toStringValue(
        json['condition_snapshot'] ?? json['condition'],
        defaultValue: 'GOOD',
      ),
      defectInfo: SafeJsonParser.toNullableString(
        json['defect_info_snapshot'] ?? json['defect_info'],
      ),
      unitPrice: price,
      quantity: qty,
      subtotal: lineTotal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_code': productCode,
      'product_title': productTitle,
      'primary_image_url': primaryImageUrl,
      'condition': condition,
      'defect_info': defectInfo,
      'unit_price': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}
