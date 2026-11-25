import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';

/// Modal Bottom Sheet for Seller to attach tracking code and ship order (M-SL-07).
class ShipOrderFormModal extends StatefulWidget {
  final int orderId;
  final String orderCode;
  final Future<void> Function({
    required String carrierName,
    required String trackingCode,
    String? shippingNote,
  }) onConfirmShip;

  const ShipOrderFormModal({
    super.key,
    required this.orderId,
    required this.orderCode,
    required this.onConfirmShip,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int orderId,
    required String orderCode,
    required Future<void> Function({
      required String carrierName,
      required String trackingCode,
      String? shippingNote,
    }) onConfirmShip,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ShipOrderFormModal(
          orderId: orderId,
          orderCode: orderCode,
          onConfirmShip: onConfirmShip,
        ),
      ),
    );
  }

  @override
  State<ShipOrderFormModal> createState() => _ShipOrderFormModalState();
}

class _ShipOrderFormModalState extends State<ShipOrderFormModal> {
  final TextEditingController _trackingController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedCarrier = 'Giao Hàng Nhanh (GHN)';
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<String> _carriers = [
    'Giao Hàng Nhanh (GHN)',
    'Viettel Post',
    'Giao Hàng Tiết Kiệm (GHTK)',
    'J&T Express',
    'Chủ tiệm tự vận chuyển (Hỏa tốc)',
  ];

  @override
  void dispose() {
    _trackingController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: DesignTokens.modalElevation,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                    borderRadius: DesignTokens.borderRadiusFull,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          AppColors.categoryCircleStart,
                          AppColors.categoryCircleEnd,
                        ],
                      ),
                      border: Border.all(color: AppColors.creamBadgeBorder),
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      color: AppColors.pineDeep,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giao hàng cho vận chuyển',
                          style:
                              AppTypography.headingSmall.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Đơn hàng: ${widget.orderCode}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1. Select Carrier
              Text(
                'Chọn đơn vị vận chuyển:',
                style: AppTypography.labelStrong.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCarrier,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: DesignTokens.borderRadiusMd,
                    borderSide: const BorderSide(color: AppColors.borderWarm),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: DesignTokens.borderRadiusMd,
                    borderSide: const BorderSide(color: AppColors.borderWarm),
                  ),
                ),
                items: _carriers.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(
                      c,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCarrier = val);
                },
              ),
              const SizedBox(height: 14),

              // 2. Tracking Code Input
              Text(
                'Mã vận đơn (bắt buộc):',
                style: AppTypography.labelStrong.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('input_tracking_code'),
                controller: _trackingController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  hintText: 'Ví dụ: GHN-12345678VN',
                  prefixIcon: const Icon(
                    Icons.qr_code_2_rounded,
                    size: 19,
                    color: AppColors.textMuted,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: DesignTokens.borderRadiusMd,
                    borderSide: const BorderSide(color: AppColors.borderWarm),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: DesignTokens.borderRadiusMd,
                    borderSide: const BorderSide(color: AppColors.borderWarm),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Shipping Note (optional)
              Text(
                'Ghi chú vận chuyển (không bắt buộc):',
                style: AppTypography.labelStrong.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  hintText: 'Ví dụ: Hàng dễ vỡ, xin nhẹ tay',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: DesignTokens.borderRadiusMd,
                    borderSide: const BorderSide(color: AppColors.borderWarm),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: DesignTokens.borderRadiusMd,
                    borderSide: const BorderSide(color: AppColors.borderWarm),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.priceCrimsonSoft,
                    borderRadius: DesignTokens.borderRadiusSm,
                    border: Border.all(color: AppColors.priceCrimsonBorder),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.priceCrimson,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textCharcoal,
                          side: const BorderSide(color: AppColors.borderWarm),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        key: const Key('btn_submit_ship_order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pineDeep,
                          foregroundColor: AppColors.textLight,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Xác nhận gửi hàng',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final tracking = _trackingController.text.trim();
    if (tracking.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mã vận đơn.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onConfirmShip(
        carrierName: _selectedCarrier,
        trackingCode: tracking,
        shippingNote: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Không thể cập nhật vận đơn: $e';
        });
      }
    }
  }
}
