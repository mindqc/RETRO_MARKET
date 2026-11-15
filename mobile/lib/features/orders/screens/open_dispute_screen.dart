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
    {'key': 'ITEM_NOT_AS_DESCRIBED', 'label': 'Hàng không đúng mô tả / Khuyết điểm ẩn'},
    {'key': 'COUNTERFEIT_FAKE', 'label': 'Nghi vấn hàng giả, nhái nhãn hiệu'},
    {'key': 'DAMAGED_IN_TRANSIT', 'label': 'Hàng bị hư hỏng / bể vỡ do vận chuyển'},
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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Mở khiếu nại / Trả hàng'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Escrow Freeze Warning Box (DEC-03)
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceMd),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: const Color(0xFFFFEEBA), width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_clock_outlined, color: Color(0xFF856404), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cơ chế Đóng Băng Quỹ Escrow (DEC-03)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF856404)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Khi bạn gửi yêu cầu, toàn bộ tiền đơn hàng sẽ được ĐÓNG BĂNG (FROZEN) tại quỹ Escrow izithrift. Thời hạn tự động giải ngân sẽ tạm dừng cho đến khi hai bên đối chất hoặc Admin phân xử.',
                            style: AppTypography.caption.copyWith(color: const Color(0xFF856404)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: DesignTokens.spaceLg),

              // 2. Reason Category Selection
              const Text('Danh mục lý do khiếu nại:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c['key'], child: Text(c['label']!, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),

              const SizedBox(height: DesignTokens.spaceMd),

              // 3. Description Input (>= 10 chars)
              const Text('Mô tả chi tiết khuyết điểm (tối thiểu 10 ký tự):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                key: const Key('input_dispute_description'),
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Mô tả rõ sai khác so với bài đăng, lỗi rách, ố bẩn hoặc hư hỏng gặp phải...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
                ),
              ),

              const SizedBox(height: DesignTokens.spaceMd),

              // 4. Evidence Upload Section (max 5 images - BR-DP-02)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ảnh chụp bằng chứng (tối đa 5 ảnh - BR-DP-02):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${_attachmentUrls.length}/5', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._attachmentUrls.map((url) => Stack(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                              border: Border.all(color: AppColors.borderWarm),
                              color: AppColors.surfaceWarm,
                            ),
                            child: const Center(child: Icon(Icons.image, color: AppColors.secondaryPineGreen)),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: InkWell(
                              onTap: () => setState(() => _attachmentUrls.remove(url)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )),
                  if (_attachmentUrls.length < 5)
                    InkWell(
                      key: const Key('btn_add_evidence_photo'),
                      onTap: () {
                        setState(() {
                          _attachmentUrls.add('https://images.unsplash.com/photo-evidence-${_attachmentUrls.length + 1}.jpg');
                        });
                      },
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                          border: Border.all(color: AppColors.borderWarm, style: BorderStyle.solid),
                          color: Colors.white,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo_outlined, size: 20, color: AppColors.primaryTerracotta),
                            SizedBox(height: 2),
                            Text('+ Thêm', style: TextStyle(fontSize: 10, color: AppColors.primaryTerracotta)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              if (vm.submitErrorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  vm.submitErrorMessage!,
                  style: const TextStyle(color: AppColors.statusDanger, fontSize: 13),
                ),
              ],

              const SizedBox(height: DesignTokens.spaceXl),

              // 5. Submit CTA
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  key: const Key('btn_submit_dispute'),
                  icon: const Icon(Icons.shield_outlined, size: 20),
                  label: const Text('Gửi yêu cầu khiếu nại & Khóa Escrow', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusDanger,
                    foregroundColor: AppColors.textLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
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
                              const SnackBar(content: Text('Đã mở hồ sơ khiếu nại thành công! Tiền Escrow đã được khóa.')),
                            );
                            try {
                              context.pushReplacement(AppRoutes.disputeDetailPath(dispute.id));
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
