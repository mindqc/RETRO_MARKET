import '../../../core/utils/safe_json_parser.dart';
import 'cart_seller_group_model.dart';

/// Full shopping cart model containing grouped stores and summary metrics (M-CR-01).
class CartModel {
  final int cartId;
  final List<CartSellerGroupModel> sellerGroups;
  final int totalItemsCount;
  final int selectedItemsCount;
  final double selectedSubtotal;

  const CartModel({
    required this.cartId,
    required this.sellerGroups,
    this.totalItemsCount = 0,
    this.selectedItemsCount = 0,
    this.selectedSubtotal = 0.0,
  });

  bool get isEmpty => sellerGroups.isEmpty || sellerGroups.every((g) => g.items.isEmpty);

  bool get isAllSelected =>
      sellerGroups.isNotEmpty &&
      sellerGroups.every((g) => g.isAllSelected);

  double get computedSelectedSubtotal =>
      sellerGroups.fold(0.0, (sum, g) => sum + g.selectedGroupSubtotal);

  int get computedSelectedCount =>
      sellerGroups.fold(0, (sum, g) => sum + g.selectedGroupCount);

  List<int> get selectedCartItemIds => sellerGroups
      .expand((g) => g.items)
      .where((i) => i.isSelected && i.isAvailable)
      .map((i) => i.id)
      .toList();

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['seller_groups'];
    final List<CartSellerGroupModel> groups = [];
    if (rawGroups is List) {
      for (final g in rawGroups) {
        if (g is Map<String, dynamic>) {
          groups.add(CartSellerGroupModel.fromJson(g));
        }
      }
    }

    final int totalCount = SafeJsonParser.toInt(json['total_items_count']);
    final int selectedCount = SafeJsonParser.toInt(json['selected_items_count']);
    final double selectedSub = SafeJsonParser.toDouble(json['selected_subtotal']);

    return CartModel(
      cartId: SafeJsonParser.toInt(json['cart_id'] ?? json['id']),
      sellerGroups: groups,
      totalItemsCount: totalCount,
      selectedItemsCount: selectedCount,
      selectedSubtotal: selectedSub,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cart_id': cartId,
      'total_items_count': totalItemsCount,
      'selected_items_count': selectedItemsCount,
      'selected_subtotal': selectedSubtotal,
      'seller_groups': sellerGroups.map((g) => g.toJson()).toList(),
    };
  }

  CartModel copyWith({
    int? cartId,
    List<CartSellerGroupModel>? sellerGroups,
    int? totalItemsCount,
    int? selectedItemsCount,
    double? selectedSubtotal,
  }) {
    return CartModel(
      cartId: cartId ?? this.cartId,
      sellerGroups: sellerGroups ?? this.sellerGroups,
      totalItemsCount: totalItemsCount ?? this.totalItemsCount,
      selectedItemsCount: selectedItemsCount ?? this.selectedItemsCount,
      selectedSubtotal: selectedSubtotal ?? this.selectedSubtotal,
    );
  }
}
