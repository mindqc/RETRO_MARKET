import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/demo/retro_demo_marketplace_store.dart';
import '../../../core/state/base_view_model.dart';
import '../models/seller_product_item_model.dart';
import '../repositories/seller_channel_repository.dart';

/// ViewModel managing 7-state product listings for seller (M-SL-02).
class SellerListingsViewModel extends BaseViewModel<List<SellerProductItemModel>> {
  final SellerChannelRepository repository;
  final RetroDemoMarketplaceStore? demoStore;

  String _selectedStatus = 'ALL';
  int _currentPage = 1;
  bool _hasMore = false;
  final bool _isLoadingMore = false;

  SellerListingsViewModel({
    required this.repository,
    this.demoStore,
  });

  String get selectedStatus => _selectedStatus;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  void setStatusFilter(String status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      loadProducts(refresh: true);
    }
  }

  List<SellerProductItemModel> _demoItemsForCurrentStatus() {
    final localItems = demoStore?.demoSubmittedListings ?? const [];
    if (_selectedStatus == 'ALL') return List<SellerProductItemModel>.from(localItems);
    return localItems.where((item) => item.status == _selectedStatus).toList();
  }

  /// Loads products with optional status filter and pagination
  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    await runCatching(
      () async {
        final localMatches = _demoItemsForCurrentStatus();
        try {
          final res = await repository.fetchSellerProducts(
            status: _selectedStatus,
            page: _currentPage,
          );
          _hasMore = res.meta.hasMorePages;
          if (localMatches.isEmpty) return res.items;
          final existingIds = res.items.map((e) => e.id).toSet();
          return [
            ...localMatches.where((item) => !existingIds.contains(item.id)),
            ...res.items,
          ];
        } catch (_) {
          if (localMatches.isNotEmpty) {
            _hasMore = false;
            return localMatches;
          }
          rethrow;
        }
      },
      isEmpty: (items) => items.isEmpty,
      emptyMessage: 'Không có sản phẩm nào trong mục này.',
    );
  }

  /// Toggles visibility between APPROVED and HIDDEN
  Future<bool> toggleVisibility(int productId, String currentStatus) async {
    final nextStatus = currentStatus == 'APPROVED' ? 'HIDDEN' : 'APPROVED';
    final currentList = state.data ?? [];

    // Optimistic UI update
    final updatedList = currentList.map((item) {
      if (item.id == productId) {
        return item.copyWith(status: nextStatus);
      }
      return item;
    }).toList();
    setSuccess(updatedList);

    try {
      await repository.updateProductStatus(productId, nextStatus);
      return true;
    } catch (e) {
      // Revert if error
      setSuccess(currentList);
      return false;
    }
  }

  /// Relists an auction product (DEC-02)
  Future<bool> relistProduct(int productId, Map<String, dynamic> scheduleData) async {
    try {
      await repository.relistAuctionProduct(productId, scheduleData);
      await loadProducts(refresh: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deletes or archives a draft listing
  Future<bool> deleteDraft(int productId) async {
    final currentList = state.data ?? [];
    final updatedList = currentList.where((p) => p.id != productId).toList();
    setSuccess(updatedList);

    try {
      await repository.updateProductStatus(productId, 'ARCHIVED');
      return true;
    } catch (e) {
      setSuccess(currentList);
      return false;
    }
  }
}

/// Riverpod provider for SellerListingsViewModel
final sellerListingsViewModelProvider = ChangeNotifierProvider.autoDispose<SellerListingsViewModel>((ref) {
  final repo = ref.watch(sellerChannelRepositoryProvider);
  final demoStore = ref.watch(retroDemoStoreProvider);
  return SellerListingsViewModel(repository: repo, demoStore: demoStore);
});
