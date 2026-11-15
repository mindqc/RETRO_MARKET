import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/state/base_view_model.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../models/auction_card_model.dart';
import '../repositories/auction_repository.dart';

/// ViewModel managing user's personal auction activities (M-AC-02)
/// Tabs: participating, watchlist, won
class MyAuctionsViewModel extends BaseViewModel<List<AuctionCardModel>> {
  final AuctionRepository repository;
  final int? currentUserId;

  String _currentTab = 'participating';
  PaginationMeta? _paginationMeta;
  bool _isLoadingMore = false;
  final List<AuctionCardModel> _items = [];

  MyAuctionsViewModel({
    required this.repository,
    this.currentUserId,
  });

  String get currentTab => _currentTab;
  List<AuctionCardModel> get items => List.unmodifiable(_items);
  PaginationMeta? get paginationMeta => _paginationMeta;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _paginationMeta?.hasMorePages ?? false;

  int get leadingCount => _items.where((i) => i.isLeading).length;
  int get outbidCount => _items.where((i) => i.isOutbid).length;

  Future<void> switchTab(String tab) async {
    if (_currentTab == tab && _items.isNotEmpty) return;
    _currentTab = tab;
    await fetchInitial();
  }

  Future<void> fetchInitial() async {
    setLoading();
    try {
      final res = await repository.fetchMyAuctions(
        tab: _currentTab,
        page: 1,
        perPage: 12,
        currentUserId: currentUserId,
      );

      _items.clear();
      _items.addAll(res.items);
      _paginationMeta = res.meta;

      setSuccess(List.unmodifiable(_items));
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    final nextPage = (_paginationMeta?.currentPage ?? 1) + 1;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final res = await repository.fetchMyAuctions(
        tab: _currentTab,
        page: nextPage,
        perPage: 12,
        currentUserId: currentUserId,
      );

      _items.addAll(res.items);
      _paginationMeta = res.meta;
      setSuccess(List.unmodifiable(_items));
    } catch (_) {
      // Keep existing items on pagination error
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> toggleWatch(int auctionId) async {
    final idx = _items.indexWhere((item) => item.id == auctionId);
    if (idx == -1) return;

    final oldItem = _items[idx];
    final newIsWatching = !oldItem.isWatching;

    _items[idx] = oldItem.copyWith(isWatching: newIsWatching);
    notifyListeners();

    try {
      final actualStatus = await repository.toggleWatch(auctionId);
      if (_items[idx].isWatching != actualStatus) {
        _items[idx] = _items[idx].copyWith(isWatching: actualStatus);
        notifyListeners();
      }
    } catch (_) {
      _items[idx] = oldItem;
      notifyListeners();
    }
  }
}

/// Riverpod provider for MyAuctionsViewModel
final myAuctionsViewModelProvider = ChangeNotifierProvider.autoDispose<MyAuctionsViewModel>((ref) {
  final repo = ref.watch(auctionRepositoryProvider);
  final authVm = ref.watch(authViewModelProvider);
  final vm = MyAuctionsViewModel(
    repository: repo,
    currentUserId: authVm.currentUser?.id,
  );
  vm.fetchInitial();
  return vm;
});
