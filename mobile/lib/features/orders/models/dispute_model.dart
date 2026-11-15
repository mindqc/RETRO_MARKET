import '../../../core/utils/safe_json_parser.dart';
import 'dispute_evidence_model.dart';
import 'order_model.dart';

/// Full Dispute case domain model managing escrow freezing, 2-way counter evidence,
/// and admin resolution verdict (DEC-03 / DEC-07 / M-DP-01..03).
class DisputeModel {
  final int id;
  final String disputeCode;
  final int orderId;
  final String orderCode;
  final int buyerId;
  final int sellerId;
  final String? openedAtOrderStatus;
  final String status; // OPEN, NEED_MORE_INFO, RESOLVED
  final String reasonCategory;
  final String description;
  final String? sellerResponse;
  final double escrowFrozenAmount;
  final String? adminVerdict; // FULL_REFUND_TO_BUYER, RELEASE_TO_SELLER, PARTIAL_REFUND
  final double? refundAmount;
  final String? adminResolutionNote;
  final List<DisputeEvidenceModel> evidences;
  final OrderModel? order;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const DisputeModel({
    required this.id,
    required this.disputeCode,
    required this.orderId,
    required this.orderCode,
    required this.buyerId,
    required this.sellerId,
    this.openedAtOrderStatus,
    required this.status,
    required this.reasonCategory,
    required this.description,
    this.sellerResponse,
    required this.escrowFrozenAmount,
    this.adminVerdict,
    this.refundAmount,
    this.adminResolutionNote,
    this.evidences = const [],
    this.order,
    this.createdAt,
    this.resolvedAt,
  });

  bool get isOpen => status == 'OPEN';
  bool get isNeedMoreInfo => status == 'NEED_MORE_INFO';
  bool get isResolved => status == 'RESOLVED';

  String get reasonCategoryLabel {
    switch (reasonCategory) {
      case 'ITEM_NOT_AS_DESCRIBED':
        return 'Hàng không đúng mô tả';
      case 'COUNTERFEIT_FAKE':
        return 'Hàng giả / hàng nhái';
      case 'DAMAGED_IN_TRANSIT':
        return 'Hàng hư hỏng trong lúc vận chuyển';
      case 'ITEM_NOT_RECEIVED':
        return 'Chưa nhận được kiện hàng';
      default:
        return reasonCategory;
    }
  }

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    OrderModel? orderObj;
    String oCode = SafeJsonParser.toStringValue(json['order_code'], defaultValue: 'ORD-0');
    double frozenAmt = SafeJsonParser.toDouble(json['escrow_frozen_amount']);

    if (json['order'] is Map<String, dynamic>) {
      orderObj = OrderModel.fromJson(json['order'] as Map<String, dynamic>);
      oCode = orderObj.orderCode;
      if (frozenAmt == 0.0) {
        frozenAmt = orderObj.totalAmount;
      }
    }

    final rawEvidences = json['evidences'];
    final List<DisputeEvidenceModel> evidenceList = [];
    if (rawEvidences is List) {
      for (final ev in rawEvidences) {
        if (ev is Map<String, dynamic>) {
          evidenceList.add(DisputeEvidenceModel.fromJson(ev));
        }
      }
    }

    return DisputeModel(
      id: SafeJsonParser.toInt(json['id']),
      disputeCode: SafeJsonParser.toStringValue(json['dispute_code'], defaultValue: 'DSP-${json['id']}'),
      orderId: SafeJsonParser.toInt(json['order_id']),
      orderCode: oCode,
      buyerId: SafeJsonParser.toInt(json['buyer_id']),
      sellerId: SafeJsonParser.toInt(json['seller_id']),
      openedAtOrderStatus: SafeJsonParser.toNullableString(json['opened_at_order_status']),
      status: SafeJsonParser.toStringValue(json['status'], defaultValue: 'OPEN').toUpperCase(),
      reasonCategory: SafeJsonParser.toStringValue(json['reason_category'], defaultValue: 'ITEM_NOT_AS_DESCRIBED'),
      description: SafeJsonParser.toStringValue(
        json['buyer_description'] ?? json['description'],
        defaultValue: 'Không có mô tả chi tiết.',
      ),
      sellerResponse: SafeJsonParser.toNullableString(json['seller_response']),
      escrowFrozenAmount: frozenAmt,
      adminVerdict: SafeJsonParser.toNullableString(json['admin_verdict']),
      refundAmount: SafeJsonParser.toNullableDouble(json['partial_refund_to_buyer'] ?? json['refund_amount']),
      adminResolutionNote: SafeJsonParser.toNullableString(json['resolution_note'] ?? json['admin_resolution_note']),
      evidences: evidenceList,
      order: orderObj,
      createdAt: SafeJsonParser.toNullableDateTime(json['created_at']),
      resolvedAt: SafeJsonParser.toNullableDateTime(json['resolved_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dispute_code': disputeCode,
      'order_id': orderId,
      'order_code': orderCode,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'opened_at_order_status': openedAtOrderStatus,
      'status': status,
      'reason_category': reasonCategory,
      'description': description,
      'seller_response': sellerResponse,
      'escrow_frozen_amount': escrowFrozenAmount,
      'admin_verdict': adminVerdict,
      'refund_amount': refundAmount,
      'admin_resolution_note': adminResolutionNote,
      'evidences': evidences.map((e) => e.toJson()).toList(),
      'order': order?.shippingAddressSnapshot,
      'created_at': createdAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }
}
