import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:izithrift/features/cart/models/cart_item_model.dart';
import 'package:izithrift/features/cart/models/cart_model.dart';
import 'package:izithrift/features/cart/models/cart_seller_group_model.dart';
import 'package:izithrift/features/cart/repositories/cart_checkout_repository.dart';
import 'package:izithrift/features/cart/screens/shopping_cart_screen.dart';
import 'package:izithrift/features/cart/viewmodels/cart_view_model.dart';

class _TrackingSyncRepo implements CartCheckoutRepository {
  CartModel cartData;
  final Map<int, bool> backendState = {};
  final List<Map<String, dynamic>> syncCallHistory = [];
  final Set<int> failItemIds = {};
  Duration? delayDuration;

  _TrackingSyncRepo({required this.cartData, this.delayDuration}) {
    for (final group in cartData.sellerGroups) {
      for (final item in group.items) {
        backendState[item.id] = item.isSelected;
      }
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<CartModel> fetchCart() async => cartData;

  @override
  Future<CartItemModel> updateCartItemSelection({
    required int cartItemId,
    required bool isSelected,
  }) async {
    if (delayDuration != null) {
      await Future.delayed(delayDuration!);
    }
    syncCallHistory.add({'cartItemId': cartItemId, 'isSelected': isSelected});

    if (failItemIds.contains(cartItemId)) {
      throw Exception('Network error for item $cartItemId');
    }

    backendState[cartItemId] = isSelected;

    return CartItemModel(
      id: cartItemId,
      productId: 1,
      productCode: 'PRD-$cartItemId',
      title: 'Item $cartItemId',
      condition: 'GOOD',
      unitPrice: 100000,
      itemSubtotal: 100000,
      isSelected: isSelected,
    );
  }

  @override
  Future<CartItemModel> updateCartItemQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    return CartItemModel(
      id: cartItemId,
      productId: 1,
      productCode: 'PRD-$cartItemId',
      title: 'Item $cartItemId',
      condition: 'GOOD',
      unitPrice: 100000,
      itemSubtotal: 100000,
      quantity: quantity,
    );
  }

  @override
  Future<bool> removeCartItem(int cartItemId) async => true;
}

CartModel _buildSampleCart({
  bool item101Selected = true,
  bool item102Selected = true,
  bool item201Selected = false,
}) {
  return CartModel(
    cartId: 1,
    totalItemsCount: 3,
    selectedItemsCount: 2,
    selectedSubtotal: 350000,
    sellerGroups: [
      CartSellerGroupModel(
        sellerId: 10,
        shopName: 'Tiệm Vintage Sài Gòn',
        items: [
          CartItemModel(
            id: 101,
            productId: 1,
            productCode: 'PRD-101',
            title: 'Áo Khoác Denim',
            condition: 'EXCELLENT',
            unitPrice: 200000,
            quantity: 1,
            availableQuantity: 3,
            itemSubtotal: 200000,
            isAvailable: true,
            isSelected: item101Selected,
          ),
          CartItemModel(
            id: 102,
            productId: 2,
            productCode: 'PRD-102',
            title: 'Quần Corduroy',
            condition: 'GOOD',
            unitPrice: 150000,
            quantity: 1,
            availableQuantity: 2,
            itemSubtotal: 150000,
            isAvailable: true,
            isSelected: item102Selected,
          ),
        ],
      ),
      CartSellerGroupModel(
        sellerId: 20,
        shopName: 'Tiệm Đồ Cũ Hà Nội',
        items: [
          CartItemModel(
            id: 201,
            productId: 3,
            productCode: 'PRD-201',
            title: 'Túi Da Vintage',
            condition: 'GOOD',
            unitPrice: 300000,
            quantity: 1,
            availableQuantity: 1,
            itemSubtotal: 300000,
            isAvailable: true,
            isSelected: item201Selected,
          ),
        ],
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch 2.1 — Cart Selection Synchronization Tests (1 - 10)', () {
    test(
      '1. Individual select persists is_selected = true to backend',
      () async {
        final sample = _buildSampleCart(item101Selected: false);
        final repo = _TrackingSyncRepo(cartData: sample);
        final vm = CartViewModel(repository: repo);
        await vm.loadCart();

        expect(repo.backendState[101], false);

        vm.toggleItemSelection(101);

        // Optimistic state
        expect(vm.selectedItemIds.contains(101), true);

        // Await sync
        final ok = await vm.ensureSelectionSynchronized();
        expect(ok, true);
        expect(repo.backendState[101], true);
        expect(
          repo.syncCallHistory.any(
            (c) => c['cartItemId'] == 101 && c['isSelected'] == true,
          ),
          true,
        );
      },
    );

    test(
      '2. Individual deselect persists is_selected = false to backend',
      () async {
        final sample = _buildSampleCart(item101Selected: true);
        final repo = _TrackingSyncRepo(cartData: sample);
        final vm = CartViewModel(repository: repo);
        await vm.loadCart();

        expect(repo.backendState[101], true);

        vm.toggleItemSelection(101);

        // Optimistic state
        expect(vm.selectedItemIds.contains(101), false);

        // Await sync
        final ok = await vm.ensureSelectionSynchronized();
        expect(ok, true);
        expect(repo.backendState[101], false);
        expect(
          repo.syncCallHistory.any(
            (c) => c['cartItemId'] == 101 && c['isSelected'] == false,
          ),
          true,
        );
      },
    );

    test('3. Seller group selection synchronizes all affected items and skips unchanged items', () async {
      // Seller 10 has item 101 (false) and item 102 (true).
      // Toggling group 10 will target isAllSelected = true -> item 101 becomes true.
      final sample = _buildSampleCart(
        item101Selected: false,
        item102Selected: true,
      );
      final repo = _TrackingSyncRepo(cartData: sample);
      final vm = CartViewModel(repository: repo);
      await vm.loadCart();

      repo.syncCallHistory.clear();
      vm.toggleSellerGroupSelection(10);

      final ok = await vm.ensureSelectionSynchronized();
      expect(ok, true);
      expect(repo.backendState[101], true);
      expect(repo.backendState[102], true);

      // Only item 101 was sent because 102 was already true
      expect(repo.syncCallHistory.length, 1);
      expect(repo.syncCallHistory.first['cartItemId'], 101);
      expect(repo.syncCallHistory.first['isSelected'], true);
    });

    test('4. Select All synchronizes all unselected items', () async {
      final sample = _buildSampleCart(
        item101Selected: false,
        item102Selected: false,
        item201Selected: false,
      );
      final repo = _TrackingSyncRepo(cartData: sample);
      final vm = CartViewModel(repository: repo);
      await vm.loadCart();

      repo.syncCallHistory.clear();
      vm.toggleSelectAll();

      final ok = await vm.ensureSelectionSynchronized();
      expect(ok, true);
      expect(repo.backendState[101], true);
      expect(repo.backendState[102], true);
      expect(repo.backendState[201], true);
      expect(repo.syncCallHistory.length, 3);
    });

    test('5. Deselect All synchronizes all selected items', () async {
      final sample = _buildSampleCart(
        item101Selected: true,
        item102Selected: true,
        item201Selected: true,
      );
      final repo = _TrackingSyncRepo(cartData: sample);
      final vm = CartViewModel(repository: repo);
      await vm.loadCart();

      repo.syncCallHistory.clear();
      vm.toggleSelectAll();

      final ok = await vm.ensureSelectionSynchronized();
      expect(ok, true);
      expect(repo.backendState[101], false);
      expect(repo.backendState[102], false);
      expect(repo.backendState[201], false);
      expect(repo.syncCallHistory.length, 3);
    });

    testWidgets('6. Checkout is blocked while synchronization is pending', (
      tester,
    ) async {
      final sample = _buildSampleCart(
        item101Selected: false,
        item102Selected: false,
      );
      final repo = _TrackingSyncRepo(
        cartData: sample,
        delayDuration: const Duration(milliseconds: 300),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartCheckoutRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: ShoppingCartScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap item 101 to select
      await tester.tap(find.byKey(const Key('checkbox_item_101')));
      await tester.pump(); // Start sync without settling delay

      // Checkout button must be disabled while sync is in flight
      final checkoutBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('btn_proceed_checkout')),
      );
      expect(checkoutBtn.onPressed, isNull);

      // Now settle the delay
      await tester.pumpAndSettle();

      // Now that sync finished, button becomes enabled
      final checkoutBtnAfter = tester.widget<ElevatedButton>(
        find.byKey(const Key('btn_proceed_checkout')),
      );
      expect(checkoutBtnAfter.onPressed, isNotNull);
    });

    testWidgets('7. Checkout proceeds only after successful synchronization', (
      tester,
    ) async {
      final sample = _buildSampleCart(
        item101Selected: true,
        item102Selected: false,
      );
      final repo = _TrackingSyncRepo(cartData: sample);

      String navigatedExtra = '';
      final router = GoRouter(
        initialLocation: '/cart',
        routes: [
          GoRoute(path: '/cart', builder: (_, _) => const ShoppingCartScreen()),
          GoRoute(
            path: '/checkout',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              navigatedExtra = extra.toString();
              return const Scaffold(body: Text('Checkout Screen Reached'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartCheckoutRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Tap proceed to checkout
      await tester.tap(find.byKey(const Key('btn_proceed_checkout')));
      await tester.pumpAndSettle();

      expect(find.text('Checkout Screen Reached'), findsOneWidget);
      expect(navigatedExtra.contains('cartItemIds: [101]'), true);
    });

    testWidgets(
      '8. Synchronization failure prevents navigation and informs user',
      (tester) async {
        final sample = _buildSampleCart(
          item101Selected: false,
          item102Selected: false,
        );
        final repo = _TrackingSyncRepo(cartData: sample);
        repo.failItemIds.add(101); // Item 101 will fail

        bool navigated = false;
        final router = GoRouter(
          initialLocation: '/cart',
          routes: [
            GoRoute(
              path: '/cart',
              builder: (_, _) => const ShoppingCartScreen(),
            ),
            GoRoute(
              path: '/checkout',
              builder: (_, _) {
                navigated = true;
                return const Scaffold(body: Text('Checkout Screen'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [cartCheckoutRepositoryProvider.overrideWithValue(repo)],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Toggle item 101
        await tester.tap(find.byKey(const Key('checkbox_item_101')));
        await tester.pumpAndSettle();

        // Error banner displayed on screen
        expect(
          find.byKey(const Key('cart_selection_error_banner')),
          findsOneWidget,
        );
        expect(find.textContaining('Không thể đồng bộ'), findsOneWidget);

        // Navigation did not happen
        expect(navigated, false);
        expect(find.text('Checkout Screen'), findsNothing);
      },
    );

    test(
      '9. Failure handling restores a consistent UI/backend state',
      () async {
        // Starts true
        final sample = _buildSampleCart(item101Selected: true);
        final repo = _TrackingSyncRepo(cartData: sample);
        repo.failItemIds.add(101); // Will throw on sync
        final vm = CartViewModel(repository: repo);
        await vm.loadCart();

        expect(repo.backendState[101], true);
        expect(vm.selectedItemIds.contains(101), true);

        // User deselects item 101
        vm.toggleItemSelection(101);

        // Optimistically deselected
        expect(vm.selectedItemIds.contains(101), false);

        // Wait for sync loop to fail and rollback
        await vm.ensureSelectionSynchronized();

        // Selection state must roll back to true, consistent with backend
        expect(vm.selectedItemIds.contains(101), true);
        expect(repo.backendState[101], true);
        expect(vm.selectionErrorMessage, isNotNull);
      },
    );

    test('10. Rapid toggles do not leave the backend with an incorrect final selection', () async {
      final sample = _buildSampleCart(item101Selected: true);
      final repo = _TrackingSyncRepo(
        cartData: sample,
        delayDuration: const Duration(milliseconds: 50),
      );
      final vm = CartViewModel(repository: repo);
      await vm.loadCart();

      expect(repo.backendState[101], true);

      // Rapidly toggle: true -> false -> true
      vm.toggleItemSelection(101);
      expect(vm.selectedItemIds.contains(101), false);

      vm.toggleItemSelection(101);
      expect(vm.selectedItemIds.contains(101), true);

      // Wait for all sync loops to finish
      final ok = await vm.ensureSelectionSynchronized();
      expect(ok, true);

      // Final backend state must match UI state: true
      expect(repo.backendState[101], true);
      expect(vm.selectedItemIds.contains(101), true);
    });
  });
}
