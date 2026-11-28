import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/state/base_view_model.dart';
import '../models/order_model.dart';
import '../repositories/order_fulfillment_repository.dart';

/// ViewModel managing Buyer Purchases list, detail, 3-tier cancellation, and delivery confirmation (M-OR-02..05).
class BuyerOrderViewModel extends BaseViewModel<PaginatedResponse<OrderModel>> {
  final OrderFulfillmentRepository repository;

  String currentTab = 'ALL';
  OrderModel? selectedOrder;
  bool isActionLoading = false;
  String? actionErrorMessage;

  BuyerOrderViewModel({required this.repository});

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      if (error.error is ApiException) {
        return (error.error as ApiException).message;
      }
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return error.message ?? 'Không thể kết nối đến máy chủ.';
    }
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }

  /// Loads purchases according to current tab filter
  Future<void> loadPurchases({String? tab, bool refresh = false}) async {
    if (tab != null) {
      currentTab = tab;
    }

    await runCatching(
      () async {
        final statusFilter = currentTab == 'ALL' ? null : currentTab;
        return await repository.fetchMyPurchases(status: statusFilter, page: 1);
      },
      isEmpty: (res) => res.items.isEmpty,
      emptyMessage: 'Bạn chưa có đơn mua nào trong mục này.',
    );
  }

  /// Changes active tab filter and reloads orders
  void switchTab(String newTab) {
    if (currentTab == newTab) return;
    currentTab = newTab;
    notifyListeners();
    loadPurchases(tab: newTab);
  }

  /// Loads full detail of a specific purchase order
  Future<OrderModel?> loadOrderDetail(int orderId) async {
    if (selectedOrder != null && selectedOrder!.id != orderId) {
      selectedOrder = null;
    }
    isActionLoading = true;
    actionErrorMessage = null;
    notifyListeners();

    try {
      final order = await repository.fetchOrderDetail(orderId);
      selectedOrder = order;
      _updateOrderInList(order);
      isActionLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      isActionLoading = false;
      actionErrorMessage =
          'Không thể tải chi tiết đơn hàng: ${_extractErrorMessage(e)}';
      notifyListeners();
      return null;
    }
  }

  /// Cancels order or requests cancellation (DEC-06 / M-OR-04)
  Future<OrderModel?> submitCancelOrder(
    int orderId, {
    required String reason,
  }) async {
    isActionLoading = true;
    actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.cancelOrder(orderId, reason: reason);
      selectedOrder = updated;
      _updateOrderInList(updated);
      isActionLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      isActionLoading = false;
      actionErrorMessage =
          'Không thể hủy đơn hàng: ${_extractErrorMessage(e)}';
      notifyListeners();
      return null;
    }
  }

  /// Withdraws pending cancel request in PREPARING status
  Future<OrderModel?> withdrawCancel(int orderId) async {
    isActionLoading = true;
    actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.withdrawCancelRequest(orderId);
      selectedOrder = updated;
      _updateOrderInList(updated);
      isActionLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      isActionLoading = false;
      actionErrorMessage =
          'Không thể rút yêu cầu hủy: ${_extractErrorMessage(e)}';
      notifyListeners();
      return null;
    }
  }

  /// Confirms delivery and releases 100% item_subtotal into Seller Wallet (DEC-04 / OF-05)
  Future<OrderModel?> confirmDelivery(int orderId) async {
    isActionLoading = true;
    actionErrorMessage = null;
    notifyListeners();

    try {
      final completed = await repository.confirmDeliveryAndReleaseEscrow(
        orderId,
      );
      selectedOrder = completed;
      _updateOrderInList(completed);
      isActionLoading = false;
      notifyListeners();
      return completed;
    } catch (e) {
      isActionLoading = false;
      actionErrorMessage =
          'Không thể xác nhận nhận hàng: ${_extractErrorMessage(e)}';
      notifyListeners();
      return null;
    }
  }

  void _updateOrderInList(OrderModel updated) {
    final current = state.data;
    if (current == null) return;

    final updatedItems = current.items.map((o) {
      return o.id == updated.id ? updated : o;
    }).toList();

    setSuccess(PaginatedResponse(
      items: updatedItems,
      meta: current.meta,
    ));
  }
}

/// Riverpod provider for BuyerOrderViewModel
final buyerOrderViewModelProvider = ChangeNotifierProvider.autoDispose<BuyerOrderViewModel>((ref) {
  final repo = ref.watch(orderFulfillmentRepositoryProvider);
  return BuyerOrderViewModel(repository: repo);
});
