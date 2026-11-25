import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/retro_design_primitives.dart';
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
  ConsumerState<DisputeDetailScreen> createState() =>
      _DisputeDetailScreenState();
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
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          dispute != null
              ? 'Hồ sơ khiếu nại ${dispute.disputeCode}'
              : 'Chi tiết khiếu nại',
          style: AppTypography.headingMedium.copyWith(fontSize: 18),
        ),
      ),
      bottomNavigationBar: dispute != null && !dispute.isResolved
          ? _buildBottomActionBar(dispute)
          : null,
      body: SafeArea(
        child: vm.state.when(
          initial: () => const Center(
            child: CircularProgressIndicator(color: AppColors.pineDeep),
          ),
          loading: () => dispute != null
              ? _buildDisputeBody(dispute)
              : const Center(
                  child: CircularProgressIndicator(color: AppColors.pineDeep),
                ),
          error: (msg, err) => RetroErrorRetryView(
            errorMessage: msg,
            onRetry: () => ref
                .read(disputeViewModelProvider)
                .loadDisputeDetail(widget.disputeId),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // 1. Dispute Status & Escrow Frozen Spotlight Card (DEC-03)
        _buildStatusHeaderCard(dispute),
        const SizedBox(height: 14),

        // 2. Admin Verdict Card (if Resolved)
        if (dispute.isResolved || dispute.adminVerdict != null)
          _buildAdminVerdictCard(dispute),

        // 3. Initial Buyer Claim Card
        _buildBuyerInitialClaimCard(dispute),
        const SizedBox(height: 20),

        // 4. Two-Way Counter Evidence Thread Header
        Row(
          children: [
            const Expanded(
              child: RetroSectionHeader(
                title: 'Tiến trình đối chất & Bằng chứng',
                icon: Icons.forum_outlined,
                iconColor: AppColors.pineDeep,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.creamBadgeSoft,
                borderRadius: DesignTokens.borderRadiusFull,
                border: Border.all(color: AppColors.creamBadgeBorder),
              ),
              child: Text(
                '${dispute.evidences.length} phản hồi',
                style: AppTypography.caption.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.creamBadgeText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 5. Evidence Timeline Cards
        if (dispute.evidences.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceSection,
              borderRadius: DesignTokens.borderRadiusLg,
              border: Border.all(color: AppColors.borderWarm),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
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
                    Icons.inventory_2_outlined,
                    color: AppColors.pineDeep,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Chưa có lời giải trình hoặc chứng cứ bổ sung nào.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          )
        else
          ...dispute.evidences.map(_buildEvidenceCard),
      ],
    );
  }

  Widget _buildStatusHeaderCard(DisputeModel dispute) {
    return RetroPineSpotlightContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mã khiếu nại: ${dispute.disputeCode}',
                  style: AppTypography.headingSmall.copyWith(
                    fontSize: 15,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusPillBadge(status: dispute.status, isCompact: true),
            ],
          ),
          const SizedBox(height: 12),
          // Escrow Frozen Banner (DEC-03)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.creamBadgeSoft,
              borderRadius: DesignTokens.borderRadiusMd,
              border: Border.all(color: AppColors.creamBadgeBorder),
            ),
            child: Row(
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
                    Icons.lock_rounded,
                    color: AppColors.creamBadgeText,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiền ký quỹ đang đóng băng (FROZEN):',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11.5,
                          color: AppColors.creamBadgeText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        VndFormatter.format(dispute.escrowFrozenAmount),
                        style: AppTypography.priceDisplay.copyWith(
                          fontSize: 17,
                          color: AppColors.priceCrimson,
                        ),
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
    Color bannerColor = AppColors.verifiedLeaf;
    Color bgColor = AppColors.verifiedLeafBg;

    if (dispute.adminVerdict == 'FULL_REFUND_TO_BUYER') {
      verdictTitle = 'Chấp thuận Hoàn tiền 100% cho Người mua';
      bannerColor = AppColors.verifiedLeaf;
      bgColor = AppColors.verifiedLeafBg;
    } else if (dispute.adminVerdict == 'RELEASE_TO_SELLER') {
      verdictTitle = 'Bác bỏ khiếu nại – Giải ngân cho Tiệm bán';
      bannerColor = AppColors.ctaTerracotta;
      bgColor = AppColors.priceCrimsonSoft;
    } else if (dispute.adminVerdict == 'PARTIAL_REFUND') {
      verdictTitle = 'Hòa giải – Hoàn tiền một phần';
      bannerColor = AppColors.creamBadgeText;
      bgColor = AppColors.creamBadgeSoft;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(color: bannerColor.withValues(alpha: 0.45), width: 1.4),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceCard,
                  border: Border.all(color: bannerColor.withValues(alpha: 0.35)),
                ),
                child: Icon(Icons.gavel_rounded, color: bannerColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  verdictTitle,
                  style: AppTypography.headingSmall.copyWith(
                    fontSize: 14.5,
                    color: bannerColor,
                  ),
                ),
              ),
            ],
          ),
          if (dispute.refundAmount != null && dispute.refundAmount! > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: DesignTokens.borderRadiusSm,
              ),
              child: Text(
                'Số tiền hoàn trả: ${VndFormatter.format(dispute.refundAmount!)}',
                style: AppTypography.labelStrong.copyWith(
                  color: bannerColor,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
          if (dispute.adminResolutionNote != null) ...[
            const SizedBox(height: 8),
            Text(
              'Căn cứ phân xử: "${dispute.adminResolutionNote!}"',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textCharcoal,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBuyerInitialClaimCard(DisputeModel dispute) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.priceCrimsonSoft,
                  borderRadius: DesignTokens.borderRadiusSm,
                  border: Border.all(color: AppColors.priceCrimsonBorder),
                ),
                child: const Icon(
                  Icons.report_problem_outlined,
                  color: AppColors.priceCrimson,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lý do: ${dispute.reasonCategoryLabel}',
                  style: AppTypography.headingSmall.copyWith(
                    fontSize: 14.5,
                    color: AppColors.textCharcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 10),
          Text(
            dispute.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textCharcoal,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(DisputeEvidenceModel evidence) {
    Color roleBadgeColor = AppColors.ctaTerracotta;
    Color roleBg = AppColors.priceCrimsonSoft;
    String roleLabel = 'Người mua';

    if (evidence.isSellerCounterProof) {
      roleBadgeColor = AppColors.verifiedLeaf;
      roleBg = AppColors.verifiedLeafBg;
      roleLabel = 'Chủ tiệm bán';
    } else if (evidence.isStaffNote) {
      roleBadgeColor = AppColors.creamBadgeText;
      roleBg = AppColors.creamBadgeSoft;
      roleLabel = 'Admin izithrift';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: DesignTokens.borderRadiusFull,
                ),
                child: Text(
                  roleLabel,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: roleBadgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  evidence.uploaderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelStrong.copyWith(fontSize: 13),
                ),
              ),
              if (evidence.createdAt != null) ...[
                const SizedBox(width: 6),
                Text(
                  evidence.createdAt!.toLocal().toString().substring(0, 16),
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            evidence.messageNote,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textCharcoal,
              height: 1.45,
            ),
          ),
          if (evidence.attachmentUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: evidence.attachmentUrls.map((url) {
                return Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: DesignTokens.borderRadiusMd,
                    border: Border.all(color: AppColors.borderWarm),
                    color: AppColors.surfaceWarm,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 22,
                      color: AppColors.pineDeep,
                    ),
                  ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: DesignTokens.bottomNavElevation,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            key: const Key('btn_submit_counter_evidence'),
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 19),
            label: const Text(
              'Nộp bổ sung chứng cứ / Giải trình',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pineDeep,
              foregroundColor: AppColors.textLight,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: () =>
                context.push(AppRoutes.submitCounterEvidencePath(dispute.id)),
          ),
        ),
      ),
    );
  }
}
