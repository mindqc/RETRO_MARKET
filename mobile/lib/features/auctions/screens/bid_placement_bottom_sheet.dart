import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../viewmodels/live_auction_view_model.dart';

/// Modal Bottom Sheet M-AC-04: Bid Placement & 409 AUCTION_OUTBID_CONFLICT handler
class BidPlacementBottomSheet extends ConsumerStatefulWidget {
  final int auctionId;

  const BidPlacementBottomSheet({
    super.key,
    required this.auctionId,
  });

  static Future<bool?> show(BuildContext context, int auctionId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: BidPlacementBottomSheet(auctionId: auctionId),
      ),
    );
  }

  @override
  ConsumerState<BidPlacementBottomSheet> createState() => _BidPlacementBottomSheetState();
}

class _BidPlacementBottomSheetState extends ConsumerState<BidPlacementBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  double? _selectedBidAmount;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDefaultBid();
    });
  }

  void _initDefaultBid() {
    final vm = ref.read(liveAuctionViewModelProvider(widget.auctionId));
    final auction = vm.auction;
    if (auction != null) {
      final defaultBid = vm.outbidConflict?.minimumNextBid ?? auction.minimumNextBid;
      setState(() {
        _selectedBidAmount = defaultBid;
        _amountController.text = defaultBid.toStringAsFixed(0);
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onChipSelected(double amount) {
    setState(() {
      _selectedBidAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
      _validationError = null;
    });
  }

  void _onAmountChanged(String val, double minNextBid) {
    final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
    setState(() {
      _selectedBidAmount = parsed;
      if (parsed == null || parsed < minNextBid) {
        _validationError = 'Mức giá đặt phải từ ${VndFormatter.format(minNextBid)} trở lên.';
      } else {
        _validationError = null;
      }
    });
  }

  Future<void> _submitBid(LiveAuctionViewModel vm, double minNextBid) async {
    final bid = _selectedBidAmount ?? minNextBid;
    if (bid < minNextBid) {
      setState(() {
        _validationError = 'Mức giá đặt phải từ ${VndFormatter.format(minNextBid)} trở lên.';
      });
      return;
    }

    final success = await vm.placeBid(bid);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Bạn đã đặt giá thành công: ${VndFormatter.format(bid)}!'),
          backgroundColor: AppColors.primaryForestGreen,
        ),
      );
    } else {
      // If 409 conflict occurred, the sheet stays open and adapts to vm.outbidConflict!
      if (vm.outbidConflict != null) {
        final newMin = vm.outbidConflict!.minimumNextBid;
        setState(() {
          _selectedBidAmount = newMin;
          _amountController.text = newMin.toStringAsFixed(0);
          _validationError = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(liveAuctionViewModelProvider(widget.auctionId));
    final auction = vm.auction;

    if (auction == null) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Determine current effective minimum next bid (considers 409 latest_state if present)
    final conflict = vm.outbidConflict;
    final effectiveMinNextBid = conflict?.minimumNextBid ?? auction.minimumNextBid;
    final increment = auction.minBidIncrement;

    if (_selectedBidAmount == null) {
      _selectedBidAmount = effectiveMinNextBid;
      _amountController.text = effectiveMinNextBid.toStringAsFixed(0);
    }

    final chip1 = effectiveMinNextBid;
    final chip2 = effectiveMinNextBid + increment;
    final chip3 = effectiveMinNextBid + (increment * 2);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
        ),
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderWarm,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMd),

            // Header
            Row(
              children: [
                Text(
                  '🔨 Đặt Giá Thầu',
                  style: AppTypography.headingMedium.copyWith(color: AppColors.primaryForestGreen),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textCharcoalMuted),
                  onPressed: () {
                    vm.clearConflict();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingSm),

            // 409 Conflict Banner (Sticky on Sheet)
            if (conflict != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
                padding: const EdgeInsets.all(DesignTokens.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: Colors.red.shade300, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mức giá vừa bị người khác vượt qua!',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Đã có người nhanh tay hơn trả ${VndFormatter.format(conflict.currentHighestBid)}. Mức giá tối thiểu mới là ${VndFormatter.format(effectiveMinNextBid)}.',
                      style: AppTypography.bodySmall.copyWith(color: Colors.brown.shade800),
                    ),
                  ],
                ),
              ),
            ],

            // Current Info Row
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingSm + 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Giá cao nhất:', style: AppTypography.bodySmall),
                      Text(
                        VndFormatter.format(conflict?.currentHighestBid ?? auction.currentHighestBid),
                        style: AppTypography.priceMedium.copyWith(
                          color: AppColors.accentBurgundy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Bước giá tối thiểu:', style: AppTypography.bodySmall),
                      Text(
                        '+${VndFormatter.format(increment)}',
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMd),

            // Quick Bid Chips
            Text(
              'Chọn nhanh mức giá thầu:',
              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            Wrap(
              spacing: DesignTokens.spacingSm,
              children: [
                _buildBidChip(chip1, 'Tối thiểu', effectiveMinNextBid),
                _buildBidChip(chip2, '+1 bước', effectiveMinNextBid),
                _buildBidChip(chip3, '+2 bước', effectiveMinNextBid),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingMd),

            // Custom Input
            Text(
              'Hoặc nhập mức giá tùy chỉnh:',
              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (val) => _onAmountChanged(val, effectiveMinNextBid),
              decoration: InputDecoration(
                suffixText: 'đ',
                suffixStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                filled: true,
                fillColor: AppColors.surfaceWarm,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  borderSide: const BorderSide(color: AppColors.borderWarm),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  borderSide: const BorderSide(color: AppColors.primaryForestGreen, width: 2),
                ),
                errorText: _validationError ?? (conflict == null ? vm.bidErrorMessage : null),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLg),

            // Submit CTA Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: vm.isSubmittingBid
                    ? null
                    : () => _submitBid(vm, effectiveMinNextBid),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBurgundy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
                child: vm.isSubmittingBid
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _selectedBidAmount != null
                            ? 'Xác nhận đặt giá • ${VndFormatter.format(_selectedBidAmount!)}'
                            : 'Xác nhận đặt giá',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBidChip(double amount, String subtitle, double minNextBid) {
    final isSelected = _selectedBidAmount == amount;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => _onChipSelected(amount),
      selectedColor: AppColors.primaryForestGreen,
      backgroundColor: AppColors.surfaceWarm,
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            VndFormatter.format(amount),
            style: AppTypography.bodySmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textDarkCharcoal,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 10,
              color: isSelected ? Colors.white70 : AppColors.textCharcoalMuted,
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        side: BorderSide(
          color: isSelected ? AppColors.primaryForestGreen : AppColors.borderWarm,
        ),
      ),
    );
  }
}
