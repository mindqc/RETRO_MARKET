import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../viewmodels/profile_view_model.dart';

/// M-PF-02: Edit Profile & Avatar Upload Screen
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _shopSlugController = TextEditingController();

  String? _selectedAvatarPath;
  bool _isSubmitting = false;
  ApiException? _lastApiException;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).currentUser;
    if (user != null) {
      _nameController.text = user.displayName;
      _phoneController.text = user.phone ?? '';
      _bioController.text = user.profile?.bio ?? '';
      _shopSlugController.text = user.sellerProfile?.shopSlug ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _shopSlugController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedAvatarPath = image.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _lastApiException = null;
    });

    final profileVm = ref.read(profileViewModelProvider);
    try {
      final updatedUser = await profileVm.updateProfile(
        displayName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        shopSlug: _shopSlugController.text.trim().isNotEmpty
            ? _shopSlugController.text.trim()
            : null,
        avatarFilePath: _selectedAvatarPath,
      );

      if (updatedUser != null && mounted) {
        ref.read(authViewModelProvider).updateCurrentUser(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.pineDeep,
            content: Text('Cập nhật hồ sơ thành công!'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (e is ApiException) {
        setState(() => _lastApiException = e);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatarUrl =
        ref.watch(authViewModelProvider).currentUser?.profile?.avatarUrl;

    final nameError = _lastApiException?.firstErrorFor('display_name');
    final phoneError = _lastApiException?.firstErrorFor('phone');
    final slugError = _lastApiException?.firstErrorFor('shop_slug');

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        title: const Text('Chỉnh sửa hồ sơ'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Center Picker
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 102,
                        height: 102,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: const RadialGradient(
                            colors: [
                              AppColors.categoryCircleStart,
                              AppColors.categoryCircleEnd,
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.creamBadgeBorder,
                            width: 2,
                          ),
                          boxShadow: DesignTokens.cardElevation,
                        ),
                        child: ClipOval(
                          child: _buildAvatarImage(currentAvatarUrl),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickAvatar,
                          customBorder: const CircleBorder(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.ctaTerracotta,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surfaceCard,
                                width: 2,
                              ),
                              boxShadow: DesignTokens.cardElevation,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.textLight,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceXl),

                if (_lastApiException != null &&
                    _lastApiException!.fieldErrors.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceMd),
                    decoration: BoxDecoration(
                      color: AppColors.priceCrimsonSoft,
                      borderRadius: DesignTokens.borderRadiusMd,
                      border: Border.all(color: AppColors.priceCrimsonBorder),
                    ),
                    child: Text(
                      _lastApiException!.message,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.priceCrimson,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                ],

                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: DesignTokens.borderRadiusBanner,
                    border: Border.all(color: AppColors.borderWarm),
                    boxShadow: DesignTokens.cardElevation,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display Name
                      Text('Tên hiển thị', style: AppTypography.labelMedium),
                      const SizedBox(height: DesignTokens.spaceXs),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.person_outline, size: 20),
                          errorText: nameError,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập tên hiển thị.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),

                      // Phone
                      Text('Số điện thoại', style: AppTypography.labelMedium),
                      const SizedBox(height: DesignTokens.spaceXs),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '0901234567',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          errorText: phoneError,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),

                      // Shop Slug
                      Text(
                        'Định danh tiệm (Shop Slug)',
                        style: AppTypography.labelMedium,
                      ),
                      const SizedBox(height: DesignTokens.spaceXs),
                      TextFormField(
                        controller: _shopSlugController,
                        decoration: InputDecoration(
                          hintText: 'tiem-do-cu-vintage',
                          prefixIcon: const Icon(Icons.storefront, size: 20),
                          errorText: slugError,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),

                      // Bio
                      Text(
                        'Tiểu sử / Giới thiệu tiệm',
                        style: AppTypography.labelMedium,
                      ),
                      const SizedBox(height: DesignTokens.spaceXs),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Đôi nét về gu đồ vintage của bạn...',
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceXl),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _saveProfile,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textLight,
                                  ),
                                )
                              : const Text('Lưu thay đổi'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String? currentUrl) {
    if (_selectedAvatarPath != null) {
      return Image.file(
        File(_selectedAvatarPath!),
        fit: BoxFit.cover,
      );
    }
    if (currentUrl != null && currentUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: currentUrl,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) =>
            const Icon(Icons.person_rounded, size: 48, color: AppColors.pineDeep),
      );
    }
    return const Icon(Icons.person_rounded, size: 48, color: AppColors.pineDeep);
  }
}
