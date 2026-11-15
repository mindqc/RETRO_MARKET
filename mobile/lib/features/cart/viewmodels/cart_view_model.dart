import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/base_view_model.dart';
import '../models/cart_item_model.dart';
import '../models/cart_model.dart';
import '../models/cart_seller_group_model.dart';
import '../repositories/cart_checkout_repository.dart';

/// ViewModel managing Grouped Shopping Cart state and selection logic (M-CR-01 / BR-OR-01).
class CartViewModel extends BaseViewModel<CartModel> {
  final CartCheckoutRepository repository;

  CartViewModel({required this.repository});

  bool get isAllSelected => state.data?.isAllSelected ?? false;
  int get selectedItemsCount => state.data?.computedSelectedCount ?? 0;
  double get selectedItemsSubtotal => state.data?.computedSelectedSubtotal ?? 0.0;
  List<int> get selectedItemIds => state.data?.selectedCartItemIds ?? [];

  bool isSellerGroupFullySelected(CartSellerGroupModel group) {
    final cur = state.data;
    if (cur == null) return false;
    final match = cur.sellerGroups.firstWhere(
      (g) => g.sellerId == group.sellerId,
      orElse: () => group,
    );
    return match.isAllSelected;
  }

  /// Loads cart data from GET /api/v1/cart
  Future<void> loadCart({bool silent = false}) async {
    if (!silent) {
      setLoading();
    }
    await runCatching(
      () => repository.fetchCart(),
      isEmpty: (cart) => cart.isEmpty,
      emptyMessage: 'Giỏ hàng của bạn đang trống.',
    );
  }

  /// Toggles selection of a specific item in the cart
  void toggleItemSelection(int cartItemId) {
    final current = state.data;
    if (current == null) return;

    final updatedGroups = current.sellerGroups.map((group) {
      final updatedItems = group.items.map((item) {
        if (item.id == cartItemId) {
          return item.copyWith(isSelected: !item.isSelected);
        }
        return item;
      }).toList();
      return group.copyWith(items: updatedItems);
    }).toList();

    final updatedCart = current.copyWith(sellerGroups: updatedGroups);
    setSuccess(updatedCart);
  }

  /// Toggles selection of all items within a specific seller group (BR-OR-01)
  void toggleSellerGroupSelection(int sellerId) {
    final current = state.data;
    if (current == null) return;

    final updatedGroups = current.sellerGroups.map((group) {
      if (group.sellerId == sellerId) {
        final targetSelection = !group.isAllSelected;
        final updatedItems = group.items.map((item) {
          return item.copyWith(isSelected: targetSelection);
        }).toList();
        return group.copyWith(items: updatedItems);
      }
      return group;
    }).toList();

    final updatedCart = current.copyWith(sellerGroups: updatedGroups);
    setSuccess(updatedCart);
  }

  /// Toggles selection across all seller groups in the cart
  void toggleSelectAll() {
    final current = state.data;
    if (current == null) return;

    final targetSelection = !current.isAllSelected;
    final updatedGroups = current.sellerGroups.map((group) {
      final updatedItems = group.items.map((item) {
        return item.copyWith(isSelected: targetSelection);
      }).toList();
      return group.copyWith(items: updatedItems);
    }).toList();

    final updatedCart = current.copyWith(sellerGroups: updatedGroups);
    setSuccess(updatedCart);
  }

  /// Updates quantity of an item, respecting available quantity limits
  Future<void> updateQuantity(int cartItemId, int newQty) async {
    final current = state.data;
    if (current == null) return;

    // Find the item
    CartItemModel? targetItem;
    for (final group in current.sellerGroups) {
      for (final item in group.items) {
        if (item.id == cartItemId) {
          targetItem = item;
          break;
        }
      }
      if (targetItem != null) break;
    }

    if (targetItem == null) return;

    // If decreasing to 0 or less, remove item
    if (newQty <= 0) {
      await removeItem(cartItemId);
      return;
    }

    // Do not exceed available quantity
    if (newQty > targetItem.availableQuantity) {
      return;
    }

    // Optimistic UI update
    final updatedGroups = current.sellerGroups.map((group) {
      final updatedItems = group.items.map((item) {
        if (item.id == cartItemId) {
          return item.copyWith(quantity: newQty);
        }
        return item;
      }).toList();
      return group.copyWith(items: updatedItems);
    }).toList();

    setSuccess(current.copyWith(sellerGroups: updatedGroups));

    try {
      await repository.updateCartItemQuantity(cartItemId: cartItemId, quantity: newQty);
    } catch (e) {
      // Revert if API fails
      setSuccess(current);
    }
  }

  /// Removes an item from the cart
  Future<void> removeItem(int cartItemId) async {
    final current = state.data;
    if (current == null) return;

    // Optimistic UI update
    final updatedGroups = <CartSellerGroupModel>[];
    for (final group in current.sellerGroups) {
      final updatedItems = group.items.where((i) => i.id != cartItemId).toList();
      if (updatedItems.isNotEmpty) {
        updatedGroups.add(group.copyWith(items: updatedItems));
      }
    }

    final updatedCart = current.copyWith(sellerGroups: updatedGroups);
    if (updatedCart.isEmpty) {
      setEmpty('Giỏ hàng của bạn đang trống.');
    } else {
      setSuccess(updatedCart);
    }

    try {
      await repository.removeCartItem(cartItemId);
    } catch (e) {
      setSuccess(current);
    }
  }
}

/// Riverpod provider for CartViewModel
final cartViewModelProvider = ChangeNotifierProvider.autoDispose<CartViewModel>((ref) {
  final repo = ref.watch(cartCheckoutRepositoryProvider);
  return CartViewModel(repository: repo);
});
