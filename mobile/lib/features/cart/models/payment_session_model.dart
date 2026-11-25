import '../../../core/utils/safe_json_parser.dart';

/// Represents a mock QR payment session with Escrow hold states.
class PaymentSessionModel {
  final int paymentId;
  final String paymentCode;
  final int orderId;
  final String orderCode;
  final double amount;
  final String? qrPayload;
  final String? qrCodeUrl;
  final String transferContent;
  final String paymentStatus;
  final String orderStatus;
  final String escrowStatus;
  final String? failureReason;
  final DateTime paymentExpiresAt;
  final DateTime? paidAt;
  final DateTime? createdAt;

  /// A fresh payment session returned by the backend after a failed attempt.
  /// This is intentionally separate from the failed payment represented above.
  final PaymentSessionModel? retrySession;

  const PaymentSessionModel({
    required this.paymentId,
    required this.paymentCode,
    required this.orderId,
    required this.orderCode,
    required this.amount,
    this.qrPayload,
    this.qrCodeUrl,
    required this.transferContent,
    this.paymentStatus = 'PENDING',
    this.orderStatus = 'PENDING_PAYMENT',
    this.escrowStatus = 'PENDING',
    this.failureReason,
    required this.paymentExpiresAt,
    this.paidAt,
    this.createdAt,
    this.retrySession,
  });

  bool get isPaid => paymentStatus == 'PAID' || paymentStatus == 'SUCCESS';
  bool get isFailed => paymentStatus == 'FAILED';
  bool get isExpired => paymentStatus == 'EXPIRED';

  /// QR content is app-specific demo data. It is not a bank-transfer payload.
  String get qrDisplayData {
    final payload = qrPayload?.trim();
    if (payload != null && payload.isNotEmpty) return payload;
    return 'RETRO_MARKET_DEMO|PAYMENT:$paymentId|ORDER:$orderCode|AMOUNT:${amount.toStringAsFixed(0)}';
  }

  factory PaymentSessionModel.fromJson(Map<String, dynamic> json) {
    final orderMap = _asMap(json['order']);
    final primaryPayment = _asMap(json['payment'] ?? json['failed_payment']);
    final paymentMap = primaryPayment.isNotEmpty ? primaryPayment : json;

    final parsed = _fromPaymentAndOrder(
      paymentMap: paymentMap,
      orderMap: orderMap.isNotEmpty ? orderMap : json,
      root: json,
      failureReasonOverride: json['reason'] ?? json['message'],
    );

    final newPaymentMap = _asMap(json['new_payment']);
    if (newPaymentMap.isEmpty) return parsed;

    final retry = _fromPaymentAndOrder(
      paymentMap: newPaymentMap,
      orderMap: orderMap.isNotEmpty ? orderMap : json,
      root: json,
    );

    return parsed.copyWith(retrySession: retry);
  }

  static PaymentSessionModel _fromPaymentAndOrder({
    required Map<String, dynamic> paymentMap,
    required Map<String, dynamic> orderMap,
    required Map<String, dynamic> root,
    Object? failureReasonOverride,
  }) {
    final pId = SafeJsonParser.toInt(
      paymentMap['id'] ?? paymentMap['payment_id'] ?? root['payment_id'],
    );
    final pCode = SafeJsonParser.toStringValue(
      paymentMap['payment_reference'] ??
          paymentMap['payment_code'] ??
          'PAY-$pId',
    );
    final oId = SafeJsonParser.toInt(
      orderMap['id'] ?? paymentMap['order_id'] ?? root['order_id'],
    );
    final oCode = SafeJsonParser.toStringValue(
      orderMap['order_code'] ??
          paymentMap['order_code'] ??
          root['order_code'] ??
          'ORD-$oId',
    );
    final amt = SafeJsonParser.toDouble(
      paymentMap['amount'] ?? orderMap['total_amount'] ?? root['amount'],
    );

    // Do not fabricate a VietQR URL. The QR is generated locally from this
    // app-specific payload and is only for demonstrating the UI flow.
    final qr = SafeJsonParser.toNullableString(
      paymentMap['qr_payload'] ??
          paymentMap['qr_code_url'] ??
          root['qr_payload'] ??
          root['qr_code_url'],
    );

    final transfer =
        SafeJsonParser.toNullableString(
          paymentMap['transfer_content'] ?? root['transfer_content'],
        ) ??
        'RETRO MARKET $oCode';

    final pStatus = SafeJsonParser.toStringValue(
      paymentMap['status'] ?? root['payment_status'],
      defaultValue: 'PENDING',
    ).toUpperCase();
    final oStatus = SafeJsonParser.toStringValue(
      orderMap['order_status'] ?? root['order_status'],
      defaultValue: pStatus == 'PAID' ? 'PAID' : 'PENDING_PAYMENT',
    ).toUpperCase();
    final eStatus = SafeJsonParser.toStringValue(
      orderMap['escrow_status'] ?? root['escrow_status'],
      defaultValue: (pStatus == 'PAID' || oStatus == 'PAID')
          ? 'HELD'
          : 'PENDING',
    ).toUpperCase();

    final expires =
        SafeJsonParser.toNullableDateTime(
          paymentMap['expires_at'] ??
              orderMap['payment_expires_at'] ??
              root['payment_expires_at'],
        ) ??
        DateTime.now().add(const Duration(minutes: 30));
    final paid = SafeJsonParser.toNullableDateTime(
      paymentMap['paid_at'] ?? orderMap['paid_at'] ?? root['paid_at'],
    );
    final created = SafeJsonParser.toNullableDateTime(
      paymentMap['created_at'] ?? orderMap['created_at'] ?? root['created_at'],
    );

    return PaymentSessionModel(
      paymentId: pId,
      paymentCode: pCode,
      orderId: oId,
      orderCode: oCode,
      amount: amt,
      qrPayload: qr,
      qrCodeUrl: null,
      transferContent: transfer,
      paymentStatus: pStatus,
      orderStatus: oStatus,
      escrowStatus: eStatus == 'ESCROW_HELD' ? 'HELD' : eStatus,
      failureReason: SafeJsonParser.toNullableString(
        paymentMap['failure_reason'] ??
            failureReasonOverride ??
            root['failure_reason'],
      ),
      paymentExpiresAt: expires,
      paidAt: paid,
      createdAt: created,
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> toJson() {
    return {
      'payment': {
        'id': paymentId,
        'payment_reference': paymentCode,
        'order_id': orderId,
        'amount': amount,
        'qr_payload': qrPayload,
        'status': paymentStatus,
        'failure_reason': failureReason,
        'expires_at': paymentExpiresAt.toIso8601String(),
        'paid_at': paidAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      },
      'order': {
        'id': orderId,
        'order_code': orderCode,
        'total_amount': amount,
        'order_status': orderStatus,
        'escrow_status': escrowStatus,
      },
    };
  }

  PaymentSessionModel copyWith({
    int? paymentId,
    String? paymentCode,
    int? orderId,
    String? orderCode,
    double? amount,
    String? qrPayload,
    String? qrCodeUrl,
    String? transferContent,
    String? paymentStatus,
    String? orderStatus,
    String? escrowStatus,
    String? failureReason,
    DateTime? paymentExpiresAt,
    DateTime? paidAt,
    DateTime? createdAt,
    PaymentSessionModel? retrySession,
  }) {
    return PaymentSessionModel(
      paymentId: paymentId ?? this.paymentId,
      paymentCode: paymentCode ?? this.paymentCode,
      orderId: orderId ?? this.orderId,
      orderCode: orderCode ?? this.orderCode,
      amount: amount ?? this.amount,
      qrPayload: qrPayload ?? this.qrPayload,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      transferContent: transferContent ?? this.transferContent,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      escrowStatus: escrowStatus ?? this.escrowStatus,
      failureReason: failureReason ?? this.failureReason,
      paymentExpiresAt: paymentExpiresAt ?? this.paymentExpiresAt,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      retrySession: retrySession ?? this.retrySession,
    );
  }
}
