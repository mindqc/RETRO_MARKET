import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/seller_wallet_overview_model.dart';
import '../models/wallet_transaction_model.dart';
import '../viewmodels/seller_hub_view_model.dart';

/// M-SL-08: Seller Wallet Ledger Screen
/// Displays immutable append-only financial ledger transactions, wallet balance,
/// and escrow held balance.
class SellerWalletLedgerScreen extends ConsumerStatefulWidget {
  const SellerWalletLedgerScreen({super.key});

  @override
  ConsumerState<SellerWalletLedgerScreen> createState() => _SellerWalletLedgerScreenState();
}

class _SellerWalletLedgerScreenState extends ConsumerState<SellerWalletLedgerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sellerHubViewModelProvider).loadWalletLedger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(sellerHubViewModelProvider);
    final wallet = vm.walletOverview;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Sổ Cái Ví & Giao Dịch'),
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryTerracotta,
          onRefresh: () => ref.read(sellerHubViewModelProvider).loadWalletLedger(),
          child: vm.isLoadingWallet && wallet == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta))
              : _buildLedgerContent(wallet),
        ),
      ),
    );
  }

  Widget _buildLedgerContent(SellerWalletOverviewModel? wallet) {
    final balance = wallet?.walletBalance ?? 0.0;
    final escrow = wallet?.escrowHeldBalance ?? 0.0;
    final transactions = wallet?.transactions ?? [];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      children: [
        // 1. Wallet Balance Summary Card
        _buildBalanceCard(balance, escrow),

        const SizedBox(height: DesignTokens.spaceLg),

        // 2. Note on Append-Only Financial Ledger
        Container(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF5EE),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: const Color(0xFFBCE3C6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.secondaryPineGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sổ cái tài chính bất biến (Append-Only Ledger): Mọi biến động số dư và giải ngân ký quỹ Escrow được lưu vĩnh viễn, không bao giờ sửa đổi hoặc xóa.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondaryPineGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spaceXl),

        // 3. Transactions Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lịch sử biến động số dư',
              style: AppTypography.headingSmall.copyWith(fontSize: 16),
            ),
            Text(
              '${transactions.length} giao dịch',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.spaceMd),

        // 4. Ledger Transaction List
        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: RetroEmptyStateView(
              title: 'Chưa có biến động',
              message: 'Chưa có biến động giao dịch ví nào.',
              icon: Icons.receipt_long_outlined,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.spaceSm),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return _buildTransactionCard(tx);
            },
          ),

        const SizedBox(height: DesignTokens.space2xl),
      ],
    );
  }

  Widget _buildBalanceCard(double balance, double escrow) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF294638), Color(0xFF1E352A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: AppColors.textLight, size: 20),
              const SizedBox(width: 8),
              Text(
                'Số dư ví khả dụng',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textLight.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            VndFormatter.format(balance),
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textLight,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_clock, size: 16, color: Color(0xFFC5A66B)),
                  const SizedBox(width: 6),
                  Text(
                    'Ký quỹ đang giữ (Escrow):',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textLight.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              Text(
                VndFormatter.format(escrow),
                style: AppTypography.bodyMedium.copyWith(
                  color: const Color(0xFFC5A66B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransactionModel tx) {
    final isCredit = tx.isCredit;
    final prefix = isCredit ? '+' : '-';
    final amountColor = isCredit ? AppColors.secondaryPineGreen : AppColors.statusDanger;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Circle
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCredit ? const Color(0xFFEBF5EE) : const Color(0xFFFDE8E8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              size: 20,
              color: amountColor,
            ),
          ),

          const SizedBox(width: DesignTokens.spaceMd),

          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tx.type == 'CREDIT' ? 'Cộng tiền vào ví' : 'Trừ tiền ví',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    Text(
                      '$prefix${VndFormatter.format(tx.amount)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tx.description ?? 'Biến động ví',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textCharcoal),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mã GD: ${tx.walletTxCode}',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                    ),
                    Text(
                      'Sau GD: ${VndFormatter.format(tx.balanceAfter)}',
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF84664C),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (tx.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${tx.createdAt!.day.toString().padLeft(2, '0')}/${tx.createdAt!.month.toString().padLeft(2, '0')}/${tx.createdAt!.year} ${tx.createdAt!.hour.toString().padLeft(2, '0')}:${tx.createdAt!.minute.toString().padLeft(2, '0')}',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
