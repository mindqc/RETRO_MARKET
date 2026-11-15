import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/auction_detail_model.dart';
import '../viewmodels/live_auction_view_model.dart';

/// Modal Bottom Sheet M-AC-06: Seller Relist Auction Form (DEC-02 / AF-09)
class SellerRelistAuctionModal extends ConsumerStatefulWidget {
  final int auctionId;

  const SellerRelistAuctionModal({
    super.key,
    required this.auctionId,
  });

  static Future<AuctionDetailModel?> show(BuildContext context, int auctionId) {
    return showModalBottomSheet<AuctionDetailModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SellerRelistAuctionModal(auctionId: auctionId),
      ),
    );
  }

  @override
  ConsumerState<SellerRelistAuctionModal> createState() => _SellerRelistAuctionModalState();
}

class _SellerRelistAuctionModalState extends ConsumerState<SellerRelistAuctionModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startPriceController = TextEditingController();
  final TextEditingController _incrementController = TextEditingController();
  final TextEditingController _reservePriceController = TextEditingController();

  int _durationHours = 24;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(liveAuctionViewModelProvider(widget.auctionId));
      final a = vm.auction;
      if (a != null) {
        _startPriceController.text = a.startingPrice.toStringAsFixed(0);
        _incrementController.text = a.minBidIncrement.toStringAsFixed(0);
        if (a.reservePrice != null) {
          _reservePriceController.text = a.reservePrice!.toStringAsFixed(0);
        }
      }
    });
  }

  @override
  void dispose() {
    _startPriceController.dispose();
    _incrementController.dispose();
    _reservePriceController.dispose();
    super.dispose();
  }

  Future<void> _submitRelist(LiveAuctionViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final startPrice = double.tryParse(_startPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    final increment = double.tryParse(_incrementController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10000.0;
    final reservePrice = _reservePriceController.text.isNotEmpty
        ? double.tryParse(_reservePriceController.text.replaceAll(RegExp(r'[^0-9]'), ''))
        : null;

    final now = DateTime.now();
    final startsAt = now;
    final endsAt = now.add(Duration(hours: _durationHours));

    final newAuction = await vm.relistAuction(
      startingPrice: startPrice,
      minBidIncrement: increment,
      auctionStartsAt: startsAt,
      auctionEndsAt: endsAt,
      reservePrice: reservePrice,
    );

    if (!mounted) return;

    if (newAuction != null) {
      Navigator.of(context).pop(newAuction);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tái đăng phiên đấu giá thành công!'),
          backgroundColor: AppColors.primaryForestGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(liveAuctionViewModelProvider(widget.auctionId));
    final a = vm.auction;
    if (a != null && _startPriceController.text.isEmpty) {
      _startPriceController.text = a.startingPrice.toStringAsFixed(0);
      _incrementController.text = a.minBidIncrement.toStringAsFixed(0);
      if (a.reservePrice != null && _reservePriceController.text.isEmpty) {
        _reservePriceController.text = a.reservePrice!.toStringAsFixed(0);
      }
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
        ),
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  children: [
                    const Icon(Icons.replay, color: AppColors.accentBurgundy),
                    const SizedBox(width: 8),
                    Text(
                      'Tái Đăng Phiên Đấu Giá',
                      style: AppTypography.headingSmall.copyWith(color: AppColors.primaryForestGreen),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textCharcoalMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingSm),
                Text(
                  'Điều chỉnh thông tin giá và thời hạn cho phiên đấu giá mới.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textCharcoalMuted),
                ),
                const SizedBox(height: DesignTokens.spacingMd),

                // Starting Price Field
                Text('Giá khởi điểm (VNĐ)*', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _startPriceController,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    final n = double.tryParse(val?.replaceAll(RegExp(r'[^0-9]'), '') ?? '');
                    if (n == null || n <= 0) return 'Vui lòng nhập giá khởi điểm hợp lệ';
                    return null;
                  },
                  decoration: InputDecoration(
                    suffixText: 'đ',
                    filled: true,
                    fillColor: AppColors.surfaceWarm,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingMd),

                // Min Bid Increment Field
                Text('Bước giá tối thiểu (VNĐ)*', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _incrementController,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    final n = double.tryParse(val?.replaceAll(RegExp(r'[^0-9]'), '') ?? '');
                    if (n == null || n <= 0) return 'Vui lòng nhập bước giá hợp lệ';
                    return null;
                  },
                  decoration: InputDecoration(
                    suffixText: 'đ',
                    filled: true,
                    fillColor: AppColors.surfaceWarm,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingMd),

                // Duration chips
                Text('Thời lượng phiên đấu giá:', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [24, 48, 72].map((hrs) {
                    final isSelected = _durationHours == hrs;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Text('$hrs giờ'),
                        onSelected: (_) => setState(() => _durationHours = hrs),
                        selectedColor: AppColors.primaryForestGreen,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textDarkCharcoal),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: DesignTokens.spacingMd),

                // Optional Reserve Price
                Text('Giá sàn bảo lưu (Tùy chọn)', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _reservePriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Để trống nếu không đặt giá sàn',
                    suffixText: 'đ',
                    filled: true,
                    fillColor: AppColors.surfaceWarm,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingLg),

                if (vm.bidErrorMessage != null) ...[
                  Text(
                    vm.bidErrorMessage!,
                    style: AppTypography.bodySmall.copyWith(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                ],

                // CTA Submit
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: vm.isRelisting ? null : () => _submitRelist(vm),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBurgundy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                    ),
                    child: vm.isRelisting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Xác nhận đăng lại phiên đấu giá', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
