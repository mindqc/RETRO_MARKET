import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/base_view_model.dart';
import '../models/cart_item_model.dart';
import '../models/cart_model.dart';
import '../models/cart_seller_group_model.dart';
import '../repositories/cart_checkout_repository.dart';

/// ViewModel managing Grouped Shopping Cart state and selection logic (M-CR-01 / BR-OR-01 / Batch 2.1).
class CartViewModel extends BaseViewModel<CartModel> {
  final CartCheckoutRepository repository;

  CartViewModel({required this.repository});

  final Map<int, bool> _persistedSelection = {};
  final Map<int, bool> _desiredSelection = {};
  final Set<int> _inFlightItemIds = {};
  final Set<int> _pendingSyncItemIds = {};
  final Map<int, Future<void>> _activeSyncFutures = {};
  String? _selectionErrorMessage;

  bool get isSyncingSelection =>
      _inFlightItemIds.isNotEmpty || _pendingSyncItemIds.isNotEmpty;
  String? get selectionErrorMessage => _selectionErrorMessage;

  void clearSelectionError() {
    _selectionErrorMessage = null;
    notifyListeners();
  }

  bool get isAllSelected => state.data?.isAllSelected ?? false;
  int get selectedItemsCount => state.data?.computedSelectedCount ?? 0;
  double get selectedItemsSubtotal =>
      state.data?.computedSelectedSubtotal ?? 0.0;
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

  void _ensureInitialized(CartModel current) {
    for (final group in current.sellerGroups) {
      for (final item in group.items) {
        if (!_persistedSelection.containsKey(item.id)) {
          _persistedSelection[item.id] = item.isSelected;
        }
        if (!_desiredSelection.containsKey(item.id)) {
          _desiredSelection[item.id] = item.isSelected;
        }
      }
    }
  }

  /// Loads cart data from GET /api/v1/cart
  Future<void> loadCart({bool silent = false}) async {
    if (!silent) {
      setLoading();
    }
    await runCatching(
      () async {
        final cart = await repository.fetchCart();
        _persistedSelection.clear();
        _desiredSelection.clear();
        _inFlightItemIds.clear();
        _pendingSyncItemIds.clear();
        _activeSyncFutures.clear();
        _selectionErrorMessage = null;
        for (final group in cart.sellerGroups) {
          for (final item in group.items) {
            _persistedSelection[item.id] = item.isSelected;
            _desiredSelection[item.id] = item.isSelected;
          }
        }
        return cart;
      },
      isEmpty: (cart) => cart.isEmpty,
      emptyMessage: 'Giỏ hàng của bạn đang trống.',
    );
  }

  /// Toggles selection of a specific item in the cart and persists to backend
  void toggleItemSelection(int cartItemId) {
    final current = state.data;
    if (current == null) return;

    _ensureInitialized(current);

    bool? targetSelection;
    final updatedGroups = current.sellerGroups.map((group) {
      final updatedItems = group.items.map((item) {
        if (item.id == cartItemId) {
          if (!item.isAvailable) return item;
          targetSelection = !item.isSelected;
          return item.copyWith(isSelected: targetSelection!);
        }
        return item;
      }).toList();
      return group.copyWith(items: updatedItems);
    }).toList();

    if (targetSelection == null) return;

    final updatedCart = current.copyWith(sellerGroups: updatedGroups);
    setSuccess(updatedCart);

    _desiredSelection[cartItemId] = targetSelection!;
    _syncItem(cartItemId);
  }

  /// Toggles selection of all items within a specific seller group (BR-OR-01) and persists
  void toggleSellerGroupSelection(int sellerId) {
    final current = state.data;
    if (current == null) return;

    _ensureInitialized(current);

    final groupIndex = current.sellerGroups.indexWhere(
      (g) => g.sellerId == sellerId,
    );
    if (groupIndex == -1) return;

    final matchGroup = current.sellerGroups[groupIndex];
    final targetSelection = !matchGroup.isAllSelected;

    final updatedGroups = current.sellerGroups.map((group) {
      if (group.sellerId == sellerId) {
        final updatedItems = group.items.map((item) {
          if (!item.isAvailable) return item;
          return item.copyWith(isSelected: targetSelection);
        }).toList();
        return group.copyWith(items: updatedItems);
      }
      return group;
    }).toList();

    final updatedCart = current.copyWith(sellerGroups: updatedGroups);
    setSuccess(updatedCart);

    // Sync affected items whose selection actually changed
    for (final group in current.sellerGroups) {
      if (group.sellerId == sellerId) {
        for (final item in group.items) {
          if (item.isAvailable && item.isSelected != targetSelection) {
            _desiredSelection[item.id] = targetSelection;
            _syncItem(item.id);
          }
        }
      }
    }
  }

  /// Toggles selection across all seller groups in the cart and persists
  void toggleSelectAll() {
    final current = state.data;
    if (current == null) return;

    _ensureInitialized(current);

    final targetSelection = !current.isAllSelected;
    final updatedGroups = current.sellerGroups.map((group) {
      final updatedItems = group.items.map((item) {
        if (!item.isAvailable) return item;
        return item.copyWith(isSelected: targetSelection);
      }).toList();
      return group.copyWith(items: updatedItems);
    }).toList();

    final updatedCart = current.copyWith(sellerGroups: updatedGroups);
    setSuccess(updatedCart);

    // Sync affected items whose selection actually changed
    for (final group in current.sellerGroups) {
      for (final item in group.items) {
        if (item.isAvailable && item.isSelected != targetSelection) {
          _desiredSelection[item.id] = targetSelection;
          _syncItem(item.id);
        }
      }
    }
  }

  void _syncItem(int cartItemId) {
    if (_inFlightItemIds.contains(cartItemId)) {
      _pendingSyncItemIds.add(cartItemId);
      notifyListeners();
      return;
    }

    final fut = _runSyncLoop(cartItemId);
    _activeSyncFutures[cartItemId] = fut;
  }

  Future<void> _runSyncLoop(int cartItemId) async {
    _inFlightItemIds.add(cartItemId);
    _pendingSyncItemIds.add(cartItemId);
    _selectionErrorMessage = null;
    notifyListeners();

    try {
      while (true) {
        final desired = _desiredSelection[cartItemId];
        final persisted = _persistedSelection[cartItemId];

        if (desired == null || desired == persisted) {
          break;
        }

        final targetToSend = desired;
        try {
          await repository.updateCartItemSelection(
            cartItemId: cartItemId,
            isSelected: targetToSend,
          );
          _persistedSelection[cartItemId] = targetToSend;
          _selectionErrorMessage = null;
        } catch (e) {
          _selectionErrorMessage = 'Không thể đồng bộ trạng thái sản phẩm trong giỏ hàng. Vui lòng thử lại.';
          final rollbackValue =
              _persistedSelection[cartItemId] ?? !targetToSend;
          _desiredSelection[cartItemId] = rollbackValue;
          _rollbackItemState(cartItemId, rollbackValue);
          break;
        }
      }
    } finally {
      _inFlightItemIds.remove(cartItemId);
      if (_desiredSelection[cartItemId] == _persistedSelection[cartItemId]) {
        _pendingSyncItemIds.remove(cartItemId);
      }
      _activeSyncFutures.remove(cartItemId);
      notifyListeners();
    }
  }

  void _rollbackItemState(int cartItemId, bool value) {
    final current = state.data;
    if (current == null) return;

    final updatedGroups = current.sellerGroups.map((group) {
      final updatedItems = group.items.map((item) {
        if (item.id == cartItemId) {
          return item.copyWith(isSelected: value);
        }
        return item;
      }).toList();
      return group.copyWith(items: updatedItems);
    }).toList();

    setSuccess(current.copyWith(sellerGroups: updatedGroups));
  }

  /// Ensures that all pending selection updates have finished and backend matches frontend.
  /// Returns true if fully synchronized, false if any sync failed or timed out.
  Future<bool> ensureSelectionSynchronized({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_activeSyncFutures.isNotEmpty) {
      try {
        await Future.wait(List.from(_activeSyncFutures.values))
            .timeout(timeout);
      } catch (_) {
        // Errors captured in _selectionErrorMessage
      }
    }

    if (isSyncingSelection) {
      _selectionErrorMessage =
          'Đang đồng bộ trạng thái giỏ hàng, vui lòng thử lại sau.';
      notifyListeners();
      return false;
    }

    if (_selectionErrorMessage != null) {
      return false;
    }

    final current = state.data;
    if (current != null) {
      for (final group in current.sellerGroups) {
        for (final item in group.items) {
          if (item.isAvailable) {
            final persisted = _persistedSelection[item.id];
            if (persisted == null || persisted != item.isSelected) {
              _selectionErrorMessage =
                  'Trạng thái giỏ hàng chưa đồng bộ hoàn toàn với máy chủ.';
              notifyListeners();
              return false;
            }
          }
        }
      }
    }

    return true;
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
      await repository.updateCartItemQuantity(
        cartItemId: cartItemId,
        quantity: newQty,
      );
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
      final updatedItems = group.items
          .where((i) => i.id != cartItemId)
          .toList();
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

    _persistedSelection.remove(cartItemId);
    _desiredSelection.remove(cartItemId);
    _inFlightItemIds.remove(cartItemId);
    _pendingSyncItemIds.remove(cartItemId);
    _activeSyncFutures.remove(cartItemId);

    try {
      await repository.removeCartItem(cartItemId);
    } catch (e) {
      setSuccess(current);
    }
  }
}

/// Riverpod provider for CartViewModel
final cartViewModelProvider = ChangeNotifierProvider.autoDispose<CartViewModel>(
  (ref) {
    final repo = ref.watch(cartCheckoutRepositoryProvider);
    return CartViewModel(repository: repo);
  },
);
