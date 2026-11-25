import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env_config.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/seasonal_decor_provider.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../viewmodels/profile_view_model.dart';

/// M-PF-06: App Settings & Festive Seasonal Toggle Screen (NFR-UX-02)
class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _isChangingPassword = false;
  bool _showChangePasswordForm = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitChangePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);

    final success = await ref.read(profileViewModelProvider).changePassword(
          currentPassword: _currentPasswordController.text,
          password: _newPasswordController.text,
          passwordConfirmation: _confirmNewPasswordController.text,
        );

    setState(() => _isChangingPassword = false);

    if (mounted) {
      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
        setState(() => _showChangePasswordForm = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.pineDeep,
            content: Text('Đổi mật khẩu thành công!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.priceCrimson,
            content:
                Text('Mật khẩu hiện tại không chính xác hoặc không hợp lệ.'),
          ),
        );
      }
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusBanner,
        ),
        title: Text(
          'Đăng xuất tài khoản?',
          style: AppTypography.headingSmall.copyWith(color: AppColors.pineDeep),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng izithrift trên thiết bị này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.priceCrimson,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authViewModelProvider).logout();
              if (mounted) {
                context.go(AppRoutes.home);
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDecorEnabled = ref.watch(seasonalDecorProvider);
    final authVm = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        title: const Text('Cài đặt ứng dụng'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Giao diện & Chủ đề lễ hội (NFR-UX-02)
              const RetroSectionHeader(
                title: 'Giao diện & Trải nghiệm',
                icon: Icons.palette_outlined,
                iconColor: AppColors.ctaTerracotta,
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Container(
                decoration: BoxDecoration(
                  borderRadius: DesignTokens.borderRadiusLg,
                  boxShadow: DesignTokens.cardElevation,
                ),
                child: Material(
                  color: AppColors.surfaceCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: DesignTokens.borderRadiusLg,
                    side: const BorderSide(color: AppColors.borderWarm),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                  activeColor: AppColors.priceCrimson,
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.priceCrimsonSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.priceCrimsonBorder),
                    ),
                    child: const Icon(
                      Icons.ac_unit_rounded,
                      color: AppColors.priceCrimson,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Chủ đề Giáng sinh ấm áp (Cozy Christmas)',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Hiển thị dải ruy-băng và nhành thông tuyết hoài cổ tại các góc giao diện (NFR-UX-02).',
                    style: AppTypography.caption,
                  ),
                  value: isDecorEnabled,
                  onChanged: (val) {
                    ref.read(profileViewModelProvider).toggleSeasonalDecor(val);
                  },
                  ),
                ),
              ),

              const SizedBox(height: DesignTokens.spaceXl),

              // 2. Bảo mật & Tài khoản (Chỉ hiển thị khi đã đăng nhập)
              if (authVm.isAuthenticated) ...[
                const RetroSectionHeader(
                  title: 'Tài khoản & Bảo mật',
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.pineDeep,
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: DesignTokens.borderRadiusLg,
                    boxShadow: DesignTokens.cardElevation,
                  ),
                  child: Material(
                    color: AppColors.surfaceCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: DesignTokens.borderRadiusLg,
                      side: const BorderSide(color: AppColors.borderWarm),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.creamBadgeSoft,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.creamBadgeBorder),
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: AppColors.pineDeep,
                            size: 19,
                          ),
                        ),
                        title: Text(
                          'Đổi mật khẩu',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(
                          _showChangePasswordForm
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: AppColors.textMuted,
                        ),
                        onTap: () {
                          setState(
                            () => _showChangePasswordForm =
                                !_showChangePasswordForm,
                          );
                        },
                      ),
                      if (_showChangePasswordForm)
                        Padding(
                          padding: const EdgeInsets.all(DesignTokens.spaceLg),
                          child: Form(
                            key: _passwordFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(
                                  height: 1,
                                  color: AppColors.borderSubtle,
                                ),
                                const SizedBox(height: DesignTokens.spaceMd),
                                Text(
                                  'Mật khẩu hiện tại',
                                  style: AppTypography.labelMedium,
                                ),
                                const SizedBox(height: DesignTokens.spaceXs),
                                TextFormField(
                                  controller: _currentPasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    hintText: 'Nhập mật khẩu đang dùng',
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Vui lòng nhập mật khẩu hiện tại.'
                                      : null,
                                ),
                                const SizedBox(height: DesignTokens.spaceMd),
                                Text(
                                  'Mật khẩu mới',
                                  style: AppTypography.labelMedium,
                                ),
                                const SizedBox(height: DesignTokens.spaceXs),
                                TextFormField(
                                  controller: _newPasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    hintText: 'Tối thiểu 8 ký tự',
                                  ),
                                  validator: (v) => v == null || v.length < 8
                                      ? 'Mật khẩu phải từ 8 ký tự trở lên.'
                                      : null,
                                ),
                                const SizedBox(height: DesignTokens.spaceMd),
                                Text(
                                  'Xác nhận mật khẩu mới',
                                  style: AppTypography.labelMedium,
                                ),
                                const SizedBox(height: DesignTokens.spaceXs),
                                TextFormField(
                                  controller: _confirmNewPasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    hintText: 'Nhập lại mật khẩu mới',
                                  ),
                                  validator: (v) =>
                                      v != _newPasswordController.text
                                          ? 'Mật khẩu xác nhận không khớp.'
                                          : null,
                                ),
                                const SizedBox(height: DesignTokens.spaceLg),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isChangingPassword
                                        ? null
                                        : _submitChangePassword,
                                    child: _isChangingPassword
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.textLight,
                                            ),
                                          )
                                        : const Text('Cập nhật mật khẩu'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceXl),
              ],

              // 3. Thông tin ứng dụng
              const RetroSectionHeader(
                title: 'Về ứng dụng',
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.starGold,
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Container(
                decoration: BoxDecoration(
                  borderRadius: DesignTokens.borderRadiusLg,
                  boxShadow: DesignTokens.cardElevation,
                ),
                child: Material(
                  color: AppColors.surfaceCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: DesignTokens.borderRadiusLg,
                    side: const BorderSide(color: AppColors.borderWarm),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                      leading: const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.textMuted,
                      ),
                      title: Text('Phiên bản', style: AppTypography.bodyMedium),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.creamBadgeSoft,
                          borderRadius: DesignTokens.borderRadiusFull,
                          border: Border.all(color: AppColors.creamBadgeBorder),
                        ),
                        child: Text(
                          '1.0.0 (Build 2026.11)',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.creamBadgeText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      indent: 56,
                      color: AppColors.borderSubtle,
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.dns_outlined,
                        color: AppColors.textMuted,
                      ),
                      title: Text(
                        'Môi trường API',
                        style: AppTypography.bodyMedium,
                      ),
                      trailing: Text(
                        EnvConfig.appName,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.pineDeep,
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: DesignTokens.space2xl),

              // 4. Nút Đăng xuất
              if (authVm.isAuthenticated) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.priceCrimson,
                      side: const BorderSide(color: AppColors.priceCrimson),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('Đăng xuất'),
                    onPressed: _confirmLogout,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
