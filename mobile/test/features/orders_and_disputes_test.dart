import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:izithrift/core/network/api_envelope.dart';
import 'package:izithrift/core/network/dio_client.dart';
import 'package:izithrift/core/services/secure_token_storage.dart';
import 'package:izithrift/core/services/server_time_service.dart';
import 'package:izithrift/core/widgets/price_breakdown_card.dart';
import 'package:izithrift/features/orders/models/order_item_snapshot_model.dart';
import 'package:izithrift/features/orders/models/shipment_model.dart';
import 'package:izithrift/features/orders/models/order_model.dart';
import 'package:izithrift/features/orders/models/dispute_evidence_model.dart';
import 'package:izithrift/features/orders/models/dispute_model.dart';
import 'package:izithrift/features/orders/repositories/order_fulfillment_repository.dart';
import 'package:izithrift/features/orders/screens/my_purchases_screen.dart';
import 'package:izithrift/features/orders/screens/purchase_order_detail_screen.dart';
import 'package:izithrift/features/orders/screens/order_cancellation_dialog.dart';
import 'package:izithrift/features/orders/screens/shipment_tracking_screen.dart';
import 'package:izithrift/features/orders/screens/seller_orders_screen.dart';
import 'package:izithrift/features/orders/screens/seller_order_detail_screen.dart';
import 'package:izithrift/features/orders/screens/ship_order_form_modal.dart';
import 'package:izithrift/features/orders/screens/open_dispute_screen.dart';
import 'package:izithrift/features/orders/screens/dispute_detail_screen.dart';
import 'package:izithrift/features/orders/screens/submit_counter_evidence_screen.dart';

/// Mock Implementation of OrderFulfillmentRepository
class MockOrderFulfillmentRepository extends OrderFulfillmentRepository {
  MockOrderFulfillmentRepository()
    : super(
        dioClient: DioClient(
          tokenStorage: SecureTokenStorage(),
          serverTimeService: ServerTimeService.instance,
        ),
      );

  List<OrderModel> stubBuyerOrders = [];
  OrderModel? stubBuyerOrderDetail;
  List<OrderModel> stubSellerOrders = [];
  OrderModel? stubSellerOrderDetail;
  List<DisputeModel> stubDisputes = [];
  DisputeModel? stubDisputeDetail;

  bool cancelOrderCalled = false;
  bool withdrawCancelCalled = false;
  bool confirmDeliveryCalled = false;
  bool markOrderPreparingCalled = false;
  bool shipOrderCalled = false;
  bool markOrderDeliveredCalled = false;
  bool respondCancelCalled = false;
  bool openDisputeCalled = false;
  bool submitEvidenceCalled = false;

  @override
  Future<PaginatedResponse<OrderModel>> fetchMyPurchases({
    String? status,
    int page = 1,
    int perPage = 10,
  }) async {
    return PaginatedResponse<OrderModel>(
      items: stubBuyerOrders,
      meta: PaginationMeta(
        currentPage: page,
        perPage: perPage,
        total: stubBuyerOrders.length,
        lastPage: 1,
        hasMorePages: false,
      ),
    );
  }

  @override
  Future<OrderModel> fetchOrderDetail(int orderId) async {
    return stubSellerOrderDetail ??
        stubBuyerOrderDetail ??
        _createDummyOrder(
          id: orderId,
          orderStatus: 'DELIVERED',
          paymentStatus: 'PAID',
          escrowStatus: 'HELD',
          disputeStatus: 'NONE',
        );
  }

  @override
  Future<OrderModel> cancelOrder(int orderId, {required String reason}) async {
    cancelOrderCalled = true;
    return stubBuyerOrderDetail ??
        _createDummyOrder(
          id: orderId,
          orderStatus: 'CANCELLED',
          paymentStatus: 'REFUNDED',
          escrowStatus: 'REFUNDED',
          disputeStatus: 'NONE',
        );
  }

  @override
  Future<OrderModel> withdrawCancelRequest(int orderId) async {
    withdrawCancelCalled = true;
    return stubBuyerOrderDetail ??
        _createDummyOrder(
          id: orderId,
          orderStatus: 'PREPARING',
          paymentStatus: 'PAID',
          escrowStatus: 'HELD',
          disputeStatus: 'NONE',
          cancellationRequested: false,
        );
  }

  @override
  Future<OrderModel> confirmDeliveryAndReleaseEscrow(int orderId) async {
    confirmDeliveryCalled = true;
    return stubBuyerOrderDetail ??
        _createDummyOrder(
          id: orderId,
          orderStatus: 'COMPLETED',
          paymentStatus: 'PAID',
          escrowStatus: 'RELEASED',
          disputeStatus: 'NONE',
        );
  }

  @override
  Future<PaginatedResponse<OrderModel>> fetchSellerOrders({
    String? status,
    int page = 1,
    int perPage = 12,
  }) async {
    return PaginatedResponse<OrderModel>(
      items: stubSellerOrders,
      meta: PaginationMeta(
        currentPage: page,
        perPage: perPage,
        total: stubSellerOrders.length,
        lastPage: 1,
        hasMorePages: false,
      ),
    );
  }

  @override
  Future<OrderModel> markOrderPreparing(int orderId) async {
    markOrderPreparingCalled = true;
    return stubSellerOrderDetail ??
        _createDummyOrder(
          id: orderId,
          orderStatus: 'PREPARING',
          paymentStatus: 'PAID',
          escrowStatus: 'HELD',
          disputeStatus: 'NONE',
        );
  }

  @override
  Future<OrderModel> shipOrder(
    int orderId, {
    required String carrierName,
    required String trackingCode,
    String? shippingNote,
  }) async {
    shipOrderCalled = true;
    return stubSellerOrderDetail ??
        _createDummyOrder(
          id: orderId,
          orderStatus: 'SHIPPED',
          paymentStatus: 'PAID',
          escrowStatus: 'HELD',
          disputeStatus: 'NONE',
        );
  }

  @override
  Future<OrderModel> markOrderDelivered(int orderId) async {
    markOrderDeliveredCalled = true;
    return stubSellerOrderDetail ??
        _createDummyOrder(
          id: orderId,
          orderStatus: 'DELIVERED',
          paymentStatus: 'PAID',
          escrowStatus: 'HELD',
          disputeStatus: 'NONE',
        );
  }

  @override
  Future<OrderModel> respondToCancelRequest(
    int orderId, {
    required String action,
    String? reason,
  }) async {
    respondCancelCalled = true;
    return stubSellerOrderDetail ??
        _createDummyOrder(
          id: orderId,
          orderStatus: action == 'APPROVE' ? 'CANCELLED' : 'PREPARING',
          paymentStatus: action == 'APPROVE' ? 'REFUNDED' : 'PAID',
          escrowStatus: action == 'APPROVE' ? 'REFUNDED' : 'HELD',
          disputeStatus: 'NONE',
        );
  }

  @override
  Future<PaginatedResponse<DisputeModel>> fetchDisputes({
    int page = 1,
    int perPage = 10,
  }) async {
    return PaginatedResponse<DisputeModel>(
      items: stubDisputes,
      meta: PaginationMeta(
        currentPage: page,
        perPage: perPage,
        total: stubDisputes.length,
        lastPage: 1,
        hasMorePages: false,
      ),
    );
  }

  @override
  Future<DisputeModel> fetchDisputeDetail(int disputeId) async {
    return stubDisputeDetail ??
        DisputeModel(
          id: disputeId,
          disputeCode: 'DSP-20261115-$disputeId',
          orderId: 100,
          orderCode: 'ORD-20261115-100',
          buyerId: 1,
          sellerId: 2,
          reasonCategory: 'ITEM_NOT_AS_DESCRIBED',
          description:
              'Sản phẩm áo len bị rách vai 5cm không giống như mô tả ban đầu.',
          status: 'OPEN',
          escrowFrozenAmount: 350000.0,
          refundAmount: 0.0,
          evidences: [
            DisputeEvidenceModel(
              id: 1,
              disputeId: disputeId,
              uploaderId: 1,
              uploaderRole: 'BUYER',
              uploaderName: 'Người mua Đỗ Đức',
              evidenceType: 'BUYER_PROOF',
              messageNote: 'Hình ảnh chi tiết vết rách ở nách áo len',
              attachmentUrls: ['https://example.com/photo1.jpg'],
              createdAt: DateTime.now().subtract(const Duration(hours: 5)),
            ),
          ],
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        );
  }

  @override
  Future<DisputeModel> openDispute(
    int orderId, {
    required String reasonCategory,
    required String description,
    List<String> attachmentUrls = const [],
  }) async {
    openDisputeCalled = true;
    return DisputeModel(
      id: 99,
      disputeCode: 'DSP-20261115-99',
      orderId: orderId,
      orderCode: 'ORD-20261115-$orderId',
      buyerId: 1,
      sellerId: 2,
      reasonCategory: reasonCategory,
      description: description,
      status: 'OPEN',
      escrowFrozenAmount: 350000.0,
      refundAmount: 0.0,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<DisputeEvidenceModel> submitDisputeEvidence(
    int disputeId, {
    required String messageNote,
    String? evidenceType,
    List<String> attachmentUrls = const [],
  }) async {
    submitEvidenceCalled = true;
    return DisputeEvidenceModel(
      id: 88,
      disputeId: disputeId,
      uploaderId: 2,
      uploaderRole: 'SELLER',
      uploaderName: 'Chủ tiệm bán',
      evidenceType: evidenceType ?? 'SELLER_COUNTER_PROOF',
      messageNote: messageNote,
      attachmentUrls: attachmentUrls,
      createdAt: DateTime.now(),
    );
  }
}

OrderModel _createDummyOrder({
  required int id,
  required String orderStatus,
  required String paymentStatus,
  required String escrowStatus,
  required String disputeStatus,
  bool cancellationRequested = false,
  String? cancellationRequestReason,
}) {
  return OrderModel(
    id: id,
    orderCode: 'ORD-20261115-$id',
    buyerId: 1,
    buyerName: 'Người mua Đỗ Đức',
    sellerId: 2,
    shopName: 'Tiệm Đồ Cũ Sài Gòn',
    sellerAvatarUrl: 'https://example.com/seller.jpg',
    trustScore: 4.8,
    recipientName: 'Đỗ Minh Đức',
    recipientPhone: '0988776655',
    fullAddress: '123 Đường Xô Viết Nghệ Tĩnh, P.25, Q.Bình Thạnh, TP.HCM',
    shippingAddressSnapshot: const {
      'recipient_name': 'Đỗ Minh Đức',
      'recipient_phone': '0988776655',
      'full_address': '123 Đường Xô Viết Nghệ Tĩnh, P.25, Q.Bình Thạnh, TP.HCM',
    },
    orderStatus: orderStatus,
    paymentStatus: paymentStatus,
    escrowStatus: escrowStatus,
    disputeStatus: disputeStatus,
    itemSubtotal: 350000.0,
    shippingFee: 30000.0,
    buyerProtectionFee: 15000.0,
    totalAmount: 395000.0,
    sellerNetPayout: 350000.0,
    cancellationRequested: cancellationRequested,
    cancellationRequestReason: cancellationRequestReason,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    autoCompleteAt: DateTime.now().add(const Duration(days: 2)),
    shipment: ShipmentModel(
      id: 10,
      orderId: id,
      carrierName: 'Giao Hàng Tiết Kiệm (GHTK)',
      trackingCode: 'GHTK-VNT-889922',
      status: 'SHIPPED',
      timelineEvents: [
        ShipmentTimelineEventModel(
          title: 'Người bán chuẩn bị hàng',
          description: 'Tiệm đã đóng gói kiện hàng cẩn thận',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          isCompleted: true,
        ),
        ShipmentTimelineEventModel(
          title: 'Đang vận chuyển',
          description: 'Kiện hàng đã rời kho trung chuyển',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isCompleted: true,
        ),
      ],
    ),
    items: const [
      OrderItemSnapshotModel(
        id: 1,
        productId: 101,
        productCode: 'PRD-101',
        productTitle: 'Áo Len Vintage Họa Tiết Bắc Âu',
        condition: 'EXCELLENT',
        primaryImageUrl: 'https://example.com/sweater.jpg',
        unitPrice: 350000.0,
        quantity: 1,
        subtotal: 350000.0,
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockOrderFulfillmentRepository mockRepo;

  setUp(() {
    mockRepo = MockOrderFulfillmentRepository();
  });

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        orderFulfillmentRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('P7-09: Models SafeJsonParser Tests', () {
    test(
      'OrderItemSnapshotModel correctly parses json with fallback values',
      () {
        final json = {
          'id': 1,
          'product_id': 101,
          'product_code': 'PRD-101',
          'title': 'Khăn Len Cổ Điển',
          'condition': 'GOOD',
          'unit_price': '150000.00',
          'quantity': 1,
          'item_subtotal': '150000.00',
          'primary_image_url': 'https://example.com/scarf.jpg',
        };

        final item = OrderItemSnapshotModel.fromJson(json);
        expect(item.id, 1);
        expect(item.productId, 101);
        expect(item.productTitle, 'Khăn Len Cổ Điển');
        expect(item.condition, 'GOOD');
        expect(item.unitPrice, 150000.0);
        expect(item.subtotal, 150000.0);
        expect(item.primaryImageUrl, 'https://example.com/scarf.jpg');
      },
    );

    test('OrderModel correctly parses 4 independent state machines and monetary fields', () {
      final json = {
        'id': 202,
        'order_code': 'ORD-20261115-202',
        'buyer_id': 10,
        'buyer_name': 'Nguyễn Văn A',
        'seller_id': 20,
        'seller_shop_name': 'Tiệm Cũ Kỹ',
        'order_status': 'PREPARING',
        'payment_status': 'PAID',
        'escrow_status': 'HELD',
        'dispute_status': 'NONE',
        'item_subtotal': '500000',
        'shipping_fee': '30000',
        'protection_fee': '15000',
        'total_amount': '545000',
        'payment_method': 'ESCROW_WALLET',
        'cancellation_requested': true,
        'cancellation_request_reason': 'Thay đổi ý định mua hàng',
        'recipient_name': 'Nguyễn Văn A',
        'recipient_phone': '0912345678',
        'full_address': 'Số 1 Đại Cồ Việt, Hai Bà Trưng, Hà Nội',
        'items': [
          {
            'id': 1,
            'product_id': 50,
            'title': 'Máy ảnh cơ Pentax K1000',
            'condition': 'FAIR',
            'unit_price': 500000,
            'quantity': 1,
            'item_subtotal': 500000,
          },
        ],
      };

      final order = OrderModel.fromJson(json);
      expect(order.id, 202);
      expect(order.orderStatus, 'PREPARING');
      expect(order.paymentStatus, 'PAID');
      expect(order.escrowStatus, 'HELD');
      expect(order.disputeStatus, 'NONE');
      expect(order.cancellationRequested, isTrue);
      expect(order.cancellationRequestReason, 'Thay đổi ý định mua hàng');
      expect(order.itemSubtotal, 500000.0);
      expect(order.shippingFee, 30000.0);
      expect(order.buyerProtectionFee, 15000.0);
      expect(order.totalAmount, 545000.0);
      expect(order.items.length, 1);
      expect(order.items.first.productTitle, 'Máy ảnh cơ Pentax K1000');
    });

    test('OrderModel.fromJson resolves paymentId priority (latest_payment > payment_id > current_payment_id)', () {
      final caseA = OrderModel.fromJson({'id': 501, 'current_payment_id': 901});
      expect(caseA.paymentId, 901);

      final caseB = OrderModel.fromJson({
        'id': 501,
        'payment_id': 902,
        'current_payment_id': 901,
      });
      expect(caseB.paymentId, 902);

      final caseC = OrderModel.fromJson({
        'id': 501,
        'latest_payment': {'id': 903},
        'payment_id': 902,
        'current_payment_id': 901,
      });
      expect(caseC.paymentId, 903);
    });

    test('ShipmentModel and Timeline Events parse correctly', () {
      final json = {
        'id': 55,
        'order_id': 202,
        'carrier_name': 'Viettel Post',
        'tracking_code': 'VT-998877',
        'status': 'SHIPPED',
        'shipped_at': '2026-11-14T10:00:00Z',
        'timeline_events': [
          {
            'title': 'Bưu cục đã tiếp nhận',
            'description': 'Đang chuyển về kho phát',
            'timestamp': '2026-11-14T10:30:00Z',
            'is_completed': true,
          },
        ],
      };

      final shipment = ShipmentModel.fromJson(json);
      expect(shipment.carrierName, 'Viettel Post');
      expect(shipment.trackingCode, 'VT-998877');
      expect(shipment.timelineEvents.length, 1);
      expect(shipment.timelineEvents.first.title, 'Bưu cục đã tiếp nhận');
    });

    test('DisputeModel and DisputeEvidenceModel parse correctly with multi-role support', () {
      final json = {
        'id': 77,
        'dispute_code': 'DSP-20261115-77',
        'order_id': 202,
        'order_code': 'ORD-20261115-202',
        'buyer_id': 10,
        'seller_id': 20,
        'reason_category': 'DEFECTIVE_NOT_REPORTED',
        'description': 'Máy ảnh bị kẹt màn trập không chụp được.',
        'status': 'NEED_MORE_INFO',
        'escrow_frozen_amount': 500000.0,
        'refund_amount': 250000.0,
        'admin_verdict': 'PARTIAL_REFUND',
        'admin_resolution_note':
            'Hai bên thống nhất hỗ trợ tiền sửa chữa màn trập.',
        'evidences': [
          {
            'id': 101,
            'dispute_id': 77,
            'uploader_id': 10,
            'uploader_name': 'Nguyễn Văn A',
            'uploader_role': 'BUYER',
            'evidence_type': 'BUYER_PROOF',
            'message_note': 'Video mở hộp và bấm thử cò máy ảnh',
            'attachments': ['https://example.com/video1.mp4'],
          },
          {
            'id': 102,
            'dispute_id': 77,
            'uploader_id': 20,
            'uploader_name': 'Tiệm Cũ Kỹ',
            'uploader_role': 'SELLER',
            'evidence_type': 'SELLER_COUNTER_PROOF',
            'message_note': 'Video test máy trước khi bọc bóng khí gửi đi',
            'attachments': ['https://example.com/video2.mp4'],
          },
        ],
      };

      final dispute = DisputeModel.fromJson(json);
      expect(dispute.id, 77);
      expect(dispute.reasonCategory, 'DEFECTIVE_NOT_REPORTED');
      expect(dispute.status, 'NEED_MORE_INFO');
      expect(dispute.adminVerdict, 'PARTIAL_REFUND');
      expect(dispute.evidences.length, 2);
      expect(dispute.evidences.first.isBuyerProof, isTrue);
      expect(dispute.evidences.last.isSellerCounterProof, isTrue);
    });
  });

  group('P7-09: Buyer Orders & Detail Widgets Tests (M-OR-02, M-OR-03, M-OR-04)', () {
    testWidgets(
      'MyPurchasesScreen displays 9 status tabs and lists purchases correctly',
      (tester) async {
        mockRepo.stubBuyerOrders = [
          _createDummyOrder(
            id: 101,
            orderStatus: 'PENDING_PAYMENT',
            paymentStatus: 'PENDING',
            escrowStatus: 'PENDING',
            disputeStatus: 'NONE',
          ),
        ];

        await tester.pumpWidget(createTestWidget(const MyPurchasesScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Đơn mua của tôi'), findsOneWidget);
        expect(find.byType(TabBar), findsOneWidget);
        expect(find.text('Tất cả'), findsOneWidget);
        expect(find.widgetWithText(Tab, 'Chờ thanh toán'), findsOneWidget);
        expect(find.text('Tiệm Đồ Cũ Sài Gòn'), findsOneWidget);
        expect(find.text('Áo Len Vintage Họa Tiết Bắc Âu'), findsOneWidget);
        expect(find.text('Hủy'), findsOneWidget);
        expect(find.text('Thanh toán'), findsOneWidget);
      },
    );

    testWidgets(
      'PurchaseOrderDetailScreen displays 4 state machines and PriceBreakdownCard',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final dummyOrder = _createDummyOrder(
          id: 101,
          orderStatus: 'DELIVERED',
          paymentStatus: 'PAID',
          escrowStatus: 'HELD',
          disputeStatus: 'NONE',
        );
        mockRepo.stubBuyerOrderDetail = dummyOrder;

        await tester.pumpWidget(
          createTestWidget(
            PurchaseOrderDetailScreen(orderId: 101, initialOrder: dummyOrder),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Đơn hàng ORD-20261115-101'), findsOneWidget);
        expect(find.text('Trạng thái đơn hàng'), findsOneWidget);
        expect(find.text('Trạng thái thanh toán'), findsOneWidget);
        expect(find.text('Quỹ ký quỹ Escrow'), findsOneWidget);
        expect(find.text('Trạng thái khiếu nại'), findsOneWidget);
        expect(find.byType(PriceBreakdownCard), findsOneWidget);
        expect(find.text('Đã nhận được hàng & Hài lòng'), findsOneWidget);
        expect(find.text('Khiếu nại / Trả hàng'), findsOneWidget);
      },
    );

    testWidgets('OrderCancellationDialog 3-Tier logic operates properly', (
      tester,
    ) async {
      String? cancelledReason;
      final dummyOrder = _createDummyOrder(
        id: 101,
        orderStatus: 'PENDING_PAYMENT',
        paymentStatus: 'PENDING',
        escrowStatus: 'PENDING',
        disputeStatus: 'NONE',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: ctx,
                    builder: (dCtx) => OrderCancellationDialog(
                      order: dummyOrder,
                      onConfirmCancel: (reason) async {
                        cancelledReason = reason;
                      },
                    ),
                  );
                },
                child: const Text('Mở Modal Hủy'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở Modal Hủy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Hủy đơn chưa thanh toán'), findsOneWidget);
      expect(find.text('Đổi ý, không muốn mua nữa'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_confirm_cancel_order')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cancelledReason, 'Đổi ý, không muốn mua nữa');
    });

    testWidgets(
      'Escrow Release (DEC-04) triggers confirm delivery dialog on M-OR-03',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final dummyOrder = _createDummyOrder(
          id: 101,
          orderStatus: 'DELIVERED',
          paymentStatus: 'PAID',
          escrowStatus: 'HELD',
          disputeStatus: 'NONE',
        );
        mockRepo.stubBuyerOrderDetail = dummyOrder;

        await tester.pumpWidget(
          createTestWidget(
            PurchaseOrderDetailScreen(orderId: 101, initialOrder: dummyOrder),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final releaseBtn = find.byKey(
          const Key('btn_confirm_delivery_release_escrow'),
        );
        expect(releaseBtn, findsOneWidget);

        await tester.tap(releaseBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.text('Xác nhận nhận hàng & Giải ngân Escrow?'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('btn_confirm_release_dialog')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(mockRepo.confirmDeliveryCalled, isTrue);
      },
    );
  });

  group('P7-09: Seller Fulfillment & Decision Card Tests (M-SL-05, M-SL-06, M-SL-07)', () {
    testWidgets('SellerOrdersScreen renders tabs and lists seller orders', (
      tester,
    ) async {
      mockRepo.stubSellerOrders = [
        _createDummyOrder(
          id: 301,
          orderStatus: 'PAID',
          paymentStatus: 'PAID',
          escrowStatus: 'HELD',
          disputeStatus: 'NONE',
        ),
      ];

      await tester.pumpWidget(createTestWidget(const SellerOrdersScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Quản lý đơn bán của Tiệm'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Chờ chuẩn bị'), findsOneWidget);
      expect(find.textContaining('Người mua Đỗ Đức'), findsOneWidget);
      expect(find.text('Chuẩn bị hàng'), findsOneWidget);
    });

    testWidgets(
      'SellerOrderDetailScreen displays urgent cancellation decision card when buyer requested cancel',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final dummyOrder = _createDummyOrder(
          id: 301,
          orderStatus: 'PREPARING',
          paymentStatus: 'PAID',
          escrowStatus: 'HELD',
          disputeStatus: 'NONE',
          cancellationRequested: true,
          cancellationRequestReason: 'Tìm thấy sản phẩm khác rẻ hơn',
        );
        mockRepo.stubSellerOrderDetail = dummyOrder;

        await tester.pumpWidget(
          createTestWidget(
            SellerOrderDetailScreen(orderId: 301, initialOrder: dummyOrder),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.text('Khách mua gửi yêu cầu xin hủy đơn (DEC-06)'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Tìm thấy sản phẩm khác rẻ hơn'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('btn_seller_approve_cancel')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('btn_seller_reject_cancel')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('btn_seller_approve_cancel')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Đồng ý hủy đơn & Hoàn tiền?'), findsOneWidget);
        await tester.tap(find.text('Đồng ý hủy'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(mockRepo.respondCancelCalled, isTrue);
      },
    );

    testWidgets('ShipOrderFormModal validates carrier and tracking code', (
      tester,
    ) async {
      String? shippedCarrier;
      String? shippedTracking;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: ctx,
                    isScrollControlled: true,
                    builder: (bCtx) => ShipOrderFormModal(
                      orderId: 301,
                      orderCode: 'ORD-301',
                      onConfirmShip:
                          ({
                            required carrierName,
                            required trackingCode,
                            shippingNote,
                          }) async {
                            shippedCarrier = carrierName;
                            shippedTracking = trackingCode;
                          },
                    ),
                  );
                },
                child: const Text('Mở Modal Giao Hàng'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở Modal Giao Hàng'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Giao hàng cho vận chuyển'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('input_tracking_code')),
        'GHTK-HCM-112233',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('btn_submit_ship_order')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(shippedCarrier, isNotEmpty);
      expect(shippedTracking, 'GHTK-HCM-112233');
    });

    testWidgets(
      'ShipmentTrackingScreen displays carrier, tracking code, and timeline steps',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final dummyOrder = _createDummyOrder(
          id: 101,
          orderStatus: 'SHIPPED',
          paymentStatus: 'PAID',
          escrowStatus: 'HELD',
          disputeStatus: 'NONE',
        );
        mockRepo.stubBuyerOrderDetail = dummyOrder;

        await tester.pumpWidget(
          createTestWidget(
            ShipmentTrackingScreen(orderId: 101, initialOrder: dummyOrder),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Vận đơn ORD-20261115-101'), findsOneWidget);
        expect(find.text('Giao Hàng Tiết Kiệm (GHTK)'), findsOneWidget);
        expect(find.text('Mã vận đơn: GHTK-VNT-889922'), findsOneWidget);
        expect(find.text('Tiệm đang chuẩn bị hàng'), findsOneWidget);
        expect(find.textContaining('Đã giao cho vận chuyển'), findsOneWidget);
      },
    );
  });

  group('P7-09: Dispute Resolution Tests (M-DP-01, M-DP-02, M-DP-03)', () {
    testWidgets(
      'OpenDisputeScreen validates description >= 10 chars and handles submission',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(const OpenDisputeScreen(orderId: 101)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Mở khiếu nại / Trả hàng'), findsOneWidget);
        expect(
          find.text('Hàng không đúng mô tả / Khuyết điểm ẩn'),
          findsOneWidget,
        );

        // Try submitting without description -> validation fails
        await tester.ensureVisible(find.byKey(const Key('btn_submit_dispute')));
        await tester.tap(find.byKey(const Key('btn_submit_dispute')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.text(
            'Vui lòng mô tả chi tiết lý do khiếu nại (tối thiểu 10 ký tự).',
          ),
          findsOneWidget,
        );

        // Fill description >= 10 chars
        await tester.enterText(
          find.byKey(const Key('input_dispute_description')),
          'Chiếc áo len bị rách ở nách trái và có vết bẩn lớn ở vạt áo.',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.ensureVisible(find.byKey(const Key('btn_submit_dispute')));
        await tester.tap(find.byKey(const Key('btn_submit_dispute')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(mockRepo.openDisputeCalled, isTrue);
      },
    );

    testWidgets(
      'DisputeDetailScreen renders status banner, claims, and counter-evidence history',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final dummyDispute = DisputeModel(
          id: 99,
          disputeCode: 'DSP-20261115-99',
          orderId: 100,
          orderCode: 'ORD-20261115-100',
          buyerId: 1,
          sellerId: 2,
          reasonCategory: 'ITEM_NOT_AS_DESCRIBED',
          description:
              'Sản phẩm áo len bị rách vai 5cm không giống như mô tả ban đầu.',
          status: 'OPEN',
          escrowFrozenAmount: 350000.0,
          refundAmount: 0.0,
          evidences: [
            DisputeEvidenceModel(
              id: 1,
              disputeId: 99,
              uploaderId: 1,
              uploaderRole: 'BUYER',
              uploaderName: 'Người mua Đỗ Đức',
              evidenceType: 'BUYER_PROOF',
              messageNote: 'Hình ảnh chi tiết vết rách ở nách áo len',
              attachmentUrls: const ['https://example.com/photo1.jpg'],
              createdAt: DateTime.now().subtract(const Duration(hours: 5)),
            ),
          ],
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        );
        mockRepo.stubDisputeDetail = dummyDispute;

        await tester.pumpWidget(
          createTestWidget(
            DisputeDetailScreen(disputeId: 99, initialDispute: dummyDispute),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Hồ sơ khiếu nại DSP-20261115-99'), findsOneWidget);
        expect(find.text('Mã khiếu nại: DSP-20261115-99'), findsOneWidget);
        expect(
          find.text('Tiền ký quỹ đang đóng băng (FROZEN):'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Sản phẩm áo len bị rách vai 5cm'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('btn_submit_counter_evidence')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'SubmitCounterEvidenceScreen validates and calls submitEvidence',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(const SubmitCounterEvidenceScreen(disputeId: 99)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Nộp chứng cứ & Giải trình'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('input_counter_evidence_note')),
          'Tiệm cam kết đã kiểm tra kỹ trước khi bọc túi bóng khí niêm phong.',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(
          find.byKey(const Key('btn_confirm_submit_counter_evidence')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(mockRepo.submitEvidenceCalled, isTrue);
      },
    );
  });
}
