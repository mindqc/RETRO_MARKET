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
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radiusLg),
          topRight: Radius.circular(DesignTokens.radiusLg),
        ),
      ),
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
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
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spaceMd),

          Text(
            'Giao hàng cho vận chuyển',
            style: AppTypography.headingSmall.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            'Đơn hàng: ${widget.orderCode}',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),

          const SizedBox(height: DesignTokens.spaceLg),

          // 1. Select Carrier
          const Text('Chọn đơn vị vận chuyển:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedCarrier,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
            ),
            items: _carriers.map((c) {
              return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCarrier = val);
            },
          ),

          const SizedBox(height: DesignTokens.spaceMd),

          // 2. Tracking Code Input
          const Text('Mã vận đơn (bắt buộc):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            key: const Key('input_tracking_code'),
            controller: _trackingController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Ví dụ: GHN-12345678VN',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
            ),
          ),

          const SizedBox(height: DesignTokens.spaceMd),

          // 3. Shipping Note (optional)
          const Text('Ghi chú vận chuyển (không bắt buộc):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Hàng dễ vỡ, xin nhẹ tay',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.statusDanger, fontSize: 12),
            ),
          ],

          const SizedBox(height: DesignTokens.spaceLg),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: ElevatedButton(
                  key: const Key('btn_submit_ship_order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryPineGreen,
                    foregroundColor: AppColors.textLight,
                  ),
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Xác nhận gửi hàng'),
                ),
              ),
            ],
          ),
        ],
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
        shippingNote: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
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
