import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/state/base_view_model.dart';
import '../models/order_model.dart';
import '../repositories/order_fulfillment_repository.dart';

/// ViewModel managing Seller Order Fulfillment pipeline, shipment updates, and cancel requests (M-SL-05..07).
class SellerOrderViewModel extends BaseViewModel<PaginatedResponse<OrderModel>> {
  final OrderFulfillmentRepository repository;

  String currentTab = 'ALL';
  OrderModel? selectedOrder;
  bool isActionLoading = false;
  String? actionErrorMessage;

  SellerOrderViewModel({required this.repository});

  /// Loads seller store orders according to tab filter
  Future<void> loadSellerOrders({String? tab, bool refresh = false}) async {
    if (tab != null) {
      currentTab = tab;
    }

    await runCatching(
      () async {
        final statusFilter = currentTab == 'ALL' ? null : currentTab;
        return await repository.fetchSellerOrders(status: statusFilter, page: 1);
      },
      isEmpty: (res) => res.items.isEmpty,
      emptyMessage: 'Tiệm của bạn chưa có đơn bán nào trong mục này.',
    );
  }

  /// Switches active tab in seller orders
  void switchTab(String newTab) {
    if (currentTab == newTab) return;
    currentTab = newTab;
    notifyListeners();
    loadSellerOrders(tab: newTab);
  }

  /// Loads full details of a specific seller order
  Future<OrderModel?> loadOrderDetail(int orderId) async {
    isActionLoading = true;
    actionErrorMessage = null;
    notifyListeners();

    try {
      final order = await repository.fetchOrderDetail(orderId);
      selectedOrder = order;
      isActionLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      isActionLoading = false;
      actionErrorMessage = 'Không thể tải chi tiết đơn bán: $e';
      notifyListeners();
      return null;
    }
  }

  /// Transitions order from PAID -> PREPARING (M-SL-06)
  Future<OrderModel?> markPreparing(int orderId) async {
    isActionLoading = true;
    actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.markOrderPreparing(orderId);
      selectedOrder = updated;
      _updateOrderInList(updated);
      isActionLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      isActionLoading = false;
      actionErrorMessage = 'Lỗi chuyển trạng thái chuẩn bị: $e';
      notifyListeners();
      return null;
    }
  }

  /// Transitions order from PREPARING -> SHIPPED with carrier & tracking code (M-SL-07)
  Future<OrderModel?> shipOrder(
    int orderId, {
    required String carrierName,
    required String trackingCode,
    String? shippingNote,
  }) async {
    if (carrierName.trim().isEmpty || trackingCode.trim().isEmpty) {
      actionErrorMessage = 'Vui lòng chọn đơn vị vận chuyển và nhập mã vận đơn.';
      notifyListeners();
      return null;
    }

    isActionLoading = true;
    actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.shipOrder(
        orderId,
        carrierName: carrierName,
        trackingCode: trackingCode,
        shippingNote: shippingNote,
      );
      selectedOrder = updated;
      _updateOrderInList(updated);
      isActionLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      isActionLoading = false;
      actionErrorMessage = 'Lỗi cập nhật vận đơn: $e';
      notifyListeners();
      return null;
    }
  }

  /// Transitions order from SHIPPED -> DELIVERED (M-SL-06 / OF-04)
  Future<OrderModel?> markDelivered(int orderId) async {
    isActionLoading = true;
    actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.markOrderDelivered(orderId);
      selectedOrder = updated;
      _updateOrderInList(updated);
      isActionLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      isActionLoading = false;
      actionErrorMessage = 'Lỗi xác nhận giao hàng: $e';
      notifyListeners();
      return null;
    }
  }

  /// Seller responds to buyer's cancellation request (APPROVE or REJECT) (DEC-06 / DEC-07)
  Future<OrderModel?> respondCancelRequest(
    int orderId, {
    required String action, // 'APPROVE' or 'REJECT'
    String? reason,
  }) async {
    isActionLoading = true;
    actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.respondToCancelRequest(
        orderId,
        action: action,
        reason: reason,
      );
      selectedOrder = updated;
      _updateOrderInList(updated);
      isActionLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      isActionLoading = false;
      actionErrorMessage = 'Lỗi phản hồi yêu cầu hủy: $e';
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

/// Riverpod provider for SellerOrderViewModel
final sellerOrderViewModelProvider = ChangeNotifierProvider.autoDispose<SellerOrderViewModel>((ref) {
  final repo = ref.watch(orderFulfillmentRepositoryProvider);
  return SellerOrderViewModel(repository: repo);
});
