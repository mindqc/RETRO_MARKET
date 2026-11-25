import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../viewmodels/live_auction_view_model.dart';

/// Modal dialog M-AC-05: Seller Close Early confirmation (BR-AU-05 / AF-06)
class SellerCloseEarlyModal extends ConsumerWidget {
  final int auctionId;

  const SellerCloseEarlyModal({
    super.key,
    required this.auctionId,
  });

  static Future<bool?> show(BuildContext context, int auctionId) {
    return showDialog<bool>(
      context: context,
      builder: (_) => SellerCloseEarlyModal(auctionId: auctionId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(liveAuctionViewModelProvider(auctionId));
    final auction = vm.auction;

    if (auction == null) {
      return const AlertDialog(
        content: Center(
          child: CircularProgressIndicator(color: AppColors.ctaTerracotta),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
      ),
      title: Row(
        children: [
          const Icon(Icons.gavel_rounded, color: AppColors.priceCrimson),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chốt Phiên Đấu Giá Sớm',
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.pineDeep,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn có chắc chắn muốn chốt phiên sớm cho người trả giá cao nhất hiện tại?',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSection,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderWarm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Người thắng dự kiến:', style: AppTypography.caption),
                    Text(
                      auction.leadingBidderName ?? 'Chưa xác định',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mức giá chốt:', style: AppTypography.caption),
                    Text(
                      VndFormatter.format(auction.currentHighestBid),
                      style: AppTypography.priceMedium.copyWith(
                        color: AppColors.priceCrimson,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.creamBadgeSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.creamBadgeBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.ctaTerracotta,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lưu ý: Thao tác này sẽ kết thúc phiên ngay lập tức và tạo đơn hàng cho người thắng. Thao tác không thể hoàn tác.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.creamBadgeText,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (vm.bidErrorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              vm.bidErrorMessage!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.priceCrimson,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: vm.isClosingEarly
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Hủy bỏ'),
        ),
        ElevatedButton(
          onPressed: vm.isClosingEarly
              ? null
              : () async {
                  final ok = await vm.closeEarly();
                  if (context.mounted && ok) {
                    Navigator.of(context).pop(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Chốt phiên sớm thành công! Đơn hàng đã được tạo.',
                        ),
                        backgroundColor: AppColors.pineDeep,
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.priceCrimson,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
          ),
          child: vm.isClosingEarly
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Xác nhận chốt ngay'),
        ),
      ],
    );
  }
}
