import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/error/error_code_enum.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../viewmodels/auth_view_model.dart';

/// M-AU-03: Login Screen with Suspension Alert Dialog (BR-AC-04)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  ApiException? _lastApiException;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _lastApiException = null;
    });

    final authVm = ref.read(authViewModelProvider);

    try {
      await authVm.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (authVm.isAuthenticated) {
        context.go(AppRoutes.home);
      } else if (authVm.state.isError && authVm.state.error != null) {
        _handleLoginError(authVm.state.error!);
      }
    } catch (e) {
      if (e is ApiException) {
        _handleLoginError(e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _handleLoginError(ApiException err) {
    setState(() => _lastApiException = err);

    if (err.errorCodeEnum == ErrorCodeEnum.accountSuspended || err.statusCode == 403) {
      _showAccountSuspendedDialog(err.message);
    }
  }

  void _showAccountSuspendedDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        title: Row(
          children: [
            const Icon(Icons.block, color: AppColors.statusDanger, size: 24),
            const SizedBox(width: DesignTokens.spaceSm),
            Expanded(
              child: Text(
                'Tài khoản bị tạm khóa',
                style: AppTypography.headingSmall.copyWith(color: AppColors.statusDanger),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reason.isNotEmpty
                  ? reason
                  : 'Tài khoản của bạn đã bị khóa do vi phạm tiêu chuẩn cộng đồng (BR-AC-04).',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(
              'Nếu bạn cho rằng đây là sự nhầm lẫn, vui lòng liên hệ bộ phận hỗ trợ khách hàng qua email support@retromarket.vn.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
            ),
            onPressed: () {
              ref.read(authViewModelProvider).clearSuspendedAlert();
              Navigator.of(ctx).pop();
            },
            child: const Text('Tôi đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailError = _lastApiException?.firstErrorFor('email');
    final passwordError = _lastApiException?.firstErrorFor('password');

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Đăng nhập'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: DesignTokens.spaceMd),
                Text(
                  'Chào mừng trở lại!',
                  style: AppTypography.headingLarge,
                ),
                const SizedBox(height: DesignTokens.spaceXs),
                Text(
                  'Đăng nhập để khám phá kho đồ vintage và quản lý tiệm của bạn.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: DesignTokens.spaceXl),

                if (_lastApiException != null &&
                    _lastApiException!.errorCodeEnum != ErrorCodeEnum.accountSuspended &&
                    _lastApiException!.fieldErrors.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceMd),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                      border: Border.all(color: const Color(0xFFF8B4B4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.statusDanger, size: 20),
                        const SizedBox(width: DesignTokens.spaceSm),
                        Expanded(
                          child: Text(
                            _lastApiException!.message,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.statusDanger),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                ],

                // Email
                Text('Email', style: AppTypography.labelMedium),
                const SizedBox(height: DesignTokens.spaceXs),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'vidu@gmail.com',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    errorText: emailError,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập địa chỉ email.';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Địa chỉ email không đúng định dạng.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.spaceLg),

                // Password
                Text('Mật khẩu', style: AppTypography.labelMedium),
                const SizedBox(height: DesignTokens.spaceXs),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Nhập mật khẩu của bạn',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    errorText: passwordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Vui lòng nhập mật khẩu.';
                    }
                    return null;
                  },
                ),

                // Forgot Password shortcut
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: Text(
                      'Quên mật khẩu?',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryTerracotta,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: DesignTokens.spaceMd),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitLogin,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textLight,
                            ),
                          )
                        : const Text('Đăng nhập'),
                  ),
                ),

                const SizedBox(height: DesignTokens.spaceXl),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Chưa có tài khoản? ',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.register),
                      child: Text(
                        'Đăng ký ngay',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primaryTerracotta,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
