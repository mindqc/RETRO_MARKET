import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// M-PM-01: Mock QR Payment Screen
/// Renders simulated VietQR frame, transfer content, countdown timer to payment expiration (BR-AU-01),
/// and prominent Demo Mode simulation triggers for thesis evaluation.
class MockQrPaymentScreen extends ConsumerStatefulWidget {
  final int paymentId;
  final PaymentSessionModel? initialSession;

  const MockQrPaymentScreen({
    super.key,
    required this.paymentId,
    this.initialSession,
  });

  @override
  ConsumerState<MockQrPaymentScreen> createState() => _MockQrPaymentScreenState();
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
      ),
      body: SafeArea(
        child: vm.state.when(
          initial: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTerracotta)),
          error: (msg, err) => RetroErrorRetryView(
            errorMessage: msg,
            onRetry: () => ref.read(paymentViewModelProvider).loadPayment(widget.paymentId),
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
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      children: [
        // 1. Amount & Countdown Timer Header Card
        _buildAmountCountdownCard(session),

        const SizedBox(height: DesignTokens.spaceLg),

        // 2. Simulated VietQR Box
        _buildQrBox(session),

        const SizedBox(height: DesignTokens.spaceLg),

        // 3. Bank Transfer Details
        _buildTransferDetailsCard(session),

        const SizedBox(height: DesignTokens.spaceXl),

        // 4. Demo Mode Simulation Section (Mandatory for Thesis defense)
        _buildDemoSimulationCard(session, vm),

        const SizedBox(height: DesignTokens.space2xl),
      ],
    );
  }

  Widget _buildAmountCountdownCard(PaymentSessionModel session) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        children: [
          Text(
            'Số tiền cần thanh toán',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            VndFormatter.format(session.amount),
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.primaryTerracotta,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: AppColors.statusDanger),
              const SizedBox(width: 6),
              Text(
                'Mã QR hết hạn sau: ',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textCharcoal),
              ),
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

  Widget _buildQrBox(PaymentSessionModel session) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.qr_code_scanner, color: AppColors.secondaryPineGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'MÃ VIETQR THANH TOÁN KÝ QUỸ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.secondaryPineGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // QR Visual Container
          Container(
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              border: Border.all(color: AppColors.borderWarm, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2, size: 140, color: AppColors.textCharcoal),
                  const SizedBox(height: 4),
                  Text(
                    'izithrift • VietQR',
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Mở ứng dụng Ngân hàng hoặc Ví điện tử để quét mã',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferDetailsCard(PaymentSessionModel session) {
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
          Text('Thông tin chuyển khoản', style: AppTypography.headingSmall.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          _buildInfoRow('Mã thanh toán', session.paymentCode),
          _buildInfoRow('Ngân hàng thụ hưởng', 'VietinBank (ICB) - Mô phỏng'),
          _buildInfoRow('Tên tài khoản', 'IZITHRIFT ESCROW TRUST'),
          _buildInfoRow('Số tài khoản', '10988776655'),
          _buildInfoRow(
            'Nội dung chuyển khoản',
            session.transferContent,
            isCopyable: true,
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isCopyable = false, bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? AppColors.primaryTerracotta : AppColors.textCharcoal,
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép nội dung chuyển khoản!')),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.copy, size: 16, color: AppColors.primaryTerracotta),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoSimulationCard(PaymentSessionModel session, PaymentViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: const Color(0xFFFFE799), width: 1.5),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.developer_mode, color: Color(0xFFB47800), size: 20),
              SizedBox(width: 8),
              Text(
                'Demo Mode • Giả Lập Cổng Thanh Toán QR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF7A5100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Nhấn các nút bên dưới để mô phỏng phản hồi Webhook ngân hàng tức thời phục vụ chấm điểm đồ án:',
            style: AppTypography.caption.copyWith(color: const Color(0xFF7A5100)),
          ),
          const SizedBox(height: 12),

          // Simulate Success Button (Pine green)
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              key: const Key('btn_simulate_payment_success'),
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text(
                '✅ Mô phỏng Thanh toán Thành công',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryPineGreen,
                foregroundColor: AppColors.textLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
              ),
              onPressed: vm.isSimulating
                  ? null
                  : () async {
                      final updated = await vm.simulateSuccess(session.paymentId);
                      if (updated != null && mounted) {
                        context.pushReplacement(
                          AppRoutes.paymentSuccessPath(session.paymentId),
                          extra: updated,
                        );
                      }
                    },
            ),
          ),

          const SizedBox(height: 10),

          // Simulate Failure Button (Muted danger)
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              key: const Key('btn_simulate_payment_failure'),
              icon: const Icon(Icons.error_outline, size: 18),
              label: const Text(
                '❌ Mô phỏng Thanh toán Thất bại',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statusDanger,
                side: const BorderSide(color: AppColors.statusDanger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
              ),
              onPressed: vm.isSimulating
                  ? null
                  : () async {
                      final failed = await vm.simulateFailure(session.paymentId, reason: 'Giao dịch bị từ chối bởi ngân hàng mô phỏng.');
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
