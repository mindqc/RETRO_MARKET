import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../viewmodels/auth_view_model.dart';

/// M-AU-04: Unified Buyer/Seller Account Registration (BR-AC-01)
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  ApiException? _lastApiException;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _lastApiException = null;
    });

    final authVm = ref.read(authViewModelProvider);

    try {
      await authVm.register(
        displayName: _displayNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;

      if (authVm.isAuthenticated) {
        context.go(AppRoutes.home);
      } else if (authVm.state.isError && authVm.state.error != null) {
        setState(() => _lastApiException = authVm.state.error);
      }
    } catch (e) {
      if (e is ApiException) {
        setState(() => _lastApiException = e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nameError = _lastApiException?.firstErrorFor('display_name');
    final emailError = _lastApiException?.firstErrorFor('email');
    final phoneError = _lastApiException?.firstErrorFor('phone');
    final passwordError = _lastApiException?.firstErrorFor('password');

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tham gia cộng đồng izithrift',
                  style: AppTypography.headingLarge,
                ),
                const SizedBox(height: DesignTokens.spaceXs),
                Text(
                  'Tạo tài khoản để vừa mua sắm vừa mở tiệm kinh doanh đồ cũ.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: DesignTokens.spaceMd),

                // BR-AC-01 Unified Account Callout Box
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceMd),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5EE),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    border: Border.all(color: const Color(0xFFBCE3C6)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.storefront, color: AppColors.secondaryPineGreen, size: 22),
                      const SizedBox(width: DesignTokens.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tài khoản hợp nhất Người mua & Người bán (BR-AC-01)',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.secondaryPineGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Một tài khoản duy nhất kích hoạt đồng thời quyền mua sắm và gian hàng cá nhân. Không cần đăng ký kênh người bán riêng biệt.',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.secondaryPineGreen,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: DesignTokens.spaceLg),

                // General Error Banner
                if (_lastApiException != null && _lastApiException!.fieldErrors.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceMd),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                      border: Border.all(color: const Color(0xFFF8B4B4)),
                    ),
                    child: Text(
                      _lastApiException!.message,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.statusDanger),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                ],

                // Display Name
                Text('Tên hiển thị / Tên tiệm', style: AppTypography.labelMedium),
                const SizedBox(height: DesignTokens.spaceXs),
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Tiệm Đồ Cũ Vintage',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    errorText: nameError,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập tên hiển thị.';
                    }
                    if (val.trim().length < 2) {
                      return 'Tên hiển thị phải có ít nhất 2 ký tự.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.spaceLg),

                // Email
                Text('Địa chỉ Email', style: AppTypography.labelMedium),
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
                      return 'Email không đúng định dạng.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.spaceLg),

                // Phone (Optional)
                Text('Số điện thoại (Không bắt buộc)', style: AppTypography.labelMedium),
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

                // Password
                Text('Mật khẩu', style: AppTypography.labelMedium),
                const SizedBox(height: DesignTokens.spaceXs),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Tối thiểu 8 ký tự',
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
                    if (val.length < 8) {
                      return 'Mật khẩu phải chứa ít nhất 8 ký tự.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.spaceLg),

                // Password Confirmation
                Text('Xác nhận mật khẩu', style: AppTypography.labelMedium),
                const SizedBox(height: DesignTokens.spaceXs),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Nhập lại mật khẩu',
                    prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu.';
                    }
                    if (val != _passwordController.text) {
                      return 'Mật khẩu xác nhận không khớp.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: DesignTokens.spaceXl),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRegister,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textLight,
                            ),
                          )
                        : const Text('Đăng ký tài khoản'),
                  ),
                ),

                const SizedBox(height: DesignTokens.spaceLg),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Đã có tài khoản? ',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Đăng nhập ngay',
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
