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
  ConsumerState<BidPlacementBottomSheet> createState() =>
      _BidPlacementBottomSheetState();
}

class _BidPlacementBottomSheetState
    extends ConsumerState<BidPlacementBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  double? _selectedBidAmount;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDefaultBid());
  }

  void _initDefaultBid() {
    final vm = ref.read(liveAuctionViewModelProvider(widget.auctionId));
    final auction = vm.auction;
    if (auction != null) {
      final defaultBid =
          vm.outbidConflict?.minimumNextBid ?? auction.minimumNextBid;
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
        _validationError =
            'Mức giá đặt phải từ ${VndFormatter.format(minNextBid)} trở lên.';
      } else {
        _validationError = null;
      }
    });
  }

  Future<void> _submitBid(LiveAuctionViewModel vm, double minNextBid) async {
    final bid = _selectedBidAmount ?? minNextBid;
    if (bid < minNextBid) {
      setState(() {
        _validationError =
            'Mức giá đặt phải từ ${VndFormatter.format(minNextBid)} trở lên.';
      });
      return;
    }

    final success = await vm.placeBid(bid);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Bạn đã đặt giá thành công: ${VndFormatter.format(bid)}!',
          ),
          backgroundColor: AppColors.pineDeep,
        ),
      );
    } else if (vm.outbidConflict != null) {
      final newMin = vm.outbidConflict!.minimumNextBid;
      setState(() {
        _selectedBidAmount = newMin;
        _amountController.text = newMin.toStringAsFixed(0);
        _validationError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(liveAuctionViewModelProvider(widget.auctionId));
    final auction = vm.auction;

    if (auction == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radius2xl),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.ctaTerracotta),
        ),
      );
    }

    final conflict = vm.outbidConflict;
    final effectiveMinNextBid =
        conflict?.minimumNextBid ?? auction.minimumNextBid;
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
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radius2xl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderWarm,
                    borderRadius: DesignTokens.borderRadiusFull,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '🔨 Đặt Giá Thầu',
                    style: AppTypography.headingMedium.copyWith(
                      color: AppColors.pineDeep,
                      fontSize: 19,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () {
                      vm.clearConflict();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (conflict != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.priceCrimsonSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.priceCrimsonBorder,
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            color: AppColors.priceCrimson,
                            size: 20,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Mức giá vừa bị người khác vượt qua!',
                              style: TextStyle(
                                color: AppColors.priceCrimson,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Đã có người nhanh tay hơn trả ${VndFormatter.format(conflict.currentHighestBid)}. Mức giá tối thiểu mới là ${VndFormatter.format(effectiveMinNextBid)}.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textCharcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.creamBadgeSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.creamBadgeBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Giá cao nhất:', style: AppTypography.caption),
                        Text(
                          VndFormatter.format(
                            conflict?.currentHighestBid ??
                                auction.currentHighestBid,
                          ),
                          style: AppTypography.priceMedium.copyWith(
                            color: AppColors.priceCrimson,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Bước giá tối thiểu:',
                            style: AppTypography.caption),
                        Text(
                          '+${VndFormatter.format(increment)}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Chọn nhanh mức giá thầu:',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBidChip(chip1, 'Tối thiểu'),
                  _buildBidChip(chip2, '+1 bước'),
                  _buildBidChip(chip3, '+2 bước'),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Hoặc nhập mức giá tùy chỉnh:',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: (val) => _onAmountChanged(val, effectiveMinNextBid),
                decoration: InputDecoration(
                  suffixText: 'đ',
                  suffixStyle: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceSection,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderWarm),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.pineBanner,
                      width: 1.6,
                    ),
                  ),
                  errorText: _validationError ??
                      (conflict == null ? vm.bidErrorMessage : null),
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: vm.isSubmittingBid
                      ? null
                      : () => _submitBid(vm, effectiveMinNextBid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaTerracotta,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: vm.isSubmittingBid
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _selectedBidAmount != null
                              ? 'Xác nhận đặt giá • ${VndFormatter.format(_selectedBidAmount!)}'
                              : 'Xác nhận đặt giá',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBidChip(double amount, String subtitle) {
    final isSelected = _selectedBidAmount == amount;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => _onChipSelected(amount),
      selectedColor: AppColors.pineDeep,
      backgroundColor: AppColors.creamBadgeSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? AppColors.pineDeep : AppColors.creamBadgeBorder,
        ),
      ),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            VndFormatter.format(amount),
            style: AppTypography.bodySmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textCharcoal,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              color: isSelected
                  ? AppColors.creamBadgeBg
                  : AppColors.creamBadgeText,
            ),
          ),
        ],
      ),
    );
  }
}
