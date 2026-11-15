import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../viewmodels/chat_view_model.dart';

/// M-CM-03: Report Violation & Block User Modal
class ReportAndBlockModal extends ConsumerStatefulWidget {
  final int conversationId;
  final int targetUserId;
  final String targetUserName;

  const ReportAndBlockModal({
    super.key,
    required this.conversationId,
    required this.targetUserId,
    required this.targetUserName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int conversationId,
    required int targetUserId,
    required String targetUserName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportAndBlockModal(
        conversationId: conversationId,
        targetUserId: targetUserId,
        targetUserName: targetUserName,
      ),
    );
  }

  @override
  ConsumerState<ReportAndBlockModal> createState() => _ReportAndBlockModalState();
}

class _ReportAndBlockModalState extends ConsumerState<ReportAndBlockModal> {
  String _selectedReason = 'SCAM';
  final TextEditingController _descController = TextEditingController();
  bool _blockConversation = true;
  String? _validationError;

  final Map<String, String> _reasons = {
    'SCAM': 'Lừa đảo / Gian lận thanh toán',
    'COUNTERFEIT': 'Hàng giả / Nhái thương hiệu vintage',
    'ABUSIVE_LANGUAGE': 'Ngôn từ xúc phạm / Quấy rối',
    'SPAM': 'Spam quảng cáo / Nội dung không phù hợp',
  };

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final text = _descController.text.trim();
    if (text.length < 10) {
      setState(() {
        _validationError = 'Mô tả chi tiết vi phạm tối thiểu 10 ký tự';
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    final chatVm = ref.read(chatViewModelProvider);
    final success = await chatVm.reportViolation(
      conversationId: widget.conversationId,
      reasonCategory: _selectedReason,
      description: text,
      blockConversation: _blockConversation,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi báo cáo vi phạm thành công. Đội ngũ kiểm duyệt izithrift sẽ xử lý.'),
            backgroundColor: AppColors.secondaryPineGreen,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _validationError = chatVm.errorMessage ?? 'Không thể gửi báo cáo vi phạm';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final chatVm = ref.watch(chatViewModelProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusXl)),
        ),
        padding: EdgeInsets.fromLTRB(
          DesignTokens.spaceLg,
          DesignTokens.spaceLg,
          DesignTokens.spaceLg,
          DesignTokens.spaceLg + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
                  decoration: BoxDecoration(
                    color: AppColors.borderWarm,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.christmasBerryRed, size: 24),
                  const SizedBox(width: DesignTokens.spaceSm),
                  Expanded(
                    child: Text(
                      'Báo Cáo & Chặn Người Dùng',
                      style: AppTypography.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Đối tượng: ${widget.targetUserName}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: DesignTokens.spaceLg),

              // Reason Category
              Text(
                'LÝ DO VI PHẠM',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textCharcoal,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceSm),

              Material(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    border: Border.all(color: AppColors.borderWarm),
                  ),
                  child: Column(
                    children: _reasons.entries.map((entry) {
                      final isSelected = _selectedReason == entry.key;
                      return RadioListTile<String>(
                        value: entry.key,
                        groupValue: _selectedReason,
                        title: Text(
                          entry.value,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: AppColors.textCharcoal,
                          ),
                        ),
                        activeColor: AppColors.primaryTerracotta,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedReason = val;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceLg),

              // Description input
              Text(
                'MÔ TẢ CHI TIẾT VI PHẠM',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textCharcoal,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              TextField(
                controller: _descController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Cung cấp bằng chứng hoặc bối cảnh cuộc trò chuyện để admin thẩm tra...',
                  hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  contentPadding: const EdgeInsets.all(DesignTokens.spaceMd),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    borderSide: const BorderSide(color: AppColors.borderWarm),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    borderSide: const BorderSide(color: AppColors.borderWarm),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    borderSide: const BorderSide(color: AppColors.primaryTerracotta, width: 1.5),
                  ),
                ),
              ),

              // Block toggle switch
              Container(
                margin: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd),
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceMd,
                  vertical: DesignTokens.spaceSm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: AppColors.borderWarm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chặn người này',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textCharcoal,
                            ),
                          ),
                          Text(
                            'Không cho phép gửi hoặc nhận tin nhắn mới trong cuộc trò chuyện này.',
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _blockConversation,
                      activeColor: AppColors.christmasBerryRed,
                      onChanged: (val) {
                        setState(() {
                          _blockConversation = val;
                        });
                      },
                    ),
                  ],
                ),
              ),

              if (_validationError != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
                  child: Text(
                    _validationError!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.statusDanger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              // Submit CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: chatVm.isReporting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.christmasBerryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                  ),
                  icon: chatVm.isReporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.flag_outlined, size: 20),
                  label: Text(
                    chatVm.isReporting ? 'Đang gửi báo cáo...' : 'Gửi Báo Cáo Vi Phạm',
                    style: AppTypography.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
