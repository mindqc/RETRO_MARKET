import '../../../core/utils/safe_json_parser.dart';

/// Append-only immutable financial ledger entry in seller wallet (M-SL-08).
class WalletTransactionModel {
  final int id;
  final String transactionCode;
  final String type; // CREDIT or DEBIT
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? referenceType;
  final String? referenceCode;
  final int? orderId;
  final String? description;
  final DateTime? createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.transactionCode,
    required this.type,
    required this.amount,
    this.balanceBefore = 0.0,
    required this.balanceAfter,
    this.referenceType,
    this.referenceCode,
    this.orderId,
    this.description,
    this.createdAt,
  });

  bool get isCredit => type == 'CREDIT';
  String get walletTxCode => transactionCode;

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    String entryType = SafeJsonParser.toStringValue(
      json['type'] ?? json['entry_type'],
      defaultValue: 'CREDIT',
    ).toUpperCase();

    // In some backend representations, entry_type could be ESCROW_RELEASE, ORDER_PAYOUT, etc.
    if (entryType.contains('CREDIT') || entryType.contains('RELEASE') || entryType.contains('PAYOUT')) {
      entryType = 'CREDIT';
    } else if (entryType.contains('DEBIT') || entryType.contains('WITHDRAW') || entryType.contains('FEE')) {
      entryType = 'DEBIT';
    }

    String? refCode = SafeJsonParser.toNullableString(json['reference_code']);
    if (refCode == null && json['order'] is Map<String, dynamic>) {
      final o = json['order'] as Map<String, dynamic>;
      refCode = SafeJsonParser.toNullableString(o['order_code']);
    }

    return WalletTransactionModel(
      id: SafeJsonParser.toInt(json['id']),
      transactionCode: SafeJsonParser.toStringValue(
        json['transaction_code'] ?? json['wallet_tx_code'] ?? 'WTX-${json['id']}',
      ),
      type: entryType,
      amount: SafeJsonParser.toDouble(json['amount']),
      balanceBefore: SafeJsonParser.toDouble(json['balance_before']),
      balanceAfter: SafeJsonParser.toDouble(json['balance_after']),
      referenceType: SafeJsonParser.toNullableString(json['reference_type']),
      referenceCode: refCode,
      orderId: SafeJsonParser.toNullableInt(json['order_id']),
      description: SafeJsonParser.toNullableString(json['description']),
      createdAt: SafeJsonParser.toNullableDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_code': transactionCode,
      'type': type,
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'reference_type': referenceType,
      'reference_code': referenceCode,
      'order_id': orderId,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
