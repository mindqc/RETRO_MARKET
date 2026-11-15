import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../../../core/widgets/status_pill_badge.dart';
import '../models/dispute_evidence_model.dart';
import '../models/dispute_model.dart';
import '../viewmodels/dispute_view_model.dart';

/// M-DP-02: Dispute Case Detail Screen managing 2-way counter evidence thread
/// and official Admin resolution verdict (DEC-03 / DEC-07 / BR-DP-02).
class DisputeDetailScreen extends ConsumerStatefulWidget {
  final int disputeId;
  final DisputeModel? initialDispute;

  const DisputeDetailScreen({
    super.key,
    required this.disputeId,
    this.initialDispute,
  });

  @override
  ConsumerState<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends ConsumerState<DisputeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(disputeViewModelProvider).loadDisputeDetail(widget.disputeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(disputeViewModelProvider);
    final dispute = vm.state.data ?? widget.initialDispute;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: Text(dispute != null ? 'Hồ sơ khiếu nại ${dispute.disputeCode}' : 'Chi tiết khiếu nại'),
        elevation: 0,
      ),
      bottomNavigationBar: dispute != null && !dispute.isResolved
          ? _buildBottomActionBar(dispute)
          : null,
      body: SafeArea(
        child: vm.state.when(
          initial: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
          loading: () => dispute != null
              ? _buildDisputeBody(dispute)
              : const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
          error: (msg, err) => RetroErrorRetryView(
            errorMessage: msg,
            onRetry: () => ref.read(disputeViewModelProvider).loadDisputeDetail(widget.disputeId),
          ),
          empty: (msg) => RetroEmptyStateView(
            title: 'Không tìm thấy hồ sơ',
            message: msg ?? 'Không tìm thấy thông tin khiếu nại.',
            actionLabel: 'Quay lại',
            onAction: () => context.pop(),
          ),
          success: (data) => _buildDisputeBody(data),
        ),
      ),
    );
  }

  Widget _buildDisputeBody(DisputeModel dispute) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      children: [
        // 1. Dispute Status & Escrow Frozen Card (DEC-03)
        _buildStatusHeaderCard(dispute),

        const SizedBox(height: DesignTokens.spaceMd),

        // 2. Admin Verdict Card (if Resolved)
        if (dispute.isResolved || dispute.adminVerdict != null) _buildAdminVerdictCard(dispute),

        // 3. Initial Buyer Claim Card
        _buildBuyerInitialClaimCard(dispute),

        const SizedBox(height: DesignTokens.spaceLg),

        // 4. Two-Way Counter Evidence Thread Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tiến trình đối chất & Bằng chứng',
              style: AppTypography.headingSmall.copyWith(fontSize: 16),
            ),
            Text(
              '${dispute.evidences.length} phản hồi',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceMd),

        // 5. Evidence Timeline Cards
        if (dispute.evidences.isEmpty)
          Container(
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: AppColors.borderWarm),
            ),
            child: const Center(
              child: Text('Chưa có lời giải trình hoặc chứng cứ bổ sung nào.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
          )
        else
          ...dispute.evidences.map((ev) => _buildEvidenceCard(ev)),

        const SizedBox(height: 80), // Padding for bottom sticky bar
      ],
    );
  }

  Widget _buildStatusHeaderCard(DisputeModel dispute) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mã khiếu nại: ${dispute.disputeCode}',
                style: AppTypography.headingSmall.copyWith(fontSize: 14),
              ),
              StatusPillBadge(status: dispute.status, isCompact: true),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 10),

          // Escrow Frozen Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              border: Border.all(color: const Color(0xFFFFEEBA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, color: Color(0xFF856404), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tiền ký quỹ đang đóng băng (FROZEN):',
                        style: TextStyle(fontSize: 11, color: Color(0xFF856404)),
                      ),
                      Text(
                        VndFormatter.format(dispute.escrowFrozenAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF856404)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminVerdictCard(DisputeModel dispute) {
    String verdictTitle = 'Phán quyết của Quản trị viên';
    Color bannerColor = AppColors.secondaryPineGreen;

    if (dispute.adminVerdict == 'FULL_REFUND_TO_BUYER') {
      verdictTitle = 'Chấp thuận Hoàn tiền 100% cho Người mua';
      bannerColor = AppColors.secondaryPineGreen;
    } else if (dispute.adminVerdict == 'RELEASE_TO_SELLER') {
      verdictTitle = 'Bác bỏ khiếu nại – Giải ngân cho Tiệm bán';
      bannerColor = AppColors.primaryTerracotta;
    } else if (dispute.adminVerdict == 'PARTIAL_REFUND') {
      verdictTitle = 'Hòa giải – Hoàn tiền một phần';
      bannerColor = AppColors.statusWarning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: bannerColor.withAlpha(20),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: bannerColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, color: bannerColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  verdictTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: bannerColor),
                ),
              ),
            ],
          ),
          if (dispute.refundAmount != null && dispute.refundAmount! > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Số tiền hoàn trả: ${VndFormatter.format(dispute.refundAmount!)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: bannerColor),
            ),
          ],
          if (dispute.adminResolutionNote != null) ...[
            const SizedBox(height: 6),
            Text(
              'Căn cứ phân xử: "${dispute.adminResolutionNote!}"',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textCharcoal),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBuyerInitialClaimCard(DisputeModel dispute) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.statusDanger, size: 18),
              const SizedBox(width: 6),
              Text(
                'Lý do: ${dispute.reasonCategoryLabel}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dispute.description,
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(DisputeEvidenceModel evidence) {
    Color roleBadgeColor = AppColors.primaryTerracotta;
    String roleLabel = 'Người mua';

    if (evidence.isSellerCounterProof) {
      roleBadgeColor = AppColors.secondaryPineGreen;
      roleLabel = 'Chủ tiệm bán';
    } else if (evidence.isStaffNote) {
      roleBadgeColor = AppColors.statusWarning;
      roleLabel = 'Admin izithrift';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleBadgeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: roleBadgeColor),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                evidence.uploaderName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              if (evidence.createdAt != null)
                Text(
                  evidence.createdAt!.toLocal().toString().substring(0, 16),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            evidence.messageNote,
            style: AppTypography.bodySmall,
          ),
          if (evidence.attachmentUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: evidence.attachmentUrls.map((url) {
                return Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    border: Border.all(color: AppColors.borderWarm),
                    color: AppColors.surfaceWarm,
                  ),
                  child: const Center(child: Icon(Icons.image, size: 20, color: AppColors.secondaryPineGreen)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(DisputeModel dispute) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      color: AppColors.surfaceCard,
      child: ElevatedButton.icon(
        key: const Key('btn_submit_counter_evidence'),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Nộp bổ sung chứng cứ / Giải trình', style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryPineGreen,
          foregroundColor: AppColors.textLight,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () => context.push(AppRoutes.submitCounterEvidencePath(dispute.id)),
      ),
    );
  }
}
