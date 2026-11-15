import '../../../core/utils/safe_json_parser.dart';
import '../../profile/models/user_address_model.dart';
import 'cart_item_model.dart';

/// Previews order financial breakdown separated per seller group (DEC-04 / M-OR-01).
class CheckoutOrderGroupPreviewModel {
  final int sellerId;
  final String shopName;
  final String? shopSlug;
  final String? avatarUrl;
  final double trustScore;
  final List<CartItemModel> items;
  final double itemSubtotal;
  final double shippingFee;
  final double protectionFeeRate;
  final double protectionFixedFee;
  final double buyerProtectionFee;
  final double totalAmount;
  final double sellerNetAmount;

  const CheckoutOrderGroupPreviewModel({
    required this.sellerId,
    required this.shopName,
    this.shopSlug,
    this.avatarUrl,
    this.trustScore = 100.0,
    required this.items,
    required this.itemSubtotal,
    this.shippingFee = 0.0,
    this.protectionFeeRate = 0.06,
    this.protectionFixedFee = 7000.0,
    required this.buyerProtectionFee,
    required this.totalAmount,
    required this.sellerNetAmount,
  });

  factory CheckoutOrderGroupPreviewModel.fromJson(Map<String, dynamic> json) {
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

    final sub = SafeJsonParser.toDouble(json['item_subtotal']);
    final rate = SafeJsonParser.toDouble(json['protection_fee_rate'], defaultValue: 0.06);
    final fixedFee = SafeJsonParser.toDouble(json['protection_fixed_fee'], defaultValue: 7000.0);
    final fee = SafeJsonParser.toDouble(
      json['buyer_protection_fee'],
      defaultValue: (sub * rate + fixedFee).roundToDouble(),
    );
    final ship = SafeJsonParser.toDouble(json['shipping_fee']);
    final total = SafeJsonParser.toDouble(json['total_amount'], defaultValue: sub + ship + fee);
    final net = SafeJsonParser.toDouble(json['seller_net_amount'], defaultValue: sub);

    return CheckoutOrderGroupPreviewModel(
      sellerId: sId,
      shopName: name,
      shopSlug: slug,
      avatarUrl: avatar,
      trustScore: trust,
      items: parsedItems,
      itemSubtotal: sub,
      shippingFee: ship,
      protectionFeeRate: rate,
      protectionFixedFee: fixedFee,
      buyerProtectionFee: fee,
      totalAmount: total,
      sellerNetAmount: net,
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
      'item_subtotal': itemSubtotal,
      'shipping_fee': shippingFee,
      'protection_fee_rate': protectionFeeRate,
      'protection_fixed_fee': protectionFixedFee,
      'buyer_protection_fee': buyerProtectionFee,
      'total_amount': totalAmount,
      'seller_net_amount': sellerNetAmount,
    };
  }
}

/// Grand preview model for order checkout confirmation (DEC-04 / M-OR-01).
class CheckoutPreviewModel {
  final String source; // 'CART' or 'BUY_NOW'
  final UserAddressModel? shippingAddress;
  final List<CheckoutOrderGroupPreviewModel> orderGroups;
  final int sellersCount;
  final int itemsCount;
  final double totalItemSubtotal;
  final double totalShippingFee;
  final double totalBuyerProtectionFee;
  final double grandTotalAmount;

  const CheckoutPreviewModel({
    required this.source,
    this.shippingAddress,
    required this.orderGroups,
    this.sellersCount = 1,
    this.itemsCount = 1,
    required this.totalItemSubtotal,
    this.totalShippingFee = 0.0,
    required this.totalBuyerProtectionFee,
    required this.grandTotalAmount,
  });

  factory CheckoutPreviewModel.fromJson(Map<String, dynamic> json) {
    UserAddressModel? addr;
    if (json['shipping_address'] is Map<String, dynamic>) {
      addr = UserAddressModel.fromJson(json['shipping_address'] as Map<String, dynamic>);
    }

    final rawGroups = json['seller_groups'];
    final List<CheckoutOrderGroupPreviewModel> groups = [];
    if (rawGroups is List) {
      for (final g in rawGroups) {
        if (g is Map<String, dynamic>) {
          groups.add(CheckoutOrderGroupPreviewModel.fromJson(g));
        }
      }
    }

    final summary = json['summary'] is Map<String, dynamic>
        ? json['summary'] as Map<String, dynamic>
        : <String, dynamic>{};

    final double subtotal = SafeJsonParser.toDouble(
      summary['item_subtotal'] ?? json['total_item_subtotal'],
      defaultValue: groups.fold(0.0, (sum, g) => sum + g.itemSubtotal),
    );
    final double ship = SafeJsonParser.toDouble(
      summary['shipping_fee'] ?? json['total_shipping_fee'],
      defaultValue: 0.0,
    );
    final double protectionFee = SafeJsonParser.toDouble(
      summary['buyer_protection_fee'] ?? json['total_buyer_protection_fee'],
      defaultValue: groups.fold(0.0, (sum, g) => sum + g.buyerProtectionFee),
    );
    final double grandTotal = SafeJsonParser.toDouble(
      summary['grand_total'] ?? json['grand_total_amount'],
      defaultValue: subtotal + ship + protectionFee,
    );

    return CheckoutPreviewModel(
      source: SafeJsonParser.toStringValue(json['source'], defaultValue: 'CART').toUpperCase(),
      shippingAddress: addr,
      orderGroups: groups,
      sellersCount: SafeJsonParser.toInt(summary['sellers_count'], defaultValue: groups.length),
      itemsCount: SafeJsonParser.toInt(summary['items_count'], defaultValue: groups.fold(0, (sum, g) => sum + g.items.length)),
      totalItemSubtotal: subtotal,
      totalShippingFee: ship,
      totalBuyerProtectionFee: protectionFee,
      grandTotalAmount: grandTotal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'shipping_address': shippingAddress?.toJson(),
      'seller_groups': orderGroups.map((g) => g.toJson()).toList(),
      'summary': {
        'sellers_count': sellersCount,
        'items_count': itemsCount,
        'item_subtotal': totalItemSubtotal,
        'shipping_fee': totalShippingFee,
        'buyer_protection_fee': totalBuyerProtectionFee,
        'grand_total': grandTotalAmount,
      },
    };
  }

  CheckoutPreviewModel copyWith({
    String? source,
    UserAddressModel? shippingAddress,
    List<CheckoutOrderGroupPreviewModel>? orderGroups,
    int? sellersCount,
    int? itemsCount,
    double? totalItemSubtotal,
    double? totalShippingFee,
    double? totalBuyerProtectionFee,
    double? grandTotalAmount,
  }) {
    return CheckoutPreviewModel(
      source: source ?? this.source,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      orderGroups: orderGroups ?? this.orderGroups,
      sellersCount: sellersCount ?? this.sellersCount,
      itemsCount: itemsCount ?? this.itemsCount,
      totalItemSubtotal: totalItemSubtotal ?? this.totalItemSubtotal,
      totalShippingFee: totalShippingFee ?? this.totalShippingFee,
      totalBuyerProtectionFee: totalBuyerProtectionFee ?? this.totalBuyerProtectionFee,
      grandTotalAmount: grandTotalAmount ?? this.grandTotalAmount,
    );
  }
}
