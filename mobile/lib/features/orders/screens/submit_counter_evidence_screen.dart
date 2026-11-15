import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../viewmodels/dispute_view_model.dart';

/// M-DP-03: Submit Counter-Evidence & Clarification Screen.
class SubmitCounterEvidenceScreen extends ConsumerStatefulWidget {
  final int disputeId;

  const SubmitCounterEvidenceScreen({
    super.key,
    required this.disputeId,
  });

  @override
  ConsumerState<SubmitCounterEvidenceScreen> createState() => _SubmitCounterEvidenceScreenState();
}

class _SubmitCounterEvidenceScreenState extends ConsumerState<SubmitCounterEvidenceScreen> {
  final TextEditingController _noteController = TextEditingController();
  final List<String> _attachmentUrls = [];
  String _selectedRole = 'SELLER_COUNTER_PROOF';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(disputeViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Nộp chứng cứ & Giải trình'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice Card
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceMd),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF5EE),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: const Color(0xFFBCE3C6)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.balance, color: AppColors.secondaryPineGreen, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chứng cứ và lời giải trình của bạn sẽ được chuyển thẳng đến Ban Quản trị izithrift và đối phương trong phiên đối chất minh bạch.',
                        style: TextStyle(fontSize: 12, color: AppColors.secondaryPineGreen, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: DesignTokens.spaceLg),

              const Text('Vai trò gửi chứng cứ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
                ),
                items: const [
                  DropdownMenuItem(value: 'SELLER_COUNTER_PROOF', child: Text('Chủ tiệm bán (Giải trình & Bác bỏ)')),
                  DropdownMenuItem(value: 'BUYER_PROOF', child: Text('Người mua (Bổ sung chứng cứ làm rõ)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),

              const SizedBox(height: DesignTokens.spaceMd),

              const Text('Nội dung giải trình / Ghi chú chứng cứ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                key: const Key('input_counter_evidence_note'),
                controller: _noteController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Nhập chi tiết quá trình đóng gói, mã vận đơn, video kiểm hàng hoặc phản hồi khiếu nại...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
                ),
              ),

              const SizedBox(height: DesignTokens.spaceMd),

              // Photos upload
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ảnh / Video đối chứng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                      key: const Key('btn_add_counter_photo'),
                      onTap: () {
                        setState(() {
                          _attachmentUrls.add('https://images.unsplash.com/photo-counter-${_attachmentUrls.length + 1}.jpg');
                        });
                      },
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                          border: Border.all(color: AppColors.borderWarm),
                          color: Colors.white,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo_outlined, size: 20, color: AppColors.secondaryPineGreen),
                            SizedBox(height: 2),
                            Text('+ Thêm', style: TextStyle(fontSize: 10, color: AppColors.secondaryPineGreen)),
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

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  key: const Key('btn_confirm_submit_counter_evidence'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryPineGreen,
                    foregroundColor: AppColors.textLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
                  ),
                  onPressed: vm.isSubmitting
                      ? null
                      : () async {
                          final ev = await vm.submitEvidence(
                            disputeId: widget.disputeId,
                            messageNote: _noteController.text,
                            evidenceType: _selectedRole,
                            attachmentUrls: _attachmentUrls,
                          );

                          if (!context.mounted) return;

                          if (ev != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã nộp chứng cứ đối chất thành công!')),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                  child: vm.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Gửi chứng cứ lên hệ thống', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
