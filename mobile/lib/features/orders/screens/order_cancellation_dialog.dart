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
  State<OrderCancellationDialog> createState() =>
      _OrderCancellationDialogState();
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
    Color headerBg;
    IconData headerIcon;

    if (isLevel1) {
      title = 'Hủy đơn chưa thanh toán';
      description =
          'Đơn hàng sẽ được hủy ngay lập tức và giải phóng sản phẩm về kho.';
      headerColor = AppColors.textCharcoal;
      headerBg = AppColors.surfaceWarm;
      headerIcon = Icons.cancel_outlined;
    } else if (isLevel2) {
      title = 'Hủy đơn & Hoàn tiền 100%';
      description =
          'Đơn hàng đã thanh toán sẽ được hủy tự động và hoàn trả 100% tiền hàng theo chính sách bảo vệ người mua (DEC-07).';
      headerColor = AppColors.ctaTerracotta;
      headerBg = AppColors.priceCrimsonSoft;
      headerIcon = Icons.replay_circle_filled_outlined;
    } else {
      title = 'Gửi yêu cầu xin hủy đơn';
      description =
          'Đơn hàng đang được tiệm đóng gói. Yêu cầu của bạn sẽ được gửi tới Chủ tiệm để duyệt (DEC-06).';
      headerColor = AppColors.creamBadgeText;
      headerBg = AppColors.creamBadgeSoft;
      headerIcon = Icons.hourglass_top_outlined;
    }

    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.borderRadiusBanner,
        side: const BorderSide(color: AppColors.borderWarm),
      ),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: headerBg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusBanner),
          ),
          border: const Border(
            bottom: BorderSide(color: AppColors.borderWarm),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceCard,
                border: Border.all(color: AppColors.borderWarm),
              ),
              child: Icon(headerIcon, color: headerColor, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTypography.headingSmall.copyWith(
                  fontSize: 16.5,
                  color: AppColors.textCharcoal,
                ),
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
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chọn lý do hủy:',
              style: AppTypography.labelStrong.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceWarm,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: DesignTokens.borderRadiusMd,
                  borderSide: const BorderSide(color: AppColors.borderWarm),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: DesignTokens.borderRadiusMd,
                  borderSide: const BorderSide(color: AppColors.borderWarm),
                ),
              ),
              items: _commonReasons.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(
                    r,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedReason = val);
              },
            ),
            if (_selectedReason == 'Lý do khác' || isLevel3) ...[
              const SizedBox(height: 14),
              Text(
                'Chi tiết lý do (bắt buộc):',
                style: AppTypography.labelStrong.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  hintText: 'Nhập lý do hủy chi tiết...',
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
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.priceCrimson,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textMuted,
            shape: const StadiumBorder(),
          ),
          child: const Text('Đóng'),
        ),
        ElevatedButton(
          key: const Key('btn_confirm_cancel_order'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isLevel3 ? AppColors.ctaTerracotta : AppColors.priceCrimson,
            foregroundColor: AppColors.textLight,
            shape: const StadiumBorder(),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: _isSubmitting
              ? null
              : () async {
                  String finalReason = _selectedReason;
                  if (_selectedReason == 'Lý do khác' || isLevel3) {
                    final text = _reasonController.text.trim();
                    if (text.isEmpty && isLevel3) {
                      setState(() => _errorMessage =
                          'Vui lòng nhập lý do xin hủy chi tiết.');
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
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(isLevel3 ? 'Gửi yêu cầu' : 'Xác nhận hủy'),
        ),
      ],
    );
  }
}
