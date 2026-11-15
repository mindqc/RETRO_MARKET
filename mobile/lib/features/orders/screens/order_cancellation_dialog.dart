import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/order_model.dart';

/// Modal dialog for 3-Tier Order Cancellation (DEC-06 / DEC-07 / M-OR-04).
class OrderCancellationDialog extends StatefulWidget {
  final OrderModel order;
  final Future<void> Function(String reason) onConfirmCancel;

  const OrderCancellationDialog({
    super.key,
    required this.order,
    required this.onConfirmCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required OrderModel order,
    required Future<void> Function(String reason) onConfirmCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrderCancellationDialog(
        order: order,
        onConfirmCancel: onConfirmCancel,
      ),
    );
  }

  @override
  State<OrderCancellationDialog> createState() => _OrderCancellationDialogState();
}

class _OrderCancellationDialogState extends State<OrderCancellationDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String _selectedReason = 'Đổi ý, không muốn mua nữa';
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _commonReasons = [
    'Đổi ý, không muốn mua nữa',
    'Tìm thấy sản phẩm khác giá tốt hơn',
    'Thời gian giao hàng quá lâu',
    'Nhập sai địa chỉ nhận hàng',
    'Lý do khác',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isLevel1 = order.isPendingPayment;
    final isLevel2 = order.isPaid;
    final isLevel3 = order.isPreparing;

    String title;
    String description;
    Color headerColor;
    IconData headerIcon;

    if (isLevel1) {
      title = 'Hủy đơn chưa thanh toán';
      description = 'Đơn hàng sẽ được hủy ngay lập tức và giải phóng sản phẩm về kho.';
      headerColor = AppColors.textMuted;
      headerIcon = Icons.cancel_outlined;
    } else if (isLevel2) {
      title = 'Hủy đơn & Hoàn tiền 100%';
      description = 'Đơn hàng đã thanh toán sẽ được hủy tự động và hoàn trả 100% tiền hàng theo chính sách bảo vệ người mua (DEC-07).';
      headerColor = AppColors.primaryTerracotta;
      headerIcon = Icons.replay_circle_filled_outlined;
    } else {
      title = 'Gửi yêu cầu xin hủy đơn';
      description = 'Đơn hàng đang được tiệm đóng gói. Yêu cầu của bạn sẽ được gửi tới Chủ tiệm để duyệt (DEC-06).';
      headerColor = AppColors.statusWarning;
      headerIcon = Icons.hourglass_top_outlined;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 14),
        decoration: BoxDecoration(
          color: headerColor.withAlpha(20),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(DesignTokens.radiusMd),
            topRight: Radius.circular(DesignTokens.radiusMd),
          ),
        ),
        child: Row(
          children: [
            Icon(headerIcon, color: headerColor, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppTypography.headingSmall.copyWith(fontSize: 16, color: AppColors.textCharcoal),
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            const Text(
              'Chọn lý do hủy:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
              ),
              items: _commonReasons.map((r) {
                return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedReason = val);
              },
            ),
            if (_selectedReason == 'Lý do khác' || isLevel3) ...[
              const SizedBox(height: DesignTokens.spaceMd),
              const Text(
                'Chi tiết lý do (bắt buộc):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Nhập lý do hủy chi tiết...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.statusDanger, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Đóng'),
        ),
        ElevatedButton(
          key: const Key('btn_confirm_cancel_order'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isLevel3 ? AppColors.statusWarning : AppColors.statusDanger,
            foregroundColor: AppColors.textLight,
          ),
          onPressed: _isSubmitting
              ? null
              : () async {
                  String finalReason = _selectedReason;
                  if (_selectedReason == 'Lý do khác' || isLevel3) {
                    final text = _reasonController.text.trim();
                    if (text.isEmpty && isLevel3) {
                      setState(() => _errorMessage = 'Vui lòng nhập lý do xin hủy chi tiết.');
                      return;
                    }
                    if (text.isNotEmpty) {
                      finalReason = text;
                    }
                  }

                  setState(() {
                    _isSubmitting = true;
                    _errorMessage = null;
                  });

                  try {
                    await widget.onConfirmCancel(finalReason);
                    if (!context.mounted) return;
                    Navigator.of(context).pop(true);
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _isSubmitting = false;
                        _errorMessage = 'Không thể hủy đơn: $e';
                      });
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(isLevel3 ? 'Gửi yêu cầu' : 'Xác nhận hủy'),
        ),
      ],
    );
  }
}
