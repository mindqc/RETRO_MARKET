import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/error/error_code_enum.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/models/user_model.dart';
import '../models/profile_summary_model.dart';

/// ProfileRepository manages user profile, avatar upload, and security settings
class ProfileRepository {
  final DioClient dioClient;

  ProfileRepository({required this.dioClient});

  /// Fetches full user profile with order status counts and shop stats (M-PF-01)
  Future<ProfileSummaryModel> fetchMyProfile() async {
    final response = await dioClient.get(ApiEndpoints.profile);
    final data = response.data?['data'] as Map<String, dynamic>;
    return ProfileSummaryModel.fromJson(data);
  }

  /// Updates personal info, shop slug, and optional avatar image (M-PF-02)
  /// Enforces NFR-SEC-05 file size check (max 5MB for avatars)
  Future<UserModel> updateProfile({
    required String displayName,
    String? phone,
    String? bio,
    String? shopSlug,
    String? avatarFilePath,
  }) async {
    if (avatarFilePath != null && avatarFilePath.isNotEmpty) {
      final file = io.File(avatarFilePath);
      if (file.existsSync()) {
        final fileSize = file.lengthSync();
        if (fileSize > 5 * 1024 * 1024) {
          throw const ApiException(
            statusCode: 422,
            errorCode: 'VALIDATION_ERROR',
            errorCodeEnum: ErrorCodeEnum.validationError,
            message: 'Kích thước ảnh đại diện không được vượt quá 5MB (NFR-SEC-05).',
          );
        }
      }

      final fileName = avatarFilePath.split(io.Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'display_name': displayName.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (bio != null) 'bio': bio.trim(),
        if (shopSlug != null) 'shop_slug': shopSlug.trim(),
        'avatar': await MultipartFile.fromFile(avatarFilePath, filename: fileName),
      });

      final response = await dioClient.putMultipart(
        ApiEndpoints.profile,
        formData: formData,
      );
      final userJson = response.data?['data'] as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } else {
      final response = await dioClient.post(
        ApiEndpoints.profile,
        data: {
          '_method': 'PUT',
          'display_name': displayName.trim(),
          if (phone != null) 'phone': phone.trim(),
          if (bio != null) 'bio': bio.trim(),
          if (shopSlug != null) 'shop_slug': shopSlug.trim(),
        },
      );
      final userJson = response.data?['data'] as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    }
  }

  /// Toggles seasonal holiday decor preference (NFR-UX-02)
  Future<bool> updateSeasonalSetting(bool enabled) async {
    final response = await dioClient.put(
      ApiEndpoints.updateSettings,
      data: {'seasonal_decor_enabled': enabled},
    );
    return response.data?['success'] == true;
  }

  /// Updates user password with current password verification
  Future<bool> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await dioClient.put(
      ApiEndpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return response.data?['success'] == true;
  }
}

/// Riverpod provider for ProfileRepository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ProfileRepository(dioClient: dioClient);
});
