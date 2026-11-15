import '../../../core/utils/safe_json_parser.dart';
import 'cart_item_model.dart';

/// Represents a distinct Seller Group in the shopping cart (BR-OR-01 / M-CR-01).
class CartSellerGroupModel {
  final int sellerId;
  final String shopName;
  final String? shopSlug;
  final String? avatarUrl;
  final double trustScore;
  final List<CartItemModel> items;
  final double sellerSubtotal;

  const CartSellerGroupModel({
    required this.sellerId,
    required this.shopName,
    this.shopSlug,
    this.avatarUrl,
    this.trustScore = 100.0,
    required this.items,
    this.sellerSubtotal = 0.0,
  });

  bool get isAllSelected => items.isNotEmpty && items.every((i) => i.isSelected);

  double get selectedGroupSubtotal => items
      .where((i) => i.isSelected && i.isAvailable)
      .fold(0.0, (sum, i) => sum + i.itemSubtotal);

  int get selectedGroupCount => items
      .where((i) => i.isSelected && i.isAvailable)
      .fold(0, (sum, i) => sum + i.quantity);

  factory CartSellerGroupModel.fromJson(Map<String, dynamic> json) {
    int sId = 0;
    String name = 'Tiệm Đồ Si';
    String? slug;
    String? avatar;
    double trust = 100.0;

    if (json['seller'] is Map<String, dynamic>) {
      final s = json['seller'] as Map<String, dynamic>;
      sId = SafeJsonParser.toInt(s['id'] ?? s['seller_id']);
      name = SafeJsonParser.toStringValue(
        s['display_name'] ?? s['shop_name'] ?? s['name'],
        defaultValue: 'Tiệm Đồ Si',
      );
      slug = SafeJsonParser.toNullableString(s['shop_slug']);
      avatar = SafeJsonParser.toNullableString(s['avatar_url']);
      trust = SafeJsonParser.toDouble(s['trust_score'], defaultValue: 100.0);
    } else {
      sId = SafeJsonParser.toInt(json['seller_id']);
      name = SafeJsonParser.toStringValue(json['shop_name'], defaultValue: 'Tiệm Đồ Si');
      slug = SafeJsonParser.toNullableString(json['shop_slug']);
    }

    final rawItems = json['items'];
    final List<CartItemModel> parsedItems = [];
    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map<String, dynamic>) {
          parsedItems.add(CartItemModel.fromJson(it));
        }
      }
    }

    return CartSellerGroupModel(
      sellerId: sId,
      shopName: name,
      shopSlug: slug,
      avatarUrl: avatar,
      trustScore: trust,
      items: parsedItems,
      sellerSubtotal: SafeJsonParser.toDouble(json['seller_subtotal']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seller': {
        'id': sellerId,
        'display_name': shopName,
        'shop_slug': shopSlug,
        'avatar_url': avatarUrl,
        'trust_score': trustScore,
      },
      'items': items.map((i) => i.toJson()).toList(),
      'seller_subtotal': sellerSubtotal,
    };
  }

  CartSellerGroupModel copyWith({
    int? sellerId,
    String? shopName,
    String? shopSlug,
    String? avatarUrl,
    double? trustScore,
    List<CartItemModel>? items,
    double? sellerSubtotal,
  }) {
    return CartSellerGroupModel(
      sellerId: sellerId ?? this.sellerId,
      shopName: shopName ?? this.shopName,
      shopSlug: shopSlug ?? this.shopSlug,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      trustScore: trustScore ?? this.trustScore,
      items: items ?? this.items,
      sellerSubtotal: sellerSubtotal ?? this.sellerSubtotal,
    );
  }
}
