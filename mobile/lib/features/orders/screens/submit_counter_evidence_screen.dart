import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../viewmodels/dispute_view_model.dart';

/// M-DP-03: Submit Counter-Evidence & Clarification Screen.
class SubmitCounterEvidenceScreen extends ConsumerStatefulWidget {
  final int disputeId;

  const SubmitCounterEvidenceScreen({super.key, required this.disputeId});

  @override
  ConsumerState<SubmitCounterEvidenceScreen> createState() =>
      _SubmitCounterEvidenceScreenState();
}

class _SubmitCounterEvidenceScreenState
    extends ConsumerState<SubmitCounterEvidenceScreen> {
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
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Nộp chứng cứ & Giải trình',
          style: AppTypography.headingMedium.copyWith(fontSize: 19),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Editorial Mediation Notice Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.verifiedLeafBg,
                  borderRadius: DesignTokens.borderRadiusLg,
                  border: Border.all(
                    color: AppColors.verifiedLeaf.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceCard,
                        border: Border.all(
                          color: AppColors.verifiedLeaf.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.balance_rounded,
                        color: AppColors.verifiedLeaf,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chứng cứ và lời giải trình của bạn sẽ được chuyển thẳng đến Ban Quản trị izithrift và đối phương trong phiên đối chất minh bạch.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12.5,
                          color: AppColors.pineDeep,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Main Form Card
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
                    Text(
                      'Vai trò gửi chứng cứ:',
                      style: AppTypography.labelStrong.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
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
                          borderSide: const BorderSide(
                            color: AppColors.borderWarm,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: DesignTokens.borderRadiusMd,
                          borderSide: const BorderSide(
                            color: AppColors.borderWarm,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'SELLER_COUNTER_PROOF',
                          child: Text(
                            'Chủ tiệm bán (Giải trình & Bác bỏ)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'BUYER_PROOF',
                          child: Text(
                            'Người mua (Bổ sung chứng cứ làm rõ)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nội dung giải trình / Ghi chú chứng cứ:',
                      style: AppTypography.labelStrong.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('input_counter_evidence_note'),
                      controller: _noteController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceWarm,
                        hintText: 'Nhập chi tiết quá trình đóng gói, mã vận đơn, video kiểm hàng hoặc phản hồi khiếu nại...',
                        border: OutlineInputBorder(
                          borderRadius: DesignTokens.borderRadiusMd,
                          borderSide: const BorderSide(
                            color: AppColors.borderWarm,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: DesignTokens.borderRadiusMd,
                          borderSide: const BorderSide(
                            color: AppColors.borderWarm,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Photos upload
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ảnh / Video đối chứng:',
                          style: AppTypography.labelStrong.copyWith(
                            fontSize: 13,
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
                                  border: Border.all(
                                    color: AppColors.borderWarm,
                                  ),
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
                                    () => _attachmentUrls.remove(url),
                                  ),
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
                            key: const Key('btn_add_counter_photo'),
                            borderRadius: DesignTokens.borderRadiusMd,
                            onTap: () {
                              setState(() {
                                _attachmentUrls.add(
                                  'https://images.unsplash.com/photo-counter-${_attachmentUrls.length + 1}.jpg',
                                );
                              });
                            },
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: DesignTokens.borderRadiusMd,
                                border: Border.all(
                                  color: AppColors.verifiedLeaf.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                                color: AppColors.verifiedLeafBg.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 20,
                                    color: AppColors.pineDeep,
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    '+ Thêm',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.pineDeep,
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
                          border: Border.all(
                            color: AppColors.priceCrimsonBorder,
                          ),
                        ),
                        child: Text(
                          vm.submitErrorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.priceCrimson,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.canvasParchment),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              key: const Key('btn_confirm_submit_counter_evidence'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pineDeep,
                foregroundColor: AppColors.textLight,
                shape: const StadiumBorder(),
                elevation: 0,
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
                          const SnackBar(
                            content: Text(
                              'Đã nộp chứng cứ đối chất thành công!',
                            ),
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
              child: vm.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Gửi chứng cứ lên hệ thống',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
