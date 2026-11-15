import '../../../core/utils/safe_json_parser.dart';

/// Represents a single item inside the grouped shopping cart (M-CR-01).
class CartItemModel {
  final int id;
  final int productId;
  final String productCode;
  final String title;
  final String? slug;
  final String? primaryImageUrl;
  final String condition;
  final double unitPrice;
  final int quantity;
  final int availableQuantity;
  final double itemSubtotal;
  final bool isAvailable;
  final bool isSelected;

  const CartItemModel({
    required this.id,
    required this.productId,
    required this.productCode,
    required this.title,
    this.slug,
    this.primaryImageUrl,
    required this.condition,
    required this.unitPrice,
    this.quantity = 1,
    this.availableQuantity = 1,
    required this.itemSubtotal,
    this.isAvailable = true,
    this.isSelected = true,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final double price = SafeJsonParser.toDouble(
      json['price'] ?? json['unit_price'],
    );
    final int qty = SafeJsonParser.toInt(json['quantity'], defaultValue: 1);
    final double subtotal = SafeJsonParser.toDouble(
      json['line_total'] ?? json['item_subtotal'],
      defaultValue: price * qty,
    );

    return CartItemModel(
      id: SafeJsonParser.toInt(json['id'] ?? json['cart_item_id']),
      productId: SafeJsonParser.toInt(json['product_id']),
      productCode: SafeJsonParser.toStringValue(json['product_code'], defaultValue: 'PRD-ITEM'),
      title: SafeJsonParser.toStringValue(json['title'], defaultValue: 'Sản phẩm vintage'),
      slug: SafeJsonParser.toNullableString(json['slug']),
      primaryImageUrl: SafeJsonParser.toNullableString(json['primary_image_url'] ?? json['image_url']),
      condition: SafeJsonParser.toStringValue(json['condition'], defaultValue: 'GOOD'),
      unitPrice: price,
      quantity: qty,
      availableQuantity: SafeJsonParser.toInt(json['available_quantity'], defaultValue: 1),
      itemSubtotal: subtotal,
      isAvailable: SafeJsonParser.toBool(json['is_available'], defaultValue: true),
      isSelected: SafeJsonParser.toBool(json['is_selected'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_code': productCode,
      'title': title,
      'slug': slug,
      'primary_image_url': primaryImageUrl,
      'condition': condition,
      'unit_price': unitPrice,
      'quantity': quantity,
      'available_quantity': availableQuantity,
      'item_subtotal': itemSubtotal,
      'is_available': isAvailable,
      'is_selected': isSelected,
    };
  }

  CartItemModel copyWith({
    int? id,
    int? productId,
    String? productCode,
    String? title,
    String? slug,
    String? primaryImageUrl,
    String? condition,
    double? unitPrice,
    int? quantity,
    int? availableQuantity,
    double? itemSubtotal,
    bool? isAvailable,
    bool? isSelected,
  }) {
    final newPrice = unitPrice ?? this.unitPrice;
    final newQty = quantity ?? this.quantity;
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productCode: productCode ?? this.productCode,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      condition: condition ?? this.condition,
      unitPrice: newPrice,
      quantity: newQty,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      itemSubtotal: itemSubtotal ?? (newPrice * newQty),
      isAvailable: isAvailable ?? this.isAvailable,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
