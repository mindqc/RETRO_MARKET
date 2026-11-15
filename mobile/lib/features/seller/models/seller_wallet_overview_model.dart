import '../../../core/utils/safe_json_parser.dart';
import 'wallet_transaction_model.dart';

/// Overview model for Seller Wallet and Escrow reconciliation (M-SL-08).
class SellerWalletOverviewModel {
  final double walletBalance;
  final double escrowHeldBalance;
  final double totalEarned;
  final int completedOrdersCount;
  final List<WalletTransactionModel> transactions;

  const SellerWalletOverviewModel({
    required this.walletBalance,
    required this.escrowHeldBalance,
    this.totalEarned = 0.0,
    this.completedOrdersCount = 0,
    this.transactions = const [],
  });

  factory SellerWalletOverviewModel.fromJson(Map<String, dynamic> json) {
    final List<WalletTransactionModel> txList = [];
    final rawList = json['wallet_transactions'] ?? json['transactions'];
    if (rawList is List) {
      for (final tx in rawList) {
        if (tx is Map<String, dynamic>) {
          txList.add(WalletTransactionModel.fromJson(tx));
        }
      }
    }

    final double balance = SafeJsonParser.toDouble(json['wallet_balance']);
    final double escrow = SafeJsonParser.toDouble(json['escrow_held_balance']);

    return SellerWalletOverviewModel(
      walletBalance: balance,
      escrowHeldBalance: escrow,
      totalEarned: SafeJsonParser.toDouble(json['total_earned'], defaultValue: balance + escrow),
      completedOrdersCount: SafeJsonParser.toInt(json['completed_orders_count']),
      transactions: txList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wallet_balance': walletBalance,
      'escrow_held_balance': escrowHeldBalance,
      'total_earned': totalEarned,
      'completed_orders_count': completedOrdersCount,
      'wallet_transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }
}
