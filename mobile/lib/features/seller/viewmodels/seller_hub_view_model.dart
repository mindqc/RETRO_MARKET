import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/base_view_model.dart';
import '../models/seller_dashboard_model.dart';
import '../models/seller_wallet_overview_model.dart';
import '../repositories/seller_channel_repository.dart';

/// ViewModel managing Seller Hub metrics (M-SL-01) and Wallet Ledger overview (M-SL-08).
class SellerHubViewModel extends BaseViewModel<SellerDashboardModel> {
  final SellerChannelRepository repository;

  SellerWalletOverviewModel? _walletOverview;
  bool _isLoadingWallet = false;

  SellerHubViewModel({required this.repository});

  SellerWalletOverviewModel? get walletOverview => _walletOverview;
  bool get isLoadingWallet => _isLoadingWallet;

  /// Loads dashboard metrics from GET /api/v1/seller/dashboard
  Future<void> loadDashboard() async {
    await runCatching(
      () => repository.fetchDashboard(),
      emptyMessage: 'Không có thông tin bảng điều khiển.',
    );
  }

  /// Loads wallet balance and transaction ledger (M-SL-08)
  Future<void> loadWalletLedger({int page = 1}) async {
    _isLoadingWallet = true;
    notifyListeners();

    try {
      final res = await repository.fetchWalletLedger(page: page);
      _walletOverview = res;
      _isLoadingWallet = false;
      notifyListeners();
    } catch (e) {
      _isLoadingWallet = false;
      notifyListeners();
    }
  }

  /// Pull to refresh dashboard
  Future<void> refresh() async {
    try {
      final res = await repository.fetchDashboard();
      setSuccess(res);
    } catch (e) {
      if (state.data == null) {
        await loadDashboard();
      }
    }
  }
}

/// Riverpod provider for SellerHubViewModel
final sellerHubViewModelProvider = ChangeNotifierProvider.autoDispose<SellerHubViewModel>((ref) {
  final repo = ref.watch(sellerChannelRepositoryProvider);
  return SellerHubViewModel(repository: repo);
});
