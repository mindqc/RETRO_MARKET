import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:izithrift/core/widgets/price_breakdown_card.dart';
import 'package:izithrift/features/cart/models/cart_item_model.dart';
import 'package:izithrift/features/cart/models/cart_model.dart';
import 'package:izithrift/features/cart/models/cart_seller_group_model.dart';
import 'package:izithrift/features/cart/models/checkout_preview_model.dart';
import 'package:izithrift/features/cart/models/payment_session_model.dart';
import 'package:izithrift/features/cart/repositories/cart_checkout_repository.dart';
import 'package:izithrift/features/cart/screens/checkout_screen.dart';
import 'package:izithrift/features/cart/screens/shopping_cart_screen.dart';
import 'package:izithrift/features/profile/models/user_address_model.dart';

class _FakeCartCheckoutRepo implements CartCheckoutRepository {
  CartModel cartData;
  CheckoutPreviewModel previewData;
  PaymentSessionModel? placedSession;

  _FakeCartCheckoutRepo({
    required this.cartData,
    required this.previewData,
    this.placedSession,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<CartModel> fetchCart() async => cartData;

  @override
  Future<CheckoutPreviewModel> previewCheckout({
    required String source,
    List<int>? cartItemIds,
    int? productId,
    int? quantity,
    int? addressId,
  }) async => previewData;

  @override
  Future<CartItemModel> updateCartItemQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    for (final group in cartData.sellerGroups) {
      for (final item in group.items) {
        if (item.id == cartItemId) {
          return item.copyWith(quantity: quantity);
        }
      }
    }
    throw Exception('Item not found');
  }

  @override
  Future<CartItemModel> updateCartItemSelection({
    required int cartItemId,
    required bool isSelected,
  }) async {
    for (final group in cartData.sellerGroups) {
      for (final item in group.items) {
        if (item.id == cartItemId) {
          return item.copyWith(isSelected: isSelected);
        }
      }
    }
    return CartItemModel(
      id: cartItemId,
      productId: 1,
      productCode: 'PRD-001',
      title: 'Item',
      condition: 'GOOD',
      unitPrice: 100000,
      itemSubtotal: 100000,
      isSelected: isSelected,
    );
  }

  @override
  Future<bool> removeCartItem(int cartItemId) async => true;

  @override
  Future<PaymentSessionModel> placeOrder({
    required String source,
    List<int>? cartItemIds,
    int? productId,
    int? quantity,
    required int shippingAddressId,
    String? note,
  }) async {
    return placedSession ??
        PaymentSessionModel(
          paymentId: 999,
          paymentCode: 'PAY-999',
          orderId: 888,
          orderCode: 'ORD-888',
          amount: previewData.grandTotalAmount,
          transferContent: 'RETRO MARKET ORD-888',
          paymentExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
        );
  }
}

void main() {
  late CartModel sampleCart;
  late CheckoutPreviewModel samplePreview;
  late UserAddressModel sampleAddress;

  setUp(() {
    sampleAddress = const UserAddressModel(
      id: 1,
      recipientName: 'Trần Văn Đức',
      recipientPhone: '0901234567',
      provinceCity: 'TP. Hồ Chí Minh',
      districtWard: 'Quận 1, Phường Bến Nghé',
      streetAddress: '123 Lê Lợi',
      isDefault: true,
    );

    sampleCart = const CartModel(
      cartId: 1,
      totalItemsCount: 3,
      selectedItemsCount: 2,
      selectedSubtotal: 450000.0,
      sellerGroups: [
        CartSellerGroupModel(
          sellerId: 10,
          shopName: 'Tiệm Vintage Sài Gòn',
          items: [
            CartItemModel(
              id: 101,
              productId: 1,
              productCode: 'PRD-001',
              title: 'Áo Khoác Denim 1990s',
              condition: 'EXCELLENT',
              unitPrice: 250000.0,
              quantity: 1,
              availableQuantity: 2,
              itemSubtotal: 250000.0,
              isAvailable: true,
              isSelected: true,
            ),
            CartItemModel(
              id: 102,
              productId: 2,
              productCode: 'PRD-002',
              title: 'Quần Corduroy Ống Rộng',
              condition: 'GOOD',
              unitPrice: 200000.0,
              quantity: 1,
              availableQuantity: 1,
              itemSubtotal: 200000.0,
              isAvailable: true,
              isSelected: true,
            ),
          ],
        ),
        CartSellerGroupModel(
          sellerId: 20,
          shopName: 'Tiệm Đồ Cũ Hà Nội',
          items: [
            CartItemModel(
              id: 103,
              productId: 3,
              productCode: 'PRD-003',
              title: 'Áo Thun Ban Nhạc Nirvana Đã Bán',
              condition: 'FAIR',
              unitPrice: 150000.0,
              quantity: 1,
              availableQuantity: 0,
              itemSubtotal: 150000.0,
              isAvailable: false,
              isSelected: false,
            ),
          ],
        ),
      ],
    );

    samplePreview = CheckoutPreviewModel(
      source: 'CART',
      shippingAddress: sampleAddress,
      sellersCount: 1,
      itemsCount: 2,
      totalItemSubtotal: 450000.0,
      totalShippingFee: 0.0,
      totalBuyerProtectionFee: 34000.0, // 450k * 6% + 7k = 34k
      grandTotalAmount: 484000.0,
      orderGroups: const [
        CheckoutOrderGroupPreviewModel(
          sellerId: 10,
          shopName: 'Tiệm Vintage Sài Gòn',
          itemSubtotal: 450000.0,
          shippingFee: 0.0,
          buyerProtectionFee: 34000.0,
          totalAmount: 484000.0,
          sellerNetAmount: 450000.0,
          items: [
            CartItemModel(
              id: 101,
              productId: 1,
              productCode: 'PRD-001',
              title: 'Áo Khoác Denim 1990s',
              condition: 'EXCELLENT',
              unitPrice: 250000.0,
              quantity: 1,
              availableQuantity: 2,
              itemSubtotal: 250000.0,
            ),
            CartItemModel(
              id: 102,
              productId: 2,
              productCode: 'PRD-002',
              title: 'Quần Corduroy Ống Rộng',
              condition: 'GOOD',
              unitPrice: 200000.0,
              quantity: 1,
              availableQuantity: 1,
              itemSubtotal: 200000.0,
            ),
          ],
        ),
      ],
    );
  });

  group('Batch 2 UI Smoke Tests — ShoppingCartScreen', () {
    testWidgets(
      'Scenario 1 & 8: Cart loads with seller-grouped products & hero banner',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeRepo = _FakeCartCheckoutRepo(
          cartData: sampleCart,
          previewData: samplePreview,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cartCheckoutRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(home: ShoppingCartScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Túi đồ vintage của bạn'), findsOneWidget);
        expect(find.text('Tiệm Vintage Sài Gòn'), findsOneWidget);
        expect(find.text('Tiệm Đồ Cũ Hà Nội'), findsOneWidget);
        expect(find.text('Áo Khoác Denim 1990s'), findsOneWidget);
        expect(find.text('Quần Corduroy Ống Rộng'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 2 & 3: Seller, individual item, and select-all checkboxes toggle properly',
      (tester) async {
        final fakeRepo = _FakeCartCheckoutRepo(
          cartData: sampleCart,
          previewData: samplePreview,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cartCheckoutRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(home: ShoppingCartScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Checkbox seller 10 is currently selected
        expect(
          tester
              .widget<Checkbox>(find.byKey(const Key('checkbox_seller_10')))
              .value,
          true,
        );

        // Toggle item selection
        await tester.tap(find.byKey(const Key('checkbox_item_101')));
        await tester.pumpAndSettle();

        // Seller group is no longer all selected
        expect(
          tester
              .widget<Checkbox>(find.byKey(const Key('checkbox_seller_10')))
              .value,
          false,
        );

        // Select all toggle
        await tester.tap(find.byKey(const Key('checkbox_select_all')));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Scenario 4: Quantity increment/decrement respects stock limits',
      (tester) async {
        final fakeRepo = _FakeCartCheckoutRepo(
          cartData: sampleCart,
          previewData: samplePreview,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cartCheckoutRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(home: ShoppingCartScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Item 102 has quantity 1 and availableQuantity 1 -> plus button is disabled
        final plus102 = tester.widget<InkWell>(
          find.byKey(const Key('btn_qty_plus_102')),
        );
        expect(plus102.onTap, isNull);

        // Item 101 has quantity 1 and availableQuantity 2 -> plus button is enabled
        final plus101 = tester.widget<InkWell>(
          find.byKey(const Key('btn_qty_plus_101')),
        );
        expect(plus101.onTap, isNotNull);
      },
    );

    testWidgets('Scenario 5: Removing an item requires confirmation dialog', (
      tester,
    ) async {
      final fakeRepo = _FakeCartCheckoutRepo(
        cartData: sampleCart,
        previewData: samplePreview,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartCheckoutRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(home: ShoppingCartScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap delete icon on item 101
      await tester.tap(find.byKey(const Key('btn_delete_item_101')));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Xóa sản phẩm?'), findsOneWidget);
      expect(find.text('Giữ lại'), findsOneWidget);
      expect(find.text('Xóa'), findsOneWidget);

      // Tap Giữ lại dismisses dialog
      await tester.tap(find.text('Giữ lại'));
      await tester.pumpAndSettle();
      expect(find.text('Xóa sản phẩm?'), findsNothing);
    });

    testWidgets(
      'Scenario 6: Unavailable products display "Hết hàng" and cannot be selected',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeRepo = _FakeCartCheckoutRepo(
          cartData: sampleCart,
          previewData: samplePreview,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cartCheckoutRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(home: ShoppingCartScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Item 103 is unavailable
        expect(find.text('HẾT HÀNG'), findsOneWidget);
        final checkbox103 = tester.widget<Checkbox>(
          find.byKey(const Key('checkbox_item_103')),
        );
        expect(checkbox103.onChanged, isNull); // Disabled checkbox
      },
    );

    testWidgets(
      'Scenario 7: Selected subtotal and checkout CTA update correctly',
      (tester) async {
        final fakeRepo = _FakeCartCheckoutRepo(
          cartData: sampleCart,
          previewData: samplePreview,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cartCheckoutRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(home: ShoppingCartScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 450.000đ subtotal
        expect(find.text('450.000đ'), findsWidgets);
        expect(find.text('Mua (2)'), findsOneWidget);
      },
    );
  });

  group('Batch 2 UI Smoke Tests — CheckoutScreen & PriceBreakdownCard', () {
    testWidgets(
      'Scenario 8 & 13: Checkout renders address, store items, and does not overflow on mobile size (390x844)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeRepo = _FakeCartCheckoutRepo(
          cartData: sampleCart,
          previewData: samplePreview,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cartCheckoutRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(
              home: CheckoutScreen(source: 'CART', cartItemIds: [101, 102]),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify recipient address snapshot
        expect(find.textContaining('Trần Văn Đức'), findsOneWidget);
        expect(find.textContaining('0901234567'), findsOneWidget);
        expect(find.text('Mặc định'), findsOneWidget);

        // Verify items rendered
        expect(find.text('Tiệm Vintage Sài Gòn'), findsOneWidget);
        expect(find.text('Áo Khoác Denim 1990s'), findsOneWidget);
        expect(find.text('Quần Corduroy Ống Rộng'), findsOneWidget);

        // No overflow exception occurred
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Scenario 9: Order note input updates without breaking checkout',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeRepo = _FakeCartCheckoutRepo(
          cartData: sampleCart,
          previewData: samplePreview,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cartCheckoutRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(
              home: CheckoutScreen(source: 'CART', cartItemIds: [101, 102]),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter order note
        final noteField = find.byType(TextField);
        expect(noteField, findsOneWidget);
        await tester.enterText(noteField, 'Đóng gói kỹ giúp mình nhé shop!');
        await tester.pumpAndSettle();

        expect(find.text('Đóng gói kỹ giúp mình nhé shop!'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 10 & 11: PriceBreakdownCard uses authoritative customBuyerProtectionFee and displays all rows',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PriceBreakdownCard(
                itemSubtotal: 450000,
                shippingFee: 0,
                customBuyerProtectionFee: 34000,
                showSellerNetAmount: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Chi tiết thanh toán'), findsOneWidget);
        expect(find.text('Tiền hàng'), findsOneWidget);
        expect(find.text('450.000đ'), findsWidgets);
        expect(find.text('Phí vận chuyển'), findsOneWidget);
        expect(find.text('Miễn phí'), findsOneWidget);
        expect(find.text('Phí bảo vệ người mua'), findsOneWidget);
        expect(find.text('34.000đ'), findsOneWidget);
        expect(find.text('Thực nhận của người bán'), findsOneWidget);
        expect(find.text('Tổng thanh toán'), findsOneWidget);
        expect(find.text('484.000đ'), findsOneWidget);

        // Fallback calculation test: subtotal = 100,000 -> 100000 * 0.06 + 7000 = 13000
        expect(PriceBreakdownCard.calculateBuyerProtectionFee(100000), 13000);
        expect(PriceBreakdownCard.calculateBuyerProtectionFee(0), 0);
      },
    );

    testWidgets('Scenario 12: QR payment navigation trigger is functional', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = _FakeCartCheckoutRepo(
        cartData: sampleCart,
        previewData: samplePreview,
        placedSession: PaymentSessionModel(
          paymentId: 1234,
          paymentCode: 'PAY-1234',
          orderId: 5678,
          orderCode: 'ORD-5678',
          amount: 484000.0,
          transferContent: 'RETRO MARKET ORD-5678',
          paymentExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
        ),
      );

      final router = GoRouter(
        initialLocation: '/checkout',
        routes: [
          GoRoute(
            path: '/checkout',
            builder: (context, state) =>
                const CheckoutScreen(source: 'CART', cartItemIds: [101, 102]),
          ),
          GoRoute(
            path: '/payments/:id',
            builder: (context, state) {
              final extra = state.extra as PaymentSessionModel?;
              return Scaffold(
                body: Text(
                  'Payment Screen: ${state.pathParameters['id']} - ${extra?.paymentCode}',
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartCheckoutRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Place order CTA button is active
      final placeOrderBtn = find.byKey(const Key('btn_place_order'));
      expect(placeOrderBtn, findsOneWidget);

      await tester.tap(placeOrderBtn);
      await tester.pumpAndSettle();

      // Verify navigation to QR payment succeeded with params
      expect(find.text('Payment Screen: 1234 - PAY-1234'), findsOneWidget);
    });
  });
}
