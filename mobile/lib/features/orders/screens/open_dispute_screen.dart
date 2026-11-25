import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../viewmodels/dispute_view_model.dart';

/// M-DP-01: Open Dispute Form Screen (DEC-03 / BR-DP-02).
/// Immediately freezes escrow funds upon successful submission.
class OpenDisputeScreen extends ConsumerStatefulWidget {
  final int orderId;

  const OpenDisputeScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OpenDisputeScreen> createState() => _OpenDisputeScreenState();
}

class _OpenDisputeScreenState extends ConsumerState<OpenDisputeScreen> {
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = 'ITEM_NOT_AS_DESCRIBED';
  final List<String> _attachmentUrls = [];

  static const List<Map<String, String>> _categories = [
    {
      'key': 'ITEM_NOT_AS_DESCRIBED',
      'label': 'Hàng không đúng mô tả / Khuyết điểm ẩn',
    },
    {'key': 'COUNTERFEIT_FAKE', 'label': 'Nghi vấn hàng giả, nhái nhãn hiệu'},
    {
      'key': 'DAMAGED_IN_TRANSIT',
      'label': 'Hàng bị hư hỏng / bể vỡ do vận chuyển',
    },
    {'key': 'ITEM_NOT_RECEIVED', 'label': 'Chưa nhận được kiện hàng'},
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(disputeViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Mở khiếu nại / Trả hàng',
          style: AppTypography.headingMedium.copyWith(fontSize: 19),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Escrow Freeze Warning Box (DEC-03)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.creamBadgeSoft,
                  borderRadius: DesignTokens.borderRadiusLg,
                  border: Border.all(
                    color: AppColors.creamBadgeBorder,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.creamBadgeBg,
                        border: Border.all(color: AppColors.creamBadgeBorder),
                      ),
                      child: const Icon(
                        Icons.lock_clock_outlined,
                        color: AppColors.creamBadgeText,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cơ chế Đóng Băng Quỹ Escrow (DEC-03)',
                            style: AppTypography.labelStrong.copyWith(
                              fontSize: 13.5,
                              color: AppColors.creamBadgeText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Khi bạn gửi yêu cầu, toàn bộ tiền đơn hàng sẽ được ĐÓNG BĂNG (FROZEN) tại quỹ Escrow izithrift. Thời hạn tự động giải ngân sẽ tạm dừng cho đến khi hai bên đối chất hoặc Admin phân xử.',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.creamBadgeText,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Main Dispute Form Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: DesignTokens.borderRadiusBanner,
                  border: Border.all(color: AppColors.borderWarm),
                  boxShadow: DesignTokens.cardElevation,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reason Category Selection
                    Text(
                      'Danh mục lý do khiếu nại:',
                      style: AppTypography.labelStrong.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceWarm,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: DesignTokens.borderRadiusMd,
                          borderSide:
                              const BorderSide(color: AppColors.borderWarm),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: DesignTokens.borderRadiusMd,
                          borderSide:
                              const BorderSide(color: AppColors.borderWarm),
                        ),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                          value: c['key'],
                          child: Text(
                            c['label']!,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 13,
                              color: AppColors.textCharcoal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description Input (>= 10 chars)
                    Text(
                      'Mô tả chi tiết khuyết điểm (tối thiểu 10 ký tự):',
                      style: AppTypography.labelStrong.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('input_dispute_description'),
                      controller: _descController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceWarm,
                        hintText:
                            'Mô tả rõ sai khác so với bài đăng, lỗi rách, ố bẩn hoặc hư hỏng gặp phải...',
                        border: OutlineInputBorder(
                          borderRadius: DesignTokens.borderRadiusMd,
                          borderSide:
                              const BorderSide(color: AppColors.borderWarm),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: DesignTokens.borderRadiusMd,
                          borderSide:
                              const BorderSide(color: AppColors.borderWarm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Evidence Upload Section (max 5 images - BR-DP-02)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Ảnh chụp bằng chứng (tối đa 5 ảnh - BR-DP-02):',
                            style: AppTypography.labelStrong
                                .copyWith(fontSize: 13),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.creamBadgeSoft,
                            borderRadius: DesignTokens.borderRadiusFull,
                          ),
                          child: Text(
                            '${_attachmentUrls.length}/5',
                            style: AppTypography.caption.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.creamBadgeText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ..._attachmentUrls.map(
                          (url) => Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  borderRadius: DesignTokens.borderRadiusMd,
                                  border:
                                      Border.all(color: AppColors.borderWarm),
                                  color: AppColors.surfaceWarm,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: AppColors.pineDeep,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: () => setState(
                                      () => _attachmentUrls.remove(url)),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: AppColors.textCharcoal,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_attachmentUrls.length < 5)
                          InkWell(
                            key: const Key('btn_add_evidence_photo'),
                            borderRadius: DesignTokens.borderRadiusMd,
                            onTap: () {
                              setState(() {
                                _attachmentUrls.add(
                                  'https://images.unsplash.com/photo-evidence-${_attachmentUrls.length + 1}.jpg',
                                );
                              });
                            },
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: DesignTokens.borderRadiusMd,
                                border: Border.all(
                                  color: AppColors.ctaTerracotta
                                      .withValues(alpha: 0.45),
                                ),
                                color: AppColors.priceCrimsonSoft
                                    .withValues(alpha: 0.5),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 20,
                                    color: AppColors.ctaTerracotta,
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    '+ Thêm',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ctaTerracotta,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (vm.submitErrorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.priceCrimsonSoft,
                          borderRadius: DesignTokens.borderRadiusMd,
                          border:
                              Border.all(color: AppColors.priceCrimsonBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: AppColors.priceCrimson,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                vm.submitErrorMessage!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.priceCrimson,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Submit CTA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  key: const Key('btn_submit_dispute'),
                  icon: const Icon(Icons.shield_outlined, size: 20),
                  label: const Text(
                    'Gửi yêu cầu khiếu nại & Khóa Escrow',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.priceCrimson,
                    foregroundColor: AppColors.textLight,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: vm.isSubmitting
                      ? null
                      : () async {
                          final dispute = await vm.openDispute(
                            orderId: widget.orderId,
                            reasonCategory: _selectedCategory,
                            description: _descController.text,
                            attachmentUrls: _attachmentUrls,
                          );

                          if (!context.mounted) return;

                          if (dispute != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Đã mở hồ sơ khiếu nại thành công! Tiền Escrow đã được khóa.',
                                ),
                              ),
                            );
                            try {
                              context.pushReplacement(
                                AppRoutes.disputeDetailPath(dispute.id),
                              );
                            } catch (_) {
                              Navigator.of(context).maybePop();
                            }
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
