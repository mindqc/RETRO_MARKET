import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/base_view_model.dart';
import '../../../core/theme/seasonal_decor_provider.dart';
import '../../auth/models/user_model.dart';
import '../models/profile_summary_model.dart';
import '../repositories/profile_repository.dart';

/// ProfileViewModel manages unified personal hub, profile editing, and seasonal decor toggling (M-PF-01, M-PF-02, M-PF-06)
class ProfileViewModel extends BaseViewModel<ProfileSummaryModel?> {
  final ProfileRepository profileRepository;
  final SeasonalDecorNotifier seasonalDecorNotifier;

  ProfileSummaryModel? _profileSummary;

  ProfileViewModel({
    required this.profileRepository,
    required this.seasonalDecorNotifier,
  });

  ProfileSummaryModel? get profileSummary => _profileSummary;

  /// Loads full account summary with order counts and seller statistics (M-PF-01)
  Future<void> loadProfileSummary() async {
    await runCatching(() async {
      _profileSummary = await profileRepository.fetchMyProfile();
      return _profileSummary;
    });
  }

  /// Updates profile details and optional avatar file (M-PF-02)
  Future<UserModel?> updateProfile({
    required String displayName,
    String? phone,
    String? bio,
    String? shopSlug,
    String? avatarFilePath,
  }) async {
    UserModel? updatedUser;
    await runCatching(() async {
      updatedUser = await profileRepository.updateProfile(
        displayName: displayName,
        phone: phone,
        bio: bio,
        shopSlug: shopSlug,
        avatarFilePath: avatarFilePath,
      );

      if (_profileSummary != null && updatedUser != null) {
        _profileSummary = _profileSummary!.copyWith(user: updatedUser);
      }
      return _profileSummary;
    });
    return updatedUser;
  }

  /// Toggles seasonal holiday decor mode with optimistic UI update and server persistence (NFR-UX-02)
  Future<bool> toggleSeasonalDecor(bool enabled) async {
    // 1. Optimistic UI update
    await seasonalDecorNotifier.setEnabled(enabled);

    // 2. Persist to server
    try {
      final success = await profileRepository.updateSeasonalSetting(enabled);
      if (_profileSummary != null) {
        final currentProfile = _profileSummary!.user.profile ?? const UserProfileModel();
        final updatedProfile = currentProfile.copyWith(seasonalDecorEnabled: enabled);
        final updatedUser = _profileSummary!.user.copyWith(profile: updatedProfile);
        _profileSummary = _profileSummary!.copyWith(user: updatedUser);
        setSuccess(_profileSummary);
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Changes account password (M-PF-06)
  Future<bool> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    setLoading();
    try {
      final success = await profileRepository.changePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      setSuccess(_profileSummary);
      return success;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }
}

/// Riverpod provider for ProfileViewModel
final profileViewModelProvider = ChangeNotifierProvider<ProfileViewModel>((ref) {
  final profileRepo = ref.watch(profileRepositoryProvider);
  final seasonalNotifier = ref.watch(seasonalDecorProvider.notifier);
  return ProfileViewModel(
    profileRepository: profileRepo,
    seasonalDecorNotifier: seasonalNotifier,
  );
});
