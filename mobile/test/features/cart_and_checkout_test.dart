import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:izithrift/core/network/dio_client.dart';
import 'package:izithrift/core/services/secure_token_storage.dart';
import 'package:izithrift/core/services/server_time_service.dart';
import 'package:izithrift/core/widgets/price_breakdown_card.dart';
import 'package:izithrift/core/widgets/state_feedback_views.dart';
import 'package:izithrift/features/cart/models/cart_item_model.dart';
import 'package:izithrift/features/cart/models/cart_seller_group_model.dart';
import 'package:izithrift/features/cart/models/cart_model.dart';
import 'package:izithrift/features/cart/models/checkout_preview_model.dart';
import 'package:izithrift/features/cart/models/payment_session_model.dart';
import 'package:izithrift/features/cart/repositories/cart_checkout_repository.dart';
import 'package:izithrift/features/cart/viewmodels/cart_view_model.dart';
import 'package:izithrift/features/cart/viewmodels/checkout_view_model.dart';
import 'package:izithrift/features/cart/screens/shopping_cart_screen.dart';
import 'package:izithrift/features/cart/screens/checkout_screen.dart';
import 'package:izithrift/features/cart/screens/mock_qr_payment_screen.dart';
import 'package:izithrift/features/cart/screens/payment_success_screen.dart';
import 'package:izithrift/features/cart/screens/payment_failure_screen.dart';
import 'package:izithrift/features/profile/models/user_address_model.dart';

/// Mock implementation of CartCheckoutRepository for unit and widget tests
class MockCartCheckoutRepository extends CartCheckoutRepository {
  MockCartCheckoutRepository()
    : super(
        dioClient: DioClient(
          tokenStorage: SecureTokenStorage(),
          serverTimeService: ServerTimeService.instance,
        ),
      );

  CartModel? stubCart;
  CheckoutPreviewModel? stubPreview;
  PaymentSessionModel? stubSession;

  bool addToCartCalled = false;
  bool updateQuantityCalled = false;
  bool updateSelectionCalled = false;
  int? lastUpdatedCartItemId;
  bool? lastUpdatedIsSelected;
  bool removeCartItemCalled = false;
  bool previewCheckoutCalled = false;
  bool placeOrderCalled = false;
  bool simulateSuccessCalled = false;
  bool simulateFailureCalled = false;

  String? lastPreviewSource;
  List<int>? lastPreviewCartItemIds;
  int? lastPreviewProductId;
  int? lastPreviewQuantity;
  int? lastPreviewAddressId;

  String? lastPlaceOrderSource;
  List<int>? lastPlaceOrderCartItemIds;
  int? lastPlaceOrderProductId;
  int? lastPlaceOrderQuantity;
  int? lastPlaceOrderShippingAddressId;

  @override
  Future<CartModel> fetchCart() async {
    return stubCart ??
        const CartModel(cartId: 1, sellerGroups: [], totalItemsCount: 0);
  }

  @override
  Future<CartItemModel> addToCart({
    required int productId,
    int quantity = 1,
  }) async {
    addToCartCalled = true;
    return CartItemModel(
      id: 99,
      productId: productId,
      productCode: 'PRD-$productId',
      title: 'Added Item',
      condition: 'GOOD',
      unitPrice: 100000.0,
      quantity: quantity,
      availableQuantity: 5,
      itemSubtotal: 100000.0 * quantity,
    );
  }

  @override
  Future<CartItemModel> updateCartItemQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    updateQuantityCalled = true;
    return CartItemModel(
      id: cartItemId,
      productId: 101,
      productCode: 'PRD-101',
      title: 'Updated Item',
      condition: 'EXCELLENT',
      unitPrice: 350000.0,
      quantity: quantity,
      availableQuantity: 5,
      itemSubtotal: 350000.0 * quantity,
    );
  }

  @override
  Future<CartItemModel> updateCartItemSelection({
    required int cartItemId,
    required bool isSelected,
  }) async {
    updateSelectionCalled = true;
    lastUpdatedCartItemId = cartItemId;
    lastUpdatedIsSelected = isSelected;
    return CartItemModel(
      id: cartItemId,
      productId: 101,
      productCode: 'PRD-101',
      title: 'Updated Item',
      condition: 'EXCELLENT',
      unitPrice: 350000.0,
      quantity: 1,
      availableQuantity: 5,
      itemSubtotal: 350000.0,
      isSelected: isSelected,
    );
  }

  @override
  Future<bool> removeCartItem(int cartItemId) async {
    removeCartItemCalled = true;
    return true;
  }

  @override
  Future<CheckoutPreviewModel> previewCheckout({
    required String source,
    List<int>? cartItemIds,
    int? productId,
    int? quantity,
    int? addressId,
  }) async {
    previewCheckoutCalled = true;
    lastPreviewSource = source;
    lastPreviewCartItemIds = cartItemIds;
    lastPreviewProductId = productId;
    lastPreviewQuantity = quantity;
    lastPreviewAddressId = addressId;
    return stubPreview ??
        const CheckoutPreviewModel(
          source: 'CART',
          sellersCount: 1,
          itemsCount: 1,
          totalItemSubtotal: 350000.0,
          totalBuyerProtectionFee:
              28000.0, // 350000 * 0.06 + 7000 = 21000 + 7000 = 28000
          totalShippingFee: 0.0,
          grandTotalAmount: 378000.0,
          orderGroups: [],
        );
  }

  @override
  Future<PaymentSessionModel> placeOrder({
    required String source,
    List<int>? cartItemIds,
    int? productId,
    int? quantity,
    required int shippingAddressId,
    String? note,
  }) async {
    placeOrderCalled = true;
    lastPlaceOrderSource = source;
    lastPlaceOrderCartItemIds = cartItemIds;
    lastPlaceOrderProductId = productId;
    lastPlaceOrderQuantity = quantity;
    lastPlaceOrderShippingAddressId = shippingAddressId;
    return stubSession ??
        PaymentSessionModel(
          paymentId: 101,
          paymentCode: 'PAY-20261115-001',
          orderId: 501,
          orderCode: 'ORD-20261115-001',
          amount: 378000.0,
          paymentStatus: 'PENDING',
          escrowStatus: 'HELD',
          paymentExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
          qrCodeUrl:
              'https://img.vietqr.io/image/970422-RETROMARKET-compact2.png',
          transferContent: 'IZI 101 PAY-20261115-001',
        );
  }

  @override
  Future<PaymentSessionModel> fetchPaymentStatus(int paymentId) async {
    return stubSession ??
        PaymentSessionModel(
          paymentId: paymentId,
          paymentCode: 'PAY-20261115-001',
          orderId: 501,
          orderCode: 'ORD-20261115-001',
          amount: 378000.0,
          paymentStatus: 'PENDING',
          escrowStatus: 'HELD',
          paymentExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
          qrCodeUrl:
              'https://img.vietqr.io/image/970422-RETROMARKET-compact2.png',
          transferContent: 'IZI 101 PAY-20261115-001',
        );
  }

  @override
  Future<PaymentSessionModel> simulatePaymentSuccess(int paymentId) async {
    simulateSuccessCalled = true;
    return PaymentSessionModel(
      paymentId: paymentId,
      paymentCode: 'PAY-20261115-001',
      orderId: 501,
      orderCode: 'ORD-20261115-001',
      amount: 378000.0,
      paymentStatus: 'PAID',
      escrowStatus: 'HELD',
      orderStatus: 'PAID',
      paidAt: DateTime.now(),
      paymentExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
      qrCodeUrl: '',
      transferContent: 'IZI 101 PAY-20261115-001',
    );
  }

  @override
  Future<PaymentSessionModel> simulatePaymentFailure(
    int paymentId, {
    String? reason,
  }) async {
    simulateFailureCalled = true;
    return PaymentSessionModel(
      paymentId: paymentId,
      paymentCode: 'PAY-20261115-001',
      orderId: 501,
      orderCode: 'ORD-20261115-001',
      amount: 378000.0,
      paymentStatus: 'FAILED',
      escrowStatus: 'NOT_HELD',
      failureReason:
          reason ?? 'Số dư tài khoản không đủ hoặc timeout giao dịch.',
      paymentExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
      qrCodeUrl: '',
      transferContent: 'IZI 101 PAY-20261115-001',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Test Sample Data
  const sampleItem1 = CartItemModel(
    id: 11,
    productId: 101,
    productCode: 'PRD-101',
    title: 'Áo Khoác Denim Vintage Levis 1990s',
    primaryImageUrl:
        'https://images.unsplash.com/photo-1544441893-675973e31985?w=500',
    condition: 'EXCELLENT',
    unitPrice: 350000.0,
    quantity: 1,
    availableQuantity: 1,
    itemSubtotal: 350000.0,
    isSelected: true,
  );

  const sampleItem2 = CartItemModel(
    id: 12,
    productId: 102,
    productCode: 'PRD-102',
    title: 'Quần Corduroy Ống Suông Retro',
    primaryImageUrl:
        'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=500',
    condition: 'VERY_GOOD',
    unitPrice: 200000.0,
    quantity: 1,
    availableQuantity: 2,
    itemSubtotal: 200000.0,
    isSelected: true,
  );

  const sampleSellerGroup1 = CartSellerGroupModel(
    sellerId: 1,
    shopName: 'Tiệm Đồ Si Sài Gòn',
    items: [sampleItem1],
    sellerSubtotal: 350000.0,
  );

  const sampleSellerGroup2 = CartSellerGroupModel(
    sellerId: 2,
    shopName: 'Retro Vintage Hanoi',
    items: [sampleItem2],
    sellerSubtotal: 200000.0,
  );

  const sampleCart = CartModel(
    cartId: 1,
    sellerGroups: [sampleSellerGroup1, sampleSellerGroup2],
    totalItemsCount: 2,
    selectedItemsCount: 2,
    selectedSubtotal: 550000.0,
  );

  const sampleAddress = UserAddressModel(
    id: 1,
    recipientName: 'Trần Văn Đức',
    recipientPhone: '0901234567',
    provinceCity: 'Thành phố Hồ Chí Minh',
    districtWard: 'Quận 1, Phường Bến Nghé',
    streetAddress: '123 Đường Đồng Khởi',
    isDefault: true,
  );

  const samplePreview = CheckoutPreviewModel(
    source: 'CART',
    sellersCount: 2,
    itemsCount: 2,
    totalItemSubtotal: 550000.0,
    totalBuyerProtectionFee:
        40000.0, // 550000 * 0.06 + 7000 = 33000 + 7000 = 40000
    totalShippingFee: 0.0,
    grandTotalAmount: 590000.0,
    orderGroups: [
      CheckoutOrderGroupPreviewModel(
        sellerId: 1,
        shopName: 'Tiệm Đồ Si Sài Gòn',
        items: [sampleItem1],
        itemSubtotal: 350000.0,
        shippingFee: 0.0,
        buyerProtectionFee: 28000.0,
        totalAmount: 378000.0,
        sellerNetAmount: 350000.0,
      ),
      CheckoutOrderGroupPreviewModel(
        sellerId: 2,
        shopName: 'Retro Vintage Hanoi',
        items: [sampleItem2],
        itemSubtotal: 200000.0,
        shippingFee: 0.0,
        buyerProtectionFee: 19000.0,
        totalAmount: 219000.0,
        sellerNetAmount: 200000.0,
      ),
    ],
    shippingAddress: sampleAddress,
  );

  group('P7-08 Cart & Checkout Models & Fee Formula (DEC-04) Tests', () {
    test(
      'CartItemModel, CartSellerGroupModel, CartModel parse JSON correctly',
      () {
        final json = {
          'cart_id': 1,
          'seller_groups': [
            {
              'seller_id': 1,
              'shop_name': 'Tiệm Đồ Si Sài Gòn',
              'seller_subtotal': '350000',
              'items': [
                {
                  'id': 11,
                  'product_id': 101,
                  'product_code': 'PRD-101',
                  'title': 'Áo Khoác Denim Vintage Levis 1990s',
                  'image_url': 'https://example.com/img.jpg',
                  'condition': 'EXCELLENT',
                  'price': '350000',
                  'quantity': 1,
                  'available_quantity': 1,
                  'line_total': '350000',
                },
              ],
            },
          ],
          'total_items_count': 1,
          'selected_items_count': 1,
          'selected_subtotal': '350000',
        };

        final cart = CartModel.fromJson(json);
        expect(cart.cartId, equals(1));
        expect(cart.totalItemsCount, equals(1));
        expect(cart.sellerGroups.length, equals(1));

        final group = cart.sellerGroups.first;
        expect(group.sellerId, equals(1));
        expect(group.shopName, equals('Tiệm Đồ Si Sài Gòn'));
        expect(group.sellerSubtotal, equals(350000.0));

        final item = group.items.first;
        expect(item.id, equals(11));
        expect(item.title, equals('Áo Khoác Denim Vintage Levis 1990s'));
        expect(item.unitPrice, equals(350000.0));
        expect(item.condition, equals('EXCELLENT'));
      },
    );

    test('CheckoutPreviewModel parses DEC-04 fee breakdown accurately', () {
      final json = {
        'source': 'CART',
        'summary': {
          'item_subtotal': '550000',
          'buyer_protection_fee': '40000',
          'shipping_fee': '0',
          'grand_total': '590000',
        },
        'seller_groups': [
          {
            'seller_id': 1,
            'shop_name': 'Tiệm Đồ Si Sài Gòn',
            'item_subtotal': '350000',
            'buyer_protection_fee': '28000',
            'total_amount': '378000',
            'seller_net_amount': '350000',
            'items': [
              {
                'id': 11,
                'product_id': 101,
                'product_code': 'PRD-101',
                'title': 'Áo Khoác Denim Vintage',
                'image_url': 'https://example.com/img.jpg',
                'condition': 'LIKE_NEW',
                'price': '350000',
                'quantity': 1,
                'available_quantity': 1,
                'line_total': '350000',
              },
            ],
          },
        ],
        'shipping_address': {
          'id': 1,
          'recipient_name': 'Trần Văn Đức',
          'phone': '0901234567',
          'province': 'TP. Hồ Chí Minh',
          'district': 'Quận 1',
          'ward': 'Phường Bến Nghé',
          'street_address': '123 Đường Đồng Khởi',
          'is_default': true,
        },
      };

      final preview = CheckoutPreviewModel.fromJson(json);
      expect(preview.totalItemSubtotal, equals(550000.0));
      expect(preview.totalBuyerProtectionFee, equals(40000.0));
      expect(preview.totalShippingFee, equals(0.0));
      expect(preview.grandTotalAmount, equals(590000.0));
      expect(preview.orderGroups.length, equals(1));
      expect(preview.shippingAddress?.recipientName, equals('Trần Văn Đức'));

      // Validate DEC-04 formula: (550,000 * 0.06) + 7,000 = 33,000 + 7,000 = 40,000
      final computedFee = PriceBreakdownCard.calculateBuyerProtectionFee(
        preview.totalItemSubtotal,
      );
      expect(computedFee, equals(preview.totalBuyerProtectionFee));
    });

    test('PaymentSessionModel parses mock escrow session and expiration', () {
      final json = {
        'payment_id': 101,
        'payment_code': 'PAY-20261115-001',
        'order_id': 501,
        'order_code': 'ORD-20261115-001',
        'amount': '590000',
        'payment_status': 'PENDING',
        'escrow_status': 'HELD',
        'payment_expires_at': '2026-11-15T15:30:00Z',
        'qr_code_url':
            'https://img.vietqr.io/image/970422-RETROMARKET-compact2.png',
        'transfer_content': 'IZI 101 PAY-20261115-001',
      };

      final session = PaymentSessionModel.fromJson(json);
      expect(session.paymentId, equals(101));
      expect(session.paymentCode, equals('PAY-20261115-001'));
      expect(session.amount, equals(590000.0));
      expect(session.paymentStatus, equals('PENDING'));
      expect(session.escrowStatus, equals('HELD'));
      expect(session.transferContent, equals('IZI 101 PAY-20261115-001'));
    });
  });

  group('P7-08 CartViewModel Group Selection Logic Tests (BR-OR-01)', () {
    test(
      'CartViewModel handles item selection, group toggle, and select all',
      () async {
        final mockRepo = MockCartCheckoutRepository();
        mockRepo.stubCart = sampleCart;

        final vm = CartViewModel(repository: mockRepo);
        await vm.loadCart();

        // Initially all items in the cart are selected by default
        expect(vm.selectedItemIds.length, equals(2));
        expect(vm.isAllSelected, isTrue);
        expect(vm.selectedItemsCount, equals(2));
        expect(vm.selectedItemsSubtotal, equals(550000.0));

        // Toggle individual item
        vm.toggleItemSelection(11);
        expect(vm.selectedItemIds.contains(11), isFalse);
        expect(vm.selectedItemIds.contains(12), isTrue);
        expect(vm.isAllSelected, isFalse);
        expect(vm.isSellerGroupFullySelected(sampleSellerGroup1), isFalse);
        expect(vm.selectedItemsSubtotal, equals(200000.0));

        // Toggle seller group 1 back on
        vm.toggleSellerGroupSelection(sampleSellerGroup1.sellerId);
        expect(vm.selectedItemIds.contains(11), isTrue);
        expect(vm.isSellerGroupFullySelected(sampleSellerGroup1), isTrue);
        expect(vm.isAllSelected, isTrue);

        // Toggle select all off
        vm.toggleSelectAll();
        expect(vm.selectedItemIds.isEmpty, isTrue);
        expect(vm.selectedItemsCount, equals(0));
        expect(vm.selectedItemsSubtotal, equals(0.0));

        // Toggle select all on
        vm.toggleSelectAll();
        expect(vm.selectedItemIds.length, equals(2));
        expect(vm.isAllSelected, isTrue);
      },
    );
  });

  group('P7-08 ShoppingCartScreen Widget Tests (M-CR-01)', () {
    testWidgets('Empty cart displays RetroEmptyStateView with CTA', (
      tester,
    ) async {
      final mockRepo = MockCartCheckoutRepository();
      mockRepo.stubCart = const CartModel(
        cartId: 1,
        sellerGroups: [],
        totalItemsCount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartCheckoutRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: ShoppingCartScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(RetroEmptyStateView), findsOneWidget);
      expect(find.textContaining('Giỏ hàng'), findsWidgets);
      expect(find.text('Khám phá ngay'), findsOneWidget);
    });

    testWidgets(
      'Populated cart renders seller groups (BR-OR-01) and checkout bottom bar',
      (tester) async {
        final mockRepo = MockCartCheckoutRepository();
        mockRepo.stubCart = sampleCart;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cartCheckoutRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: const MaterialApp(home: ShoppingCartScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Verify seller headers
        expect(find.text('Tiệm Đồ Si Sài Gòn'), findsOneWidget);
        expect(find.text('Retro Vintage Hanoi'), findsOneWidget);

        // Verify products
        expect(find.text('Áo Khoác Denim Vintage Levis 1990s'), findsOneWidget);
        expect(find.text('Quần Corduroy Ống Suông Retro'), findsOneWidget);

        // Verify checkout bar
        expect(find.byKey(const Key('btn_proceed_checkout')), findsOneWidget);
        expect(find.textContaining('Mua'), findsWidgets);
        expect(find.text('550.000đ'), findsWidgets);
      },
    );
  });

  group('P7-08 CheckoutScreen Widget Tests (DEC-04 & M-OR-01)', () {
    testWidgets(
      'CheckoutScreen renders address, items, and PriceBreakdownCard with DEC-04 formula',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final mockRepo = MockCartCheckoutRepository();
        mockRepo.stubPreview = samplePreview;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cartCheckoutRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: const MaterialApp(
              home: CheckoutScreen(source: 'CART', cartItemIds: [11, 12]),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check recipient address
        expect(find.textContaining('Trần Văn Đức'), findsOneWidget);
        expect(find.textContaining('0901234567'), findsOneWidget);

        // Check PriceBreakdownCard
        expect(find.byType(PriceBreakdownCard), findsOneWidget);
        expect(find.text('Tiền hàng'), findsOneWidget);
        expect(find.textContaining('Phí bảo vệ người mua'), findsOneWidget);
        expect(find.text('Phí vận chuyển'), findsOneWidget);
        expect(find.text('Miễn phí'), findsOneWidget);

        // Check Place Order CTA
        expect(find.byKey(const Key('btn_place_order')), findsOneWidget);
        expect(find.textContaining('Đặt hàng'), findsOneWidget);
      },
    );
  });

  group('P7-08 Mock QR Escrow Payment Tests (M-PM-01..03 & BR-FN-03)', () {
    testWidgets(
      'MockQrPaymentScreen displays VietQR, transfer content, countdown timer, and Demo triggers',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final mockRepo = MockCartCheckoutRepository();
        final session = PaymentSessionModel(
          paymentId: 101,
          paymentCode: 'PAY-20261115-001',
          orderId: 501,
          orderCode: 'ORD-20261115-001',
          amount: 378000.0,
          paymentStatus: 'PENDING',
          escrowStatus: 'HELD',
          paymentExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
          qrCodeUrl:
              'https://img.vietqr.io/image/970422-RETROMARKET-compact2.png',
          transferContent: 'IZI 101 PAY-20261115-001',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cartCheckoutRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: MaterialApp(
              home: MockQrPaymentScreen(
                paymentId: 101,
                initialSession: session,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify QR header & Payment Code
        expect(find.text('Thanh toán đơn hàng'), findsOneWidget);
        expect(find.text('PAY-20261115-001'), findsOneWidget);
        expect(find.text('378.000đ'), findsOneWidget);

        // Verify VietQR details
        expect(find.text('IZI 101 PAY-20261115-001'), findsOneWidget);

        // Verify Demo mode action buttons
        expect(
          find.byKey(const Key('btn_simulate_payment_success')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('btn_simulate_payment_failure')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'PaymentSuccessScreen displays escrow held badge and navigation buttons',
      (tester) async {
        final successSession = PaymentSessionModel(
          paymentId: 101,
          paymentCode: 'PAY-20261115-001',
          orderId: 501,
          orderCode: 'ORD-20261115-001',
          amount: 378000.0,
          paymentStatus: 'PAID',
          escrowStatus: 'HELD',
          orderStatus: 'PAID',
          paidAt: DateTime.now(),
          paymentExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
          qrCodeUrl: '',
          transferContent: 'IZI 101 PAY-20261115-001',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PaymentSuccessScreen(paymentId: 101, session: successSession),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Thanh toán thành công!'), findsOneWidget);
        expect(find.textContaining('Escrow'), findsWidgets);
        expect(find.text('378.000đ'), findsOneWidget);
        expect(find.text('Xem chi tiết đơn mua'), findsOneWidget);
        expect(find.text('Tiếp tục mua sắm'), findsOneWidget);
      },
    );

    testWidgets(
      'PaymentFailureScreen displays error reason and retry buttons',
      (tester) async {
        final failureSession = PaymentSessionModel(
          paymentId: 101,
          paymentCode: 'PAY-20261115-001',
          orderId: 501,
          orderCode: 'ORD-20261115-001',
          amount: 378000.0,
          paymentStatus: 'FAILED',
          escrowStatus: 'NOT_HELD',
          failureReason:
              'Giao dịch hết thời gian chờ hoặc tài khoản chưa xác thực.',
          paymentExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
          qrCodeUrl: '',
          transferContent: 'IZI 101 PAY-20261115-001',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PaymentFailureScreen(paymentId: 101, session: failureSession),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Thanh toán chưa thành công'), findsOneWidget);
        expect(
          find.textContaining('Giao dịch hết thời gian chờ'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('btn_retry_payment')), findsOneWidget);
        expect(find.text('Về trang chủ'), findsOneWidget);
      },
    );
  });

  group('Batch 2.1B Patch A — Checkout Safety & Repository Parsing Tests', () {
    test('Repository data: [] -> Không crash', () {
      final repo = CartCheckoutRepository(
        dioClient: DioClient(
          tokenStorage: SecureTokenStorage(),
          serverTimeService: ServerTimeService.instance,
        ),
      );
      final dataFromList = repo.extractDataMap([]);
      expect(dataFromList, isEmpty);

      final dataFromNestedList = repo.extractDataMap({'data': []});
      expect(dataFromNestedList, isEmpty);

      final cart = CartModel.fromJson(dataFromList);
      expect(cart.cartId, equals(0));
      expect(cart.sellerGroups, isEmpty);
      expect(cart.isEmpty, isTrue);
    });

    test('Repository data: null -> Không crash', () {
      final repo = CartCheckoutRepository(
        dioClient: DioClient(
          tokenStorage: SecureTokenStorage(),
          serverTimeService: ServerTimeService.instance,
        ),
      );
      final dataFromNull = repo.extractDataMap(null);
      expect(dataFromNull, isEmpty);

      final dataFromNestedNull = repo.extractDataMap({'data': null});
      expect(dataFromNestedNull, isEmpty);

      final preview = CheckoutPreviewModel.fromJson(dataFromNull);
      expect(preview.orderGroups, isEmpty);
      expect(preview.grandTotalAmount, equals(0.0));
      expect(preview.itemsCount, equals(0));
    });

    test('Repository data: string -> Không crash', () {
      final repo = CartCheckoutRepository(
        dioClient: DioClient(
          tokenStorage: SecureTokenStorage(),
          serverTimeService: ServerTimeService.instance,
        ),
      );
      final dataFromString = repo.extractDataMap('invalid_string_response');
      expect(dataFromString, isEmpty);

      final dataFromNestedString = repo.extractDataMap({
        'data': 'nested_string',
      });
      expect(dataFromNestedString, isEmpty);

      final payment = PaymentSessionModel.fromJson(dataFromString);
      expect(payment.paymentId, equals(0));
      expect(payment.amount, equals(0.0));
      expect(payment.paymentStatus, equals('PENDING'));
    });

    test('Checkout preview có groups/items -> Success', () async {
      final mockRepo = MockCartCheckoutRepository();
      mockRepo.stubPreview = samplePreview;

      final vm = CheckoutViewModel(repository: mockRepo);
      await vm.loadCheckoutPreview(source: 'CART');

      expect(vm.state.isSuccess, isTrue);
      expect(vm.state.isEmpty, isFalse);
      expect(vm.isCheckoutValid, isTrue);
      expect(vm.state.data?.itemsCount, greaterThan(0));
      expect(vm.state.data?.grandTotalAmount, greaterThan(0.0));
    });

    test('Checkout preview groups empty -> Empty state', () async {
      final mockRepo = MockCartCheckoutRepository();
      mockRepo.stubPreview = const CheckoutPreviewModel(
        source: 'CART',
        sellersCount: 0,
        itemsCount: 0,
        totalItemSubtotal: 0.0,
        totalBuyerProtectionFee: 0.0,
        totalShippingFee: 0.0,
        grandTotalAmount: 0.0,
        orderGroups: [],
      );

      final vm = CheckoutViewModel(repository: mockRepo);
      await vm.loadCheckoutPreview(source: 'CART');

      expect(vm.state.isEmpty, isTrue);
      expect(vm.isCheckoutValid, isFalse);
    });

    test('Checkout preview itemsCount = 0 -> Empty state', () async {
      final mockRepo = MockCartCheckoutRepository();
      mockRepo.stubPreview = const CheckoutPreviewModel(
        source: 'CART',
        sellersCount: 1,
        itemsCount: 0,
        totalItemSubtotal: 0.0,
        totalBuyerProtectionFee: 0.0,
        totalShippingFee: 0.0,
        grandTotalAmount: 0.0,
        orderGroups: [
          CheckoutOrderGroupPreviewModel(
            sellerId: 1,
            shopName: 'Tiệm Đồ Si Sài Gòn',
            items: [],
            itemSubtotal: 0.0,
            buyerProtectionFee: 0.0,
            totalAmount: 0.0,
            sellerNetAmount: 0.0,
          ),
        ],
      );

      final vm = CheckoutViewModel(repository: mockRepo);
      await vm.loadCheckoutPreview(source: 'CART');

      expect(vm.state.isEmpty, isTrue);
      expect(vm.isCheckoutValid, isFalse);
    });

    test('Place order không có preview -> Không gọi repository', () async {
      final mockRepo = MockCartCheckoutRepository();
      final vm = CheckoutViewModel(repository: mockRepo);
      vm.selectedAddress = sampleAddress;

      final session = await vm.placeOrder();
      expect(session, isNull);
      expect(mockRepo.placeOrderCalled, isFalse);
      expect(vm.errorMessage, equals('Không có sản phẩm hợp lệ để đặt hàng.'));
    });

    test('Place order preview rỗng -> Không gọi repository', () async {
      final mockRepo = MockCartCheckoutRepository();
      mockRepo.stubPreview = const CheckoutPreviewModel(
        source: 'CART',
        sellersCount: 0,
        itemsCount: 0,
        totalItemSubtotal: 0.0,
        totalBuyerProtectionFee: 0.0,
        totalShippingFee: 0.0,
        grandTotalAmount: 0.0,
        orderGroups: [],
      );

      final vm = CheckoutViewModel(repository: mockRepo);
      vm.selectedAddress = sampleAddress;
      await vm.loadCheckoutPreview(source: 'CART');

      final session = await vm.placeOrder();
      expect(session, isNull);
      expect(mockRepo.placeOrderCalled, isFalse);
      expect(vm.errorMessage, equals('Không có sản phẩm hợp lệ để đặt hàng.'));
    });

    test('Place order total = 0 -> Không gọi repository', () async {
      final mockRepo = MockCartCheckoutRepository();
      mockRepo.stubPreview = CheckoutPreviewModel(
        source: 'CART',
        sellersCount: 1,
        itemsCount: 1,
        totalItemSubtotal: 0.0,
        totalBuyerProtectionFee: 0.0,
        totalShippingFee: 0.0,
        grandTotalAmount: 0.0,
        orderGroups: [
          CheckoutOrderGroupPreviewModel(
            sellerId: 1,
            shopName: 'Tiệm Đồ Si Sài Gòn',
            items: [
              const CartItemModel(
                id: 1,
                productId: 101,
                productCode: 'PRD-101',
                title: 'Free Vintage Item',
                condition: 'GOOD',
                unitPrice: 0.0,
                itemSubtotal: 0.0,
              ),
            ],
            itemSubtotal: 0.0,
            buyerProtectionFee: 0.0,
            totalAmount: 0.0,
            sellerNetAmount: 0.0,
          ),
        ],
      );

      final vm = CheckoutViewModel(repository: mockRepo);
      vm.selectedAddress = sampleAddress;
      await vm.loadCheckoutPreview(source: 'CART');

      final session = await vm.placeOrder();
      expect(session, isNull);
      expect(mockRepo.placeOrderCalled, isFalse);
      expect(vm.errorMessage, equals('Tổng thanh toán không hợp lệ.'));
    });

    test('Place order valid + address -> Gọi repository thành công', () async {
      final mockRepo = MockCartCheckoutRepository();
      mockRepo.stubPreview = samplePreview;

      final vm = CheckoutViewModel(repository: mockRepo);
      vm.selectedAddress = sampleAddress;
      await vm.loadCheckoutPreview(source: 'CART');

      expect(vm.isCheckoutValid, isTrue);
      final session = await vm.placeOrder();
      expect(session, isNotNull);
      expect(mockRepo.placeOrderCalled, isTrue);
      expect(session!.paymentId, equals(101));
    });

    test('Buy Now -> Giữ nguyên product ID + quantity', () async {
      final mockRepo = MockCartCheckoutRepository();
      mockRepo.stubPreview = samplePreview;

      final vm = CheckoutViewModel(repository: mockRepo);
      vm.selectedAddress = sampleAddress;
      await vm.loadCheckoutPreview(
        source: 'BUY_NOW',
        productId: 101,
        quantity: 2,
      );

      expect(mockRepo.previewCheckoutCalled, isTrue);
      expect(mockRepo.lastPreviewSource, equals('BUY_NOW'));
      expect(mockRepo.lastPreviewProductId, equals(101));
      expect(mockRepo.lastPreviewQuantity, equals(2));

      await vm.placeOrder();
      expect(mockRepo.placeOrderCalled, isTrue);
      expect(mockRepo.lastPlaceOrderSource, equals('BUY_NOW'));
      expect(mockRepo.lastPlaceOrderProductId, equals(101));
      expect(mockRepo.lastPlaceOrderQuantity, equals(2));
    });

    test('Cart checkout -> Giữ nguyên cart item IDs', () async {
      final mockRepo = MockCartCheckoutRepository();
      mockRepo.stubPreview = samplePreview;

      final vm = CheckoutViewModel(repository: mockRepo);
      vm.selectedAddress = sampleAddress;
      await vm.loadCheckoutPreview(source: 'CART', cartItemIds: [11, 12]);

      expect(mockRepo.previewCheckoutCalled, isTrue);
      expect(mockRepo.lastPreviewSource, equals('CART'));
      expect(mockRepo.lastPreviewCartItemIds, equals([11, 12]));

      await vm.placeOrder();
      expect(mockRepo.placeOrderCalled, isTrue);
      expect(mockRepo.lastPlaceOrderSource, equals('CART'));
      expect(mockRepo.lastPlaceOrderCartItemIds, equals([11, 12]));
    });

    testWidgets(
      'CheckoutScreen renders RetroEmptyStateView when checkout preview is empty',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final mockRepo = MockCartCheckoutRepository();
        mockRepo.stubPreview = const CheckoutPreviewModel(
          source: 'CART',
          sellersCount: 0,
          itemsCount: 0,
          totalItemSubtotal: 0.0,
          totalBuyerProtectionFee: 0.0,
          totalShippingFee: 0.0,
          grandTotalAmount: 0.0,
          orderGroups: [],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cartCheckoutRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: const MaterialApp(home: CheckoutScreen(source: 'CART')),
          ),
        );
        await tester.pumpAndSettle();

        // Empty state view is displayed, and place order button is absent
        expect(find.byType(RetroEmptyStateView), findsOneWidget);
        expect(find.text('Không có sản phẩm'), findsOneWidget);
        expect(find.byKey(const Key('btn_place_order')), findsNothing);
      },
    );
  });
}
