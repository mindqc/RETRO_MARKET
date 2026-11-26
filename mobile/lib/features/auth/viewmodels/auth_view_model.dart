import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/secure_token_storage.dart';
import '../../../core/state/base_view_model.dart';
import '../../../core/theme/seasonal_decor_provider.dart';
import '../models/bootstrap_model.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../../profile/repositories/profile_repository.dart';

const String kHasSeenOnboardingKey = 'has_seen_onboarding';

/// AuthViewModel manages global authentication state, token lifecycle, and account suspension alerts (BR-AC-04)
class AuthViewModel extends BaseViewModel<UserModel?> {
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final SecureTokenStorage tokenStorage;
  final SeasonalDecorNotifier seasonalDecorNotifier;
  final SharedPreferences? prefs;

  UserModel? _currentUser;
  BootstrapModel? _bootstrapConfig;
  bool _hasSeenOnboarding = false;
  String? _sessionSuspendedReason;
  StreamSubscription<AuthSessionAlert>? _alertSubscription;

  AuthViewModel({
    required this.authRepository,
    required this.profileRepository,
    required this.tokenStorage,
    required this.seasonalDecorNotifier,
    this.prefs,
  }) {
    _listenToSessionAlerts();
  }

  UserModel? get currentUser => _currentUser;
  BootstrapModel? get bootstrapConfig => _bootstrapConfig;
  bool get isAuthenticated => _currentUser != null;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  String? get sessionSuspendedReason => _sessionSuspendedReason;

  void _listenToSessionAlerts() {
    _alertSubscription = tokenStorage.sessionAlerts.listen((alert) {
      if (alert.type == AuthSessionAlertType.accountSuspended) {
        _sessionSuspendedReason = alert.message;
        _currentUser = null;
        setError(alert.message);
      } else if (alert.type == AuthSessionAlertType.unauthenticated) {
        _currentUser = null;
        setEmpty('Phiên đăng nhập đã hết hạn.');
      }
    });
  }

  /// Initializes system bootstrap and checks saved session (M-AU-01)
  Future<void> initializeBootstrap() async {
    await runCatching(() async {
      // 1. Check onboarding preference
      try {
        final p = prefs ?? await SharedPreferences.getInstance();
        _hasSeenOnboarding = p.getBool(kHasSeenOnboardingKey) ?? false;
      } catch (_) {}

      // 2. Fetch Bootstrap configuration
      _bootstrapConfig = await authRepository.fetchBootstrap();

      // 3. Verify existing session
      final hasToken = await tokenStorage.hasToken();
      if (hasToken) {
        try {
          final profileSummary = await profileRepository.fetchMyProfile();
          _currentUser = profileSummary.user;

          // Sync user's saved seasonal decor preference (NFR-UX-02)
          final decorEnabled = _currentUser?.profile?.seasonalDecorEnabled ?? true;
          await seasonalDecorNotifier.setEnabled(decorEnabled);
        } catch (_) {
          // Token invalid or network error on cold start
          _currentUser = null;
        }
      } else {
        _currentUser = null;
      }

      return _currentUser;
    });
  }

  /// Authenticates user credentials via POST /api/v1/auth/login and syncs seasonal decor (M-AU-03).
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _sessionSuspendedReason = null;
    await runCatching(() async {
      final user = await authRepository.login(email: email, password: password);
      _currentUser = user;

      // Sync seasonal decor setting
      final decorEnabled = user.profile?.seasonalDecorEnabled ?? true;
      await seasonalDecorNotifier.setEnabled(decorEnabled);

      return user;
    });
  }

  /// Registers unified Buyer/Seller account (BR-AC-01, M-AU-04)
  Future<void> register({
    required String displayName,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    _sessionSuspendedReason = null;
    await runCatching(() async {
      final user = await authRepository.register(
        displayName: displayName,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      _currentUser = user;

      final decorEnabled = user.profile?.seasonalDecorEnabled ?? true;
      await seasonalDecorNotifier.setEnabled(decorEnabled);

      return user;
    });
  }

  /// Logs out active user and clears session credentials
  Future<void> logout() async {
    setLoading();
    try {
      await authRepository.logout();
    } catch (_) {}
    _currentUser = null;
    _sessionSuspendedReason = null;
    setSuccess(null);
  }

  /// Updates onboarding completion flag in SharedPreferences
  Future<void> setHasSeenOnboarding(bool value) async {
    _hasSeenOnboarding = value;
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      await p.setBool(kHasSeenOnboardingKey, value);
    } catch (_) {}
    notifyListeners();
  }

  /// Clears suspension message after user acknowledges dialog
  void clearSuspendedAlert() {
    _sessionSuspendedReason = null;
    notifyListeners();
  }

  /// Updates cached current user object locally (e.g. after profile edit)
  void updateCurrentUser(UserModel user) {
    _currentUser = user;
    setSuccess(user);
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }
}

/// Riverpod provider for AuthViewModel
final authViewModelProvider = ChangeNotifierProvider<AuthViewModel>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);
  final tokenStorage = ref.watch(secureTokenStorageProvider);
  final seasonalDecorNotifier = ref.watch(seasonalDecorProvider.notifier);

  return AuthViewModel(
    authRepository: authRepo,
    profileRepository: profileRepo,
    tokenStorage: tokenStorage,
    seasonalDecorNotifier: seasonalDecorNotifier,
  );
});
