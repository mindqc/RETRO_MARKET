import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/error/error_code_enum.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/izithrift_logo.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../../../core/widgets/sell_action_bottom_sheet.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/auth_login_bottom_sheet.dart';

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

  void _navigateAfterLogin() {
    final pending = ref.read(pendingAuthRedirectProvider);
    ref.read(pendingAuthRedirectProvider.notifier).state = null;

    if (pending == null) {
      context.go(AppRoutes.home);
      return;
    }

    if (pending.returnToCaller) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(pending.route, extra: pending.extra);
      }
      return;
    }

    if (pending.openSellSheet) {
      context.go(AppRoutes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navCtx = AppRouter.rootNavigatorKey.currentContext;
        if (navCtx != null && navCtx.mounted) {
          showSellActionBottomSheet(navCtx);
        }
      });
      return;
    }

    if (pending.useGo) {
      context.go(pending.route, extra: pending.extra);
    } else {
      context.pushReplacement(pending.route, extra: pending.extra);
    }
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
        _navigateAfterLogin();
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

    if (err.errorCodeEnum == ErrorCodeEnum.accountSuspended ||
        err.statusCode == 403) {
      _showAccountSuspendedDialog(err.message);
    }
  }

  void _showAccountSuspendedDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusBanner,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.priceCrimsonSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.block_rounded,
                color: AppColors.priceCrimson,
                size: 22,
              ),
            ),
            const SizedBox(width: DesignTokens.spaceSm),
            Expanded(
              child: Text(
                'Tài khoản bị tạm khóa',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.priceCrimson,
                ),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: DesignTokens.borderRadiusMd,
                border: Border.all(color: AppColors.borderWarm),
              ),
              child: Text(
                'Nếu bạn cho rằng đây là sự nhầm lẫn, vui lòng liên hệ bộ phận hỗ trợ khách hàng qua email support@retromarket.vn.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.priceCrimson,
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
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        title: const Text('Đăng nhập'),
      ),
      body: RetroAmbientSnowflakes(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IzithriftLogo.iconOnly(iconSize: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chào mừng trở lại!',
                              style: AppTypography.headingLarge.copyWith(
                                color: AppColors.pineDeep,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Đăng nhập để khám phá kho đồ vintage và quản lý tiệm của bạn.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceXl),

                  if (_lastApiException != null &&
                      _lastApiException!.errorCodeEnum !=
                          ErrorCodeEnum.accountSuspended &&
                      _lastApiException!.fieldErrors.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.spaceMd),
                      decoration: BoxDecoration(
                        color: AppColors.priceCrimsonSoft,
                        borderRadius: DesignTokens.borderRadiusMd,
                        border: Border.all(color: AppColors.priceCrimsonBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.priceCrimson,
                            size: 20,
                          ),
                          const SizedBox(width: DesignTokens.spaceSm),
                          Expanded(
                            child: Text(
                              _lastApiException!.message,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.priceCrimson,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                  ],

                  // Elevated Editorial Form Card
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
                        // Email
                        Text(
                          'Địa chỉ Email',
                          style: AppTypography.labelMedium,
                        ),
                        const SizedBox(height: DesignTokens.spaceXs),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'vidu@gmail.com',
                            prefixIcon:
                                const Icon(Icons.email_outlined, size: 20),
                            errorText: emailError,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Vui lòng nhập địa chỉ email.';
                            }
                            final normalized = val.trim().toLowerCase();
                            if (!normalized.contains('@') ||
                                !normalized.contains('.')) {
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
                            prefixIcon:
                                const Icon(Icons.lock_outline, size: 20),
                            errorText: passwordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
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
                            onPressed: () =>
                                context.push(AppRoutes.forgotPassword),
                            child: Text(
                              'Quên mật khẩu?',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.ctaTerracotta,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: DesignTokens.spaceSm),

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
                      ],
                    ),
                  ),

                  const SizedBox(height: DesignTokens.spaceXl),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chưa có tài khoản? ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.register),
                        child: Text(
                          'Đăng ký ngay',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.ctaTerracotta,
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
      ),
    );
  }
}
