import '../../../core/utils/safe_json_parser.dart';

/// Represents a Mock QR payment session with Escrow hold states (M-PM-01..03).
class PaymentSessionModel {
  final int paymentId;
  final String paymentCode;
  final int orderId;
  final String orderCode;
  final double amount;
  final String? qrPayload;
  final String? qrCodeUrl;
  final String transferContent;
  final String paymentStatus; // PENDING, PAID, FAILED, EXPIRED
  final String orderStatus; // PENDING_PAYMENT, PAID, CANCELLED
  final String escrowStatus; // PENDING, HELD / ESCROW_HELD
  final String? failureReason;
  final DateTime paymentExpiresAt;
  final DateTime? paidAt;
  final DateTime? createdAt;

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
  });

  bool get isPaid => paymentStatus == 'PAID' || paymentStatus == 'SUCCESS';
  bool get isFailed => paymentStatus == 'FAILED';
  bool get isExpired => paymentStatus == 'EXPIRED';

  factory PaymentSessionModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> paymentMap = json['payment'] is Map<String, dynamic>
        ? json['payment'] as Map<String, dynamic>
        : json;

    Map<String, dynamic> orderMap = json['order'] is Map<String, dynamic>
        ? json['order'] as Map<String, dynamic>
        : json;

    final pId = SafeJsonParser.toInt(
      paymentMap['id'] ?? paymentMap['payment_id'] ?? json['payment_id'],
    );
    final pCode = SafeJsonParser.toStringValue(
      paymentMap['payment_reference'] ?? paymentMap['payment_code'] ?? 'PAY-$pId',
    );
    final oId = SafeJsonParser.toInt(
      orderMap['id'] ?? paymentMap['order_id'] ?? json['order_id'],
    );
    final oCode = SafeJsonParser.toStringValue(
      orderMap['order_code'] ?? paymentMap['order_code'] ?? json['order_code'] ?? 'ORD-$oId',
    );

    final amt = SafeJsonParser.toDouble(
      paymentMap['amount'] ?? orderMap['total_amount'] ?? json['amount'],
    );

    final String rawQr = SafeJsonParser.toNullableString(
      paymentMap['qr_payload'] ?? paymentMap['qr_code_url'] ?? json['qr_code_url'],
    ) ?? 'https://api.vietqr.io/image/970422-izithrift-$amt.jpg';

    final String defaultContent = SafeJsonParser.toNullableString(
      paymentMap['transfer_content'] ?? json['transfer_content'],
    ) ?? 'IZITHRIFT $oCode';

    final pStatus = SafeJsonParser.toStringValue(
      paymentMap['status'] ?? json['payment_status'],
      defaultValue: 'PENDING',
    ).toUpperCase();

    final oStatus = SafeJsonParser.toStringValue(
      orderMap['order_status'] ?? json['order_status'],
      defaultValue: pStatus == 'PAID' ? 'PAID' : 'PENDING_PAYMENT',
    ).toUpperCase();

    final eStatus = SafeJsonParser.toStringValue(
      orderMap['escrow_status'] ?? json['escrow_status'],
      defaultValue: (pStatus == 'PAID' || oStatus == 'PAID') ? 'HELD' : 'PENDING',
    ).toUpperCase();

    final expires = SafeJsonParser.toNullableDateTime(
      paymentMap['expires_at'] ?? orderMap['payment_expires_at'] ?? json['payment_expires_at'],
    ) ?? DateTime.now().add(const Duration(minutes: 30));

    final paid = SafeJsonParser.toNullableDateTime(
      paymentMap['paid_at'] ?? orderMap['paid_at'] ?? json['paid_at'],
    );

    final created = SafeJsonParser.toNullableDateTime(
      paymentMap['created_at'] ?? orderMap['created_at'] ?? json['created_at'],
    );

    return PaymentSessionModel(
      paymentId: pId,
      paymentCode: pCode,
      orderId: oId,
      orderCode: oCode,
      amount: amt,
      qrPayload: rawQr,
      qrCodeUrl: rawQr,
      transferContent: defaultContent,
      paymentStatus: pStatus,
      orderStatus: oStatus,
      escrowStatus: eStatus == 'ESCROW_HELD' ? 'HELD' : eStatus,
      failureReason: SafeJsonParser.toNullableString(
        paymentMap['failure_reason'] ?? json['failure_reason'],
      ),
      paymentExpiresAt: expires,
      paidAt: paid,
      createdAt: created,
    );
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
    );
  }
}
