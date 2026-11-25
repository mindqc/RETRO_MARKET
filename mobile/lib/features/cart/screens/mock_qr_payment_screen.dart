import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/services/server_time_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/widgets/server_countdown_timer.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/payment_session_model.dart';
import '../viewmodels/payment_view_model.dart';

/// M-PM-01: Mock QR Payment Screen.
/// Locally generated demo QR. Not VietQR and not for real transfers.
class MockQrPaymentScreen extends ConsumerStatefulWidget {
  final int paymentId;
  final PaymentSessionModel? initialSession;

  const MockQrPaymentScreen({
    super.key,
    required this.paymentId,
    this.initialSession,
  });

  @override
  ConsumerState<MockQrPaymentScreen> createState() =>
      _MockQrPaymentScreenState();
}

class _MockQrPaymentScreenState extends ConsumerState<MockQrPaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(paymentViewModelProvider);
      if (widget.initialSession != null) {
        vm.setSuccess(widget.initialSession!);
      } else {
        vm.loadPayment(widget.paymentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(paymentViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Thanh toán đơn hàng'),
        elevation: 0,
        backgroundColor: AppColors.backgroundCream,
        foregroundColor: AppColors.textCharcoal,
      ),
      body: SafeArea(
        child: vm.state.when(
          initial: () => const _LoadingView(),
          loading: () => const _LoadingView(),
          error: (msg, err) => RetroErrorRetryView(
            errorMessage: msg,
            onRetry: () => ref
                .read(paymentViewModelProvider)
                .loadPayment(widget.paymentId),
          ),
          empty: (msg) => RetroEmptyStateView(
            title: 'Không tìm thấy phiên',
            message: msg ?? 'Không tìm thấy thông tin phiên thanh toán.',
            actionLabel: 'Quay lại',
            onAction: () => context.pop(),
          ),
          success: (session) => _buildPaymentBody(session, vm),
        ),
      ),
    );
  }

  Widget _buildPaymentBody(PaymentSessionModel session, PaymentViewModel vm) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceLg,
        DesignTokens.spaceSm,
        DesignTokens.spaceLg,
        DesignTokens.space3xl,
      ),
      children: [
        _buildPaymentSummary(session),
        const SizedBox(height: DesignTokens.spaceLg),
        _buildQrPanel(session),
        const SizedBox(height: DesignTokens.spaceLg),
        _buildTransferDetails(session),
        const SizedBox(height: DesignTokens.spaceLg),
        _buildDemoPanel(session, vm),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Payment summary
  // ---------------------------------------------------------------------------

  Widget _buildPaymentSummary(PaymentSessionModel session) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.primaryForestGreen,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFDCE9D9),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Đơn hàng đang chờ thanh toán',
                  style: TextStyle(
                    color: Color(0xFFDCE9D9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5B4),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    color: Color(0xFF77500C),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          const Text(
            'Tổng thanh toán',
            style: TextStyle(color: Color(0xFFDCE9D9), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            VndFormatter.format(session.amount),
            style: AppTypography.headingLarge.copyWith(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          Container(
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFFDCE9D9),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.orderCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                color: Color(0xFFFFD98A),
                size: 19,
              ),
              const SizedBox(width: 7),
              const Text(
                'Mã hết hạn sau',
                style: TextStyle(color: Color(0xFFDCE9D9), fontSize: 12),
              ),
              const Spacer(),
              ServerCountdownTimer(
                endsAt: session.paymentExpiresAt,
                customClock: () => ServerTimeService.instance.now(),
                onExpired: () {
                  if (mounted) {
                    context.pushReplacement(
                      AppRoutes.paymentFailurePath(session.paymentId),
                      extra: session.copyWith(paymentStatus: 'EXPIRED'),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QR panel
  // ---------------------------------------------------------------------------

  Widget _buildQrPanel(PaymentSessionModel session) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.primaryTerracotta,
                size: 23,
              ),
              const SizedBox(width: 8),
              Text(
                'QUÉT MÃ QR',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.textCharcoal,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Mã thanh toán dành riêng cho đơn hàng này',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(fontSize: 12),
          ),
          const SizedBox(height: DesignTokens.spaceLg),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              border: Border.all(color: AppColors.primaryForestGreen, width: 2),
            ),
            child: QrImageView(
              data: session.qrDisplayData,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),

          const SizedBox(height: DesignTokens.spaceLg),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5DE),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: const Color(0xFFFFDF9B)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF946200),
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'QR mô phỏng RETRO MARKET. Không phải VietQR và không dùng để chuyển khoản thật.',
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFF795300),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Transfer details
  // ---------------------------------------------------------------------------

  Widget _buildTransferDetails(PaymentSessionModel session) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: AppColors.primaryVintageBrown,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Thông tin thanh toán', style: AppTypography.headingSmall),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          const Divider(color: AppColors.borderSubtle),
          _buildCopyRow(label: 'Mã thanh toán', value: session.paymentCode),
          const Divider(color: AppColors.borderSubtle),
          _buildCopyRow(label: 'Mã đơn hàng', value: session.orderCode),
          const Divider(color: AppColors.borderSubtle),
          _buildCopyRow(
            label: 'Nội dung mô phỏng',
            value: session.transferContent,
            highlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCopyRow({
    required String label,
    required String value,
    bool highlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: highlighted
                        ? AppColors.primaryTerracotta
                        : AppColors.textCharcoal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép nội dung chuyển khoản!'),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: AppColors.primaryVintageBrown,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Demo controls
  // ---------------------------------------------------------------------------

  Widget _buildDemoPanel(PaymentSessionModel session, PaymentViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D8),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: const Color(0xFFE9C86B), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5A6),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: const Icon(
                  Icons.science_outlined,
                  color: Color(0xFF946200),
                  size: 20,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEMO MODE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.8,
                        color: Color(0xFF7A5100),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'CHẾ ĐỘ TRÌNH DIỄN • THANH TOÁN MÔ PHỎNG',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A5100),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Các nút bên dưới dùng để mô phỏng kết quả thanh toán trong buổi trình diễn. Không phát sinh giao dịch hoặc dòng tiền thật.',
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFF7A5100),
            ),
          ),

          if (vm.simulationMessage != null) ...[
            const SizedBox(height: DesignTokens.spaceMd),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.spaceMd),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8E8),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Text(
                vm.simulationMessage!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.statusDanger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const SizedBox(height: DesignTokens.spaceLg),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              key: const Key('btn_simulate_payment_success'),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text(
                'Mô phỏng thanh toán thành công',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryForestGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryForestGreen
                    .withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
              ),
              onPressed: vm.isSimulating
                  ? null
                  : () async {
                      final updated = await vm.simulateSuccess(
                        session.paymentId,
                      );
                      if (updated != null && mounted) {
                        context.pushReplacement(
                          AppRoutes.paymentSuccessPath(session.paymentId),
                          extra: updated,
                        );
                      }
                    },
            ),
          ),

          const SizedBox(height: DesignTokens.spaceSm),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              key: const Key('btn_simulate_payment_failure'),
              icon: const Icon(Icons.error_outline_rounded, size: 18),
              label: const Text(
                'Mô phỏng thanh toán thất bại',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statusDanger,
                side: const BorderSide(
                  color: AppColors.statusDanger,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
              ),
              onPressed: vm.isSimulating
                  ? null
                  : () async {
                      final failed = await vm.simulateFailure(
                        session.paymentId,
                        reason: 'Giao dịch bị từ chối bởi ngân hàng mô phỏng.',
                      );
                      if (failed != null && mounted) {
                        context.pushReplacement(
                          AppRoutes.paymentFailurePath(session.paymentId),
                          extra: failed,
                        );
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryTerracotta),
    );
  }
}
