import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/demo/retro_demo_marketplace_store.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/state/base_view_model.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../models/auction_card_model.dart';
import '../repositories/auction_repository.dart';

/// ViewModel managing the Scheduled Auction Hub (M-AC-01)
/// Supports tabs: live, ending_soon, upcoming, completed, all
class AuctionHubViewModel extends BaseViewModel<List<AuctionCardModel>> {
  final AuctionRepository repository;
  final int? currentUserId;
  final RetroDemoMarketplaceStore? demoStore;

  String _currentTab = 'live';
  PaginationMeta? _paginationMeta;
  bool _isLoadingMore = false;
  final List<AuctionCardModel> _items = [];

  AuctionHubViewModel({
    required this.repository,
    this.currentUserId,
    this.demoStore,
  });

  String get currentTab => _currentTab;
  List<AuctionCardModel> get items => List.unmodifiable(_items);
  PaginationMeta? get paginationMeta => _paginationMeta;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _paginationMeta?.hasMorePages ?? false;

  /// Loads initial list for the specified tab (live, ending_soon, upcoming, completed, all)
  Future<void> switchTab(String tab) async {
    if (_currentTab == tab && _items.isNotEmpty) return;
    _currentTab = tab;
    await fetchInitial();
  }

  /// Fetches page 1 of current tab with graceful demo fallback if backend is offline
  Future<void> fetchInitial() async {
    setLoading();
    try {
      final apiTab = _currentTab == 'all' ? 'live' : _currentTab;
      final res = await repository.fetchHubAuctions(
        tab: apiTab,
        page: 1,
        perPage: 12,
        currentUserId: currentUserId,
      );

      _items.clear();
      _items.addAll(res.items);

      if (demoStore != null && (_currentTab == 'all' || _items.length < 3)) {
        final existingIds = _items.map((e) => e.id).toSet();
        for (final demo in demoStore!.demoAuctionCardsForTab(_currentTab)) {
          if (!existingIds.contains(demo.id)) {
            _items.add(demo);
          }
        }
      }
      _paginationMeta = res.meta;

      setSuccess(List.unmodifiable(_items));
    } catch (e) {
      if (demoStore != null) {
        _items
          ..clear()
          ..addAll(demoStore!.demoAuctionCardsForTab(_currentTab));
        _paginationMeta = PaginationMeta(
          currentPage: 1,
          perPage: 12,
          total: _items.length,
          lastPage: 1,
          hasMorePages: false,
        );
        setSuccess(List.unmodifiable(_items));
      } else {
        setError(e.toString());
      }
    }
  }

  /// Loads next page of current tab
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    final nextPage = (_paginationMeta?.currentPage ?? 1) + 1;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final apiTab = _currentTab == 'all' ? 'live' : _currentTab;
      final res = await repository.fetchHubAuctions(
        tab: apiTab,
        page: nextPage,
        perPage: 12,
        currentUserId: currentUserId,
      );

      _items.addAll(res.items);
      _paginationMeta = res.meta;
      setSuccess(List.unmodifiable(_items));
    } catch (_) {
      // Keep existing data on loadMore error
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Optimistically toggles watch / seat-reservation status on an auction card
  Future<void> toggleWatch(int auctionId) async {
    final idx = _items.indexWhere((item) => item.id == auctionId);
    if (idx == -1) return;

    final oldItem = _items[idx];
    final newIsWatching = !oldItem.isWatching;

    // Optimistic update
    _items[idx] = oldItem.copyWith(isWatching: newIsWatching);
    notifyListeners();

    if (demoStore != null && demoStore!.getDemoAuctionDetail(auctionId) != null) {
      final synced = demoStore!.toggleLocalAuctionRegistration(auctionId);
      _items[idx] = oldItem.copyWith(isWatching: synced);
      notifyListeners();
      return;
    }

    try {
      final actualStatus = await repository.toggleWatch(auctionId);
      if (_items[idx].isWatching != actualStatus) {
        _items[idx] = _items[idx].copyWith(isWatching: actualStatus);
        notifyListeners();
      }
    } catch (_) {
      if (demoStore != null) {
        demoStore!.toggleLocalAuctionRegistration(auctionId);
      } else {
        _items[idx] = oldItem;
        notifyListeners();
      }
    }
  }
}

/// Riverpod provider for AuctionHubViewModel
final auctionHubViewModelProvider = ChangeNotifierProvider.autoDispose<AuctionHubViewModel>((ref) {
  final repo = ref.watch(auctionRepositoryProvider);
  final authVm = ref.watch(authViewModelProvider);
  final demoStore = ref.read(retroDemoStoreProvider);
  final vm = AuctionHubViewModel(
    repository: repo,
    currentUserId: authVm.currentUser?.id,
    demoStore: demoStore,
  );
  vm.fetchInitial();
  return vm;
});
