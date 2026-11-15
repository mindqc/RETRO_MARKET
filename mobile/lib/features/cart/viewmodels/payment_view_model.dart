import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/base_view_model.dart';
import '../models/payment_session_model.dart';
import '../repositories/cart_checkout_repository.dart';

/// ViewModel managing Mock QR Payment screen, countdown timers, and simulation triggers (M-PM-01..03).
class PaymentViewModel extends BaseViewModel<PaymentSessionModel> {
  final CartCheckoutRepository repository;

  bool isSimulating = false;
  String? simulationMessage;

  PaymentViewModel({required this.repository});

  /// Loads payment details from GET /api/v1/payments/{id}
  Future<void> loadPayment(int paymentId) async {
    await runCatching(
      () => repository.fetchPaymentStatus(paymentId),
      emptyMessage: 'Không tìm thấy thông tin phiên thanh toán.',
    );
  }

  /// Triggers Simulate Success (M-PM-01 -> M-PM-02 / BR-FN-03)
  Future<PaymentSessionModel?> simulateSuccess(int paymentId) async {
    isSimulating = true;
    simulationMessage = null;
    notifyListeners();

    try {
      final res = await repository.simulatePaymentSuccess(paymentId);
      isSimulating = false;
      setSuccess(res);
      return res;
    } catch (e) {
      isSimulating = false;
      simulationMessage = 'Mô phỏng thanh toán thất bại: $e';
      notifyListeners();
      return null;
    }
  }

  /// Triggers Simulate Failure (M-PM-01 -> M-PM-03)
  Future<PaymentSessionModel?> simulateFailure(int paymentId, {String? reason}) async {
    isSimulating = true;
    simulationMessage = null;
    notifyListeners();

    try {
      final res = await repository.simulatePaymentFailure(paymentId, reason: reason);
      isSimulating = false;
      setSuccess(res);
      return res;
    } catch (e) {
      isSimulating = false;
      simulationMessage = 'Lỗi mô phỏng: $e';
      notifyListeners();
      return null;
    }
  }
}

/// Riverpod provider for PaymentViewModel
final paymentViewModelProvider = ChangeNotifierProvider.autoDispose<PaymentViewModel>((ref) {
  final repo = ref.watch(cartCheckoutRepositoryProvider);
  return PaymentViewModel(repository: repo);
});
