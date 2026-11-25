import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/retro_design_primitives.dart';
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
  ConsumerState<SellerWalletLedgerScreen> createState() =>
      _SellerWalletLedgerScreenState();
}

class _SellerWalletLedgerScreenState
    extends ConsumerState<SellerWalletLedgerScreen> {
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
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Sổ Cái Ví & Giao Dịch',
          style: AppTypography.headingMedium.copyWith(fontSize: 19),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ctaTerracotta,
          onRefresh: () =>
              ref.read(sellerHubViewModelProvider).loadWalletLedger(),
          child: vm.isLoadingWallet && wallet == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.pineDeep),
                )
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // 1. Deep Pine Spotlight Wallet Balance Card
        _buildBalanceCard(balance, escrow),
        const SizedBox(height: 14),

        // 2. Append-Only Financial Ledger Notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.verifiedLeafBg,
            borderRadius: DesignTokens.borderRadiusLg,
            border: Border.all(
              color: AppColors.verifiedLeaf.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceCard,
                  border: Border.all(
                    color: AppColors.verifiedLeaf.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.verifiedLeaf,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sổ cái tài chính bất biến (Append-Only Ledger): Mọi biến động số dư và giải ngân ký quỹ Escrow được lưu vĩnh viễn, không bao giờ sửa đổi hoặc xóa.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.pineDeep,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // 3. Transactions Section Header
        Row(
          children: [
            const Expanded(
              child: RetroSectionHeader(
                title: 'Lịch sử biến động số dư',
                icon: Icons.receipt_long_outlined,
                iconColor: AppColors.pineDeep,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.creamBadgeSoft,
                borderRadius: DesignTokens.borderRadiusFull,
                border: Border.all(color: AppColors.creamBadgeBorder),
              ),
              child: Text(
                '${transactions.length} giao dịch',
                style: AppTypography.caption.copyWith(
                  color: AppColors.creamBadgeText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

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
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _buildTransactionCard(transactions[index]),
          ),
      ],
    );
  }

  Widget _buildBalanceCard(double balance, double escrow) {
    return RetroPineSpotlightContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.creamBadgeBg.withValues(alpha: 0.16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.creamBadgeBg,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Số dư ví khả dụng',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.creamBadgeBg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            VndFormatter.format(balance),
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textLight,
              fontSize: 29,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: DesignTokens.borderRadiusMd,
              border: Border.all(
                color: AppColors.creamBadgeBg.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_clock_outlined,
                      size: 16,
                      color: AppColors.creamBadgeBg,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ký quỹ đang giữ (Escrow):',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textLight.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
                Text(
                  VndFormatter.format(escrow),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.creamBadgeBg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransactionModel tx) {
    final isCredit = tx.isCredit;
    final prefix = isCredit ? '+' : '-';
    final amountColor =
        isCredit ? AppColors.verifiedLeaf : AppColors.priceCrimson;
    final iconBg =
        isCredit ? AppColors.verifiedLeafBg : AppColors.priceCrimsonSoft;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 19,
              color: amountColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tx.type == 'CREDIT' ? 'Cộng tiền vào ví' : 'Trừ tiền ví',
                      style: AppTypography.labelStrong.copyWith(
                        fontSize: 13.5,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    Text(
                      '$prefix${VndFormatter.format(tx.amount)}',
                      style: AppTypography.priceDisplay.copyWith(
                        fontSize: 14.5,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tx.description ?? 'Biến động ví',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textCharcoal,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Mã GD: ${tx.walletTxCode}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sau GD: ${VndFormatter.format(tx.balanceAfter)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryVintageBrown,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (tx.createdAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${tx.createdAt!.day.toString().padLeft(2, '0')}/${tx.createdAt!.month.toString().padLeft(2, '0')}/${tx.createdAt!.year} ${tx.createdAt!.hour.toString().padLeft(2, '0')}:${tx.createdAt!.minute.toString().padLeft(2, '0')}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                    ),
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
