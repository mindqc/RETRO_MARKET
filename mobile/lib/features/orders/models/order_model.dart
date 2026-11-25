import '../../../core/utils/safe_json_parser.dart';
import 'order_item_snapshot_model.dart';
import 'shipment_model.dart';

/// Full Order domain model managing 4 independent state machines, financial equation (DEC-04),
/// immutable product snapshots, and 3-tier cancellation (DEC-06 / M-OR-02..05 / M-SL-05..07).
class OrderModel {
  final int id;
  final String orderCode;
  final int buyerId;
  final String buyerName;
  final int sellerId;
  final String shopName;
  final String? shopSlug;
  final String? sellerAvatarUrl;
  final double trustScore;

  // Shipping address snapshot
  final String recipientName;
  final String recipientPhone;
  final String fullAddress;
  final Map<String, dynamic> shippingAddressSnapshot;

  // 4 Independent State Machines
  final String orderStatus; // PENDING_PAYMENT, PAID, PREPARING, SHIPPED, DELIVERED, COMPLETED, CANCELLED
  final String paymentStatus; // PENDING, PAID, REFUNDED
  final String escrowStatus; // PENDING, HELD / ESCROW_HELD, FROZEN / DISPUTE_FROZEN, RELEASED, REFUNDED
  final String disputeStatus; // NONE, OPEN, NEED_MORE_INFO, RESOLVED

  // Transparent Financial Equation (DEC-04)
  final double itemSubtotal;
  final double shippingFee;
  final double buyerProtectionFee;
  final double totalAmount;
  final double sellerNetPayout; // 100% itemSubtotal

  // Cancellation & Workflow Controls (DEC-06 / DEC-07)
  final bool cancellationRequested;
  final String? cancellationRequestReason;
  final String? cancelledByRole;
  final String? cancelReason;
  final String? sellerCancelRejectReason;

  // Timestamps
  final DateTime? paymentExpiresAt;
  final DateTime? paidAt;
  final DateTime? preparingAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? autoCompleteAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;

  // Auxiliary IDs & Flags
  final int? paymentId;
  final int? activeDisputeId;
  final bool canReview;

  // Relational Collections
  final List<OrderItemSnapshotModel> items;
  final ShipmentModel? shipment;

  const OrderModel({
    required this.id,
    required this.orderCode,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.shopName,
    this.shopSlug,
    this.sellerAvatarUrl,
    this.trustScore = 100.0,
    required this.recipientName,
    required this.recipientPhone,
    required this.fullAddress,
    this.shippingAddressSnapshot = const {},
    required this.orderStatus,
    required this.paymentStatus,
    required this.escrowStatus,
    required this.disputeStatus,
    required this.itemSubtotal,
    this.shippingFee = 0.0,
    required this.buyerProtectionFee,
    required this.totalAmount,
    required this.sellerNetPayout,
    this.cancellationRequested = false,
    this.cancellationRequestReason,
    this.cancelledByRole,
    this.cancelReason,
    this.sellerCancelRejectReason,
    this.paymentExpiresAt,
    this.paidAt,
    this.preparingAt,
    this.shippedAt,
    this.deliveredAt,
    this.autoCompleteAt,
    this.completedAt,
    this.cancelledAt,
    this.createdAt,
    this.paymentId,
    this.activeDisputeId,
    this.canReview = false,
    this.items = const [],
    this.shipment,
  });

  // State Convenience Getters
  bool get isPendingPayment => orderStatus == 'PENDING_PAYMENT';
  bool get isPaid => orderStatus == 'PAID';
  bool get isPreparing => orderStatus == 'PREPARING';
  bool get isShipped => orderStatus == 'SHIPPED';
  bool get isDelivered => orderStatus == 'DELIVERED';
  bool get isCompleted => orderStatus == 'COMPLETED';
  bool get isCancelled => orderStatus == 'CANCELLED';
  bool get isDisputed => disputeStatus != 'NONE' && disputeStatus != 'RESOLVED';

  // Escrow State Getters
  bool get isEscrowHeld =>
      escrowStatus == 'HELD' || escrowStatus == 'ESCROW_HELD';
  bool get isEscrowFrozen =>
      escrowStatus == 'FROZEN' || escrowStatus == 'DISPUTE_FROZEN';
  bool get isEscrowReleased => escrowStatus == 'RELEASED';
  bool get isEscrowRefunded => escrowStatus == 'REFUNDED';

  // 3-Tier Cancellation Capabilities (DEC-06)
  bool get canBuyerCancelImmediately => isPendingPayment || isPaid;
  bool get canBuyerRequestCancel => isPreparing && !cancellationRequested;
  bool get canBuyerWithdrawCancel => isPreparing && cancellationRequested;
  bool get canSellerRespondCancel => isPreparing && cancellationRequested;

  // Completion & Dispute Capabilities
  bool get canBuyerConfirmDelivery => (isShipped || isDelivered) && !isDisputed;
  bool get canBuyerOpenDispute =>
      (isShipped || isDelivered) &&
      (disputeStatus == 'NONE' || disputeStatus.isEmpty);

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // 1. Seller & Buyer Parsing
    int sId = 0;
    String sName = 'Tiệm Đồ Si';
    String? sSlug;
    String? sAvatar;
    double tScore = 100.0;

    if (json['seller'] is Map<String, dynamic>) {
      final s = json['seller'] as Map<String, dynamic>;
      sId = SafeJsonParser.toInt(s['id'] ?? s['seller_id']);
      sName = SafeJsonParser.toStringValue(
        s['display_name'] ?? s['shop_name'] ?? s['name'],
        defaultValue: 'Tiệm Đồ Si',
      );
      sSlug = SafeJsonParser.toNullableString(s['shop_slug']);
      sAvatar = SafeJsonParser.toNullableString(s['avatar_url']);
      tScore = SafeJsonParser.toDouble(s['trust_score'], defaultValue: 100.0);
    } else {
      sId = SafeJsonParser.toInt(json['seller_id']);
      sName = SafeJsonParser.toStringValue(
        json['shop_name'],
        defaultValue: 'Tiệm Đồ Si',
      );
      sSlug = SafeJsonParser.toNullableString(json['shop_slug']);
    }

    int bId = 0;
    String bName = 'Người mua';
    if (json['buyer'] is Map<String, dynamic>) {
      final b = json['buyer'] as Map<String, dynamic>;
      bId = SafeJsonParser.toInt(b['id'] ?? b['buyer_id']);
      bName = SafeJsonParser.toStringValue(
        b['display_name'] ?? b['name'],
        defaultValue: 'Người mua',
      );
    } else {
      bId = SafeJsonParser.toInt(json['buyer_id']);
      bName = SafeJsonParser.toStringValue(
        json['buyer_name'],
        defaultValue: 'Người mua',
      );
    }

    // 2. Shipping Address Snapshot
    Map<String, dynamic> addrMap = {};
    if (json['shipping_address_snapshot'] is Map<String, dynamic>) {
      addrMap = json['shipping_address_snapshot'] as Map<String, dynamic>;
    } else if (json['shipping_address'] is Map<String, dynamic>) {
      addrMap = json['shipping_address'] as Map<String, dynamic>;
    }

    final String recipient = SafeJsonParser.toStringValue(
      addrMap['recipient_name'] ?? addrMap['name'] ?? json['recipient_name'],
      defaultValue: bName,
    );
    final String phone = SafeJsonParser.toStringValue(
      addrMap['recipient_phone'] ?? addrMap['phone'] ?? json['recipient_phone'],
      defaultValue: '',
    );
    final String address = SafeJsonParser.toStringValue(
      addrMap['full_address'] ??
          addrMap['street_address'] ??
          json['shipping_address_text'] ??
          'Địa chỉ nhận hàng',
      defaultValue: 'Địa chỉ nhận hàng',
    );

    // 3. 4 Independent State Machines
    final String oStatus = SafeJsonParser.toStringValue(
      json['order_status'] ?? json['status'],
      defaultValue: 'PENDING_PAYMENT',
    ).toUpperCase();

    final String pStatus = SafeJsonParser.toStringValue(
      json['payment_status'],
      defaultValue: 'PENDING',
    ).toUpperCase();

    final String eStatus = SafeJsonParser.toStringValue(
      json['escrow_status'],
      defaultValue: (oStatus == 'PAID' || pStatus == 'PAID')
          ? 'HELD'
          : 'PENDING',
    ).toUpperCase();

    final String dStatus = SafeJsonParser.toStringValue(
      json['dispute_status'],
      defaultValue: 'NONE',
    ).toUpperCase();

    // 4. Financials (DEC-04)
    final double subtotal = SafeJsonParser.toDouble(json['item_subtotal']);
    final double ship = SafeJsonParser.toDouble(
      json['shipping_fee'],
      defaultValue: 0.0,
    );
    final double protectFee = SafeJsonParser.toDouble(
      json['buyer_protection_fee'] ?? json['protection_fee'],
      defaultValue: (subtotal * 0.06) + 7000.0,
    );
    final double grandTotal = SafeJsonParser.toDouble(
      json['total_amount'],
      defaultValue: subtotal + ship + protectFee,
    );
    final double netPayout = SafeJsonParser.toDouble(
      json['seller_net_amount'] ?? json['seller_net_payout'],
      defaultValue: subtotal, // 100% net item subtotal
    );

    // 5. Items Snapshot
    final rawItems = json['items'];
    final List<OrderItemSnapshotModel> itemsList = [];
    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map<String, dynamic>) {
          itemsList.add(OrderItemSnapshotModel.fromJson(it));
        }
      }
    }

    // 6. Shipment Model
    ShipmentModel? shipmentObj;
    if (json['shipment'] is Map<String, dynamic>) {
      shipmentObj = ShipmentModel.fromJson(
        json['shipment'] as Map<String, dynamic>,
      );
    } else if (json['tracking_code'] != null || json['carrier_name'] != null) {
      shipmentObj = ShipmentModel(
        id: SafeJsonParser.toInt(json['shipment_id']),
        orderId: SafeJsonParser.toInt(json['id']),
        carrierName: SafeJsonParser.toStringValue(
          json['carrier_name'],
          defaultValue: 'Đang vận chuyển',
        ),
        trackingCode: SafeJsonParser.toStringValue(
          json['tracking_code'],
          defaultValue: 'CHƯA CẬP NHẬT',
        ),
        status: oStatus == 'DELIVERED'
            ? 'DELIVERED'
            : (oStatus == 'SHIPPED' ? 'SHIPPED' : 'PENDING'),
        shippedAt: SafeJsonParser.toNullableDateTime(json['shipped_at']),
        deliveredAt: SafeJsonParser.toNullableDateTime(json['delivered_at']),
      );
    }

    // 7. Payment ID resolution
    int? pId;
    if (json['latest_payment'] is Map<String, dynamic>) {
      pId = SafeJsonParser.toNullableInt(json['latest_payment']['id']);
    } else if (json['payments'] is List &&
        (json['payments'] as List).isNotEmpty) {
      final lastP = (json['payments'] as List).last;
      if (lastP is Map<String, dynamic>) {
        pId = SafeJsonParser.toNullableInt(lastP['id']);
      }
    }
    pId ??= SafeJsonParser.toNullableInt(
      json['payment_id'] ?? json['current_payment_id'],
    );

    return OrderModel(
      id: SafeJsonParser.toInt(json['id']),
      orderCode: SafeJsonParser.toStringValue(
        json['order_code'],
        defaultValue: 'ORD-${json['id']}',
      ),
      buyerId: bId,
      buyerName: bName,
      sellerId: sId,
      shopName: sName,
      shopSlug: sSlug,
      sellerAvatarUrl: sAvatar,
      trustScore: tScore,
      recipientName: recipient,
      recipientPhone: phone,
      fullAddress: address,
      shippingAddressSnapshot: addrMap,
      orderStatus: oStatus,
      paymentStatus: pStatus,
      escrowStatus: eStatus,
      disputeStatus: dStatus,
      itemSubtotal: subtotal,
      shippingFee: ship,
      buyerProtectionFee: protectFee,
      totalAmount: grandTotal,
      sellerNetPayout: netPayout,
      cancellationRequested: SafeJsonParser.toBool(
        json['cancellation_requested'],
        defaultValue: false,
      ),
      cancellationRequestReason: SafeJsonParser.toNullableString(
        json['cancellation_request_reason'],
      ),
      cancelledByRole: SafeJsonParser.toNullableString(
        json['cancelled_by_role'],
      ),
      cancelReason: SafeJsonParser.toNullableString(json['cancel_reason']),
      sellerCancelRejectReason: SafeJsonParser.toNullableString(
        json['seller_cancel_reject_reason'],
      ),
      paymentExpiresAt: SafeJsonParser.toNullableDateTime(
        json['payment_expires_at'],
      ),
      paidAt: SafeJsonParser.toNullableDateTime(json['paid_at']),
      preparingAt: SafeJsonParser.toNullableDateTime(json['preparing_at']),
      shippedAt: SafeJsonParser.toNullableDateTime(json['shipped_at']),
      deliveredAt: SafeJsonParser.toNullableDateTime(json['delivered_at']),
      autoCompleteAt: SafeJsonParser.toNullableDateTime(
        json['auto_complete_at'],
      ),
      completedAt: SafeJsonParser.toNullableDateTime(json['completed_at']),
      cancelledAt: SafeJsonParser.toNullableDateTime(json['cancelled_at']),
      createdAt: SafeJsonParser.toNullableDateTime(json['created_at']),
      paymentId: pId,
      activeDisputeId: SafeJsonParser.toNullableInt(
        json['active_dispute_id'] ?? json['dispute_id'],
      ),
      canReview: SafeJsonParser.toBool(
        json['can_review'],
        defaultValue: oStatus == 'COMPLETED',
      ),
      items: itemsList,
      shipment: shipmentObj,
    );
  }

  /// Dynamically builds ordered lifecycle timeline events for M-OR-05
  List<ShipmentTimelineEventModel> buildFullLifecycleTimeline() {
    final List<ShipmentTimelineEventModel> events = [];

    // 1. Order Placed
    events.add(
      ShipmentTimelineEventModel(
        title: 'Đặt hàng thành công',
        description: 'Đơn hàng $orderCode đã được khởi tạo thành công.',
        timestamp: createdAt,
        isCompleted: true,
      ),
    );

    // 2. Escrow Payment Held
    final bool isPaidStep =
        paidAt != null ||
        isPaid ||
        isPreparing ||
        isShipped ||
        isDelivered ||
        isCompleted;
    events.add(
      ShipmentTimelineEventModel(
        title: 'Thanh toán & Giữ tiền Escrow',
        description: isPaidStep
            ? 'Tiền đã được giữ an toàn trong quỹ Escrow của izithrift.'
            : 'Chờ người mua hoàn tất thanh toán chuyển khoản QR.',
        timestamp: paidAt,
        isCompleted: isPaidStep,
      ),
    );

    // 3. Seller Preparing
    final bool isPrepStep =
        preparingAt != null ||
        isPreparing ||
        isShipped ||
        isDelivered ||
        isCompleted;
    events.add(
      ShipmentTimelineEventModel(
        title: 'Tiệm đang chuẩn bị hàng',
        description: isPrepStep
            ? 'Chủ tiệm $shopName đang đóng gói sản phẩm cẩn thận.'
            : 'Chờ tiệm tiếp nhận và đóng gói.',
        timestamp: preparingAt,
        isCompleted: isPrepStep,
      ),
    );

    // 4. Shipped to Carrier
    final bool isShipStep =
        shippedAt != null || isShipped || isDelivered || isCompleted;
    final carrier = shipment?.carrierName ?? 'Đơn vị vận chuyển';
    final tracking = shipment?.trackingCode ?? '';
    events.add(
      ShipmentTimelineEventModel(
        title: 'Đã giao cho vận chuyển ($carrier)',
        description: isShipStep
            ? 'Mã vận đơn: $tracking. Kiện hàng đang trên đường giao.'
            : 'Chờ tiệm bàn giao cho shipper.',
        timestamp: shippedAt,
        isCompleted: isShipStep,
      ),
    );

    // 5. Delivered to Buyer
    final bool isDeliverStep =
        deliveredAt != null || isDelivered || isCompleted;
    events.add(
      ShipmentTimelineEventModel(
        title: 'Đã giao đến người mua',
        description: isDeliverStep
            ? 'Kiện hàng đã được phát thành công đến địa chỉ người nhận.'
            : 'Đang lưu thông trên tuyến giao nhận.',
        timestamp: deliveredAt,
        isCompleted: isDeliverStep,
      ),
    );

    return events;
  }
}
