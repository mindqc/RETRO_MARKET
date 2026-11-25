import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/demo/retro_demo_marketplace_store.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/error/error_code_enum.dart';
import '../../../core/services/lifecycle_polling_controller.dart';
import '../../../core/state/base_view_model.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../models/auction_detail_model.dart';
import '../models/outbid_conflict_state_model.dart';
import '../repositories/auction_repository.dart';

/// ViewModel managing Live Bidding Room (M-AC-03), real-time short-polling,
/// anti-sniping alerts, bid placement with 409 conflict retention, close-early, and relist.
class LiveAuctionViewModel extends BaseViewModel<AuctionDetailModel> {
  final int auctionId;
  final AuctionRepository repository;
  final int? currentUserId;
  final bool enablePolling;
  final RetroDemoMarketplaceStore? demoStore;

  AuctionDetailModel? _auction;
  LifecyclePollingController? _pollingController;

  bool _isSubmittingBid = false;
  bool _isClosingEarly = false;
  bool _isRelisting = false;
  bool _justTriggeredAntiSniping = false;
  bool _isUsingDemoFallback = false;
  OutbidConflictStateModel? _outbidConflict;
  String? _bidErrorMessage;

  LiveAuctionViewModel({
    required this.auctionId,
    required this.repository,
    this.currentUserId,
    this.enablePolling = true,
    this.demoStore,
  }) {
    if (enablePolling) {
      _pollingController = LifecyclePollingController(
        interval: const Duration(seconds: 3),
        pollAction: _pollAuctionRoom,
        autoStart: false,
      );
    }
  }

  AuctionDetailModel? get auction => _auction;
  bool get isSubmittingBid => _isSubmittingBid;
  bool get isClosingEarly => _isClosingEarly;
  bool get isRelisting => _isRelisting;
  bool get justTriggeredAntiSniping => _justTriggeredAntiSniping;
  bool get isUsingDemoFallback => _isUsingDemoFallback;
  OutbidConflictStateModel? get outbidConflict => _outbidConflict;
  String? get bidErrorMessage => _bidErrorMessage;
  LifecyclePollingController? get pollingController => _pollingController;

  /// Loads full auction room detail initially and starts polling if live
  Future<void> loadAuction() async {
    setLoading();

    final demoAuction = demoStore?.getDemoAuctionDetail(auctionId);
    if (demoAuction != null) {
      _isUsingDemoFallback = true;
      _auction = demoAuction;
      setSuccess(demoAuction);
      return;
    }

    try {
      final res = await repository.fetchAuctionDetail(
        auctionId,
        currentUserId: currentUserId,
      );
      _isUsingDemoFallback = false;
      final locallyRegistered =
          demoStore?.isAuctionRegistered(auctionId) ?? false;
      _auction = locallyRegistered && !res.isWatching
          ? res.copyWith(isWatching: true)
          : res;
      setSuccess(_auction!);

      if (enablePolling && res.isLive) {
        _pollingController?.start();
      }
    } catch (e) {
      final fallback = demoStore?.getDemoAuctionDetail(auctionId);
      if (fallback != null) {
        _isUsingDemoFallback = true;
        _auction = fallback;
        setSuccess(fallback);
        return;
      }
      setError(e.toString());
    }
  }

  /// Background polling cycle without triggering full screen loading indicator
  Future<void> _pollAuctionRoom() async {
    if (_auction == null || _isUsingDemoFallback) return;
    try {
      final updated = await repository.fetchAuctionDetail(
        auctionId,
        currentUserId: currentUserId,
      );

      // Detect Anti-Sniping extension triggered during polling
      if (updated.extendedCount > _auction!.extendedCount) {
        _justTriggeredAntiSniping = true;
      }

      _auction = updated;
      setSuccess(updated);

      // If auction finished, stop polling
      if (!updated.isLive) {
        _pollingController?.pause();
      }
    } catch (_) {
      // Swallowed during background polling
    }
  }

  /// Places a concurrent bid on the auction (M-AC-04 / BR-AU-03)
  /// If 409 conflict occurs, retains and updates state so bottom sheet can adapt immediately
  Future<bool> placeBid(double bidAmount) async {
    _isSubmittingBid = true;
    _bidErrorMessage = null;
    _outbidConflict = null;
    notifyListeners();

    if (_isUsingDemoFallback && demoStore != null && _auction != null) {
      if (bidAmount < _auction!.minimumNextBid) {
        _isSubmittingBid = false;
        _bidErrorMessage = 'Mức giá phải đạt tối thiểu theo bước giá quy định.';
        notifyListeners();
        return false;
      }

      final previousExtCount = _auction!.extendedCount;
      final updated = demoStore!.placeLocalDemoBid(
        auctionId: auctionId,
        bidAmount: bidAmount,
        bidderId: currentUserId ?? 999,
      );
      _isSubmittingBid = false;
      if (updated != null) {
        if (updated.extendedCount > previousExtCount) {
          _justTriggeredAntiSniping = true;
        }
        _auction = updated;
        setSuccess(updated);
        notifyListeners();
        return true;
      }
      _bidErrorMessage = 'Không thể đặt giá cho phiên đấu giá này.';
      notifyListeners();
      return false;
    }

    try {
      final result = await repository.placeBid(
        auctionId,
        bidAmount,
        currentUserId: currentUserId,
      );
      final updatedAuction = result['auction'] as AuctionDetailModel;
      final triggeredAntiSniping =
          result['triggered_anti_sniping'] as bool? ?? false;

      _auction = updatedAuction;
      if (triggeredAntiSniping) {
        _justTriggeredAntiSniping = true;
      }

      setSuccess(updatedAuction);
      _isSubmittingBid = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isSubmittingBid = false;
      if (e.errorCodeEnum == ErrorCodeEnum.auctionOutbidConflict ||
          e.statusCode == 409) {
        // Extract 409 Conflict latest_state
        if (e.latestState != null) {
          final conflictState = OutbidConflictStateModel.fromJson(
            e.latestState!,
          );
          _outbidConflict = conflictState;

          // Merge latest state into local auction model
          if (_auction != null) {
            _auction = _auction!.copyWith(
              currentHighestBid: conflictState.currentHighestBid,
              minimumNextBid: conflictState.minimumNextBid,
              bidCount: conflictState.bidCount,
              auctionEndsAt: conflictState.auctionEndsAt,
              extendedCount: conflictState.extendedCount,
              isLeading: false,
              isOutbid: true,
            );
            setSuccess(_auction!);
          }
        }
        _bidErrorMessage = e.message;
      } else {
        _bidErrorMessage = e.message;
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isSubmittingBid = false;
      _bidErrorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clears 409 conflict and bid error message
  void clearConflict() {
    _outbidConflict = null;
    _bidErrorMessage = null;
    notifyListeners();
  }

  /// Clears anti-sniping trigger banner
  void dismissAntiSnipingBanner() {
    _justTriggeredAntiSniping = false;
    notifyListeners();
  }

  /// Toggles watch / seat reservation status
  Future<bool> toggleWatch() async {
    if (_auction == null) return false;
    final oldWatching = _auction!.isWatching;
    final newWatching = !oldWatching;

    if (_isUsingDemoFallback && demoStore != null) {
      final nowRegistered = demoStore!.toggleLocalAuctionRegistration(
        auctionId,
      );
      _auction =
          demoStore!.getDemoAuctionDetail(auctionId) ??
          _auction!.copyWith(isWatching: nowRegistered);
      setSuccess(_auction!);
      return nowRegistered;
    }

    _auction = _auction!.copyWith(isWatching: newWatching);
    setSuccess(_auction!);

    try {
      final actual = await repository.toggleWatch(auctionId);
      if (_auction!.isWatching != actual) {
        _auction = _auction!.copyWith(isWatching: actual);
        setSuccess(_auction!);
      }
      if (demoStore != null &&
          demoStore!.isAuctionRegistered(auctionId) != actual) {
        demoStore!.toggleLocalAuctionRegistration(auctionId);
      }
      return actual;
    } catch (_) {
      if (demoStore != null) {
        final localStatus = demoStore!.toggleLocalAuctionRegistration(
          auctionId,
        );
        if (_auction!.isWatching != localStatus) {
          _auction = _auction!.copyWith(isWatching: localStatus);
          setSuccess(_auction!);
        }
        return localStatus;
      }
      _auction = _auction!.copyWith(isWatching: oldWatching);
      setSuccess(_auction!);
      return oldWatching;
    }
  }

  /// Seller closes auction early for current highest bidder (M-AC-05 / BR-AU-05)
  Future<bool> closeEarly() async {
    _isClosingEarly = true;
    notifyListeners();

    try {
      final res = await repository.closeEarly(
        auctionId,
        currentUserId: currentUserId,
      );
      _auction = res;
      setSuccess(res);
      _pollingController?.pause();
      _isClosingEarly = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isClosingEarly = false;
      _bidErrorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Seller relists unsold or defaulted product into a new auction (M-AC-06 / DEC-02)
  Future<AuctionDetailModel?> relistAuction({
    required double startingPrice,
    required double minBidIncrement,
    required DateTime auctionStartsAt,
    required DateTime auctionEndsAt,
    double? reservePrice,
  }) async {
    if (_auction == null) return null;
    _isRelisting = true;
    notifyListeners();

    try {
      final newAuction = await repository.relistAuction(
        _auction!.productId,
        startingPrice: startingPrice,
        minBidIncrement: minBidIncrement,
        auctionStartsAt: auctionStartsAt,
        auctionEndsAt: auctionEndsAt,
        reservePrice: reservePrice,
        currentUserId: currentUserId,
      );

      _isRelisting = false;
      notifyListeners();
      return newAuction;
    } catch (e) {
      _isRelisting = false;
      _bidErrorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _pollingController?.dispose();
    super.dispose();
  }
}

/// Riverpod family provider for LiveAuctionViewModel
final liveAuctionViewModelProvider =
    ChangeNotifierProvider.autoDispose.family<LiveAuctionViewModel, int>((
      ref,
      auctionId,
    ) {
      final repo = ref.watch(auctionRepositoryProvider);
      final authVm = ref.watch(authViewModelProvider);
      final demoStore = ref.read(retroDemoStoreProvider);
      final vm = LiveAuctionViewModel(
        auctionId: auctionId,
        repository: repo,
        currentUserId: authVm.currentUser?.id,
        demoStore: demoStore,
      );
      vm.loadAuction();
      return vm;
    });
