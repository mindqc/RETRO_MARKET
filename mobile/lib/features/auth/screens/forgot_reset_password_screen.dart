import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/izithrift_global_app_bar.dart';
import '../../../core/widgets/izithrift_logo.dart';
import '../../../core/widgets/retro_design_primitives.dart';
import '../repositories/auth_repository.dart';

/// M-AU-05: Forgot & Reset Password Flow
class ForgotResetPasswordScreen extends ConsumerStatefulWidget {
  const ForgotResetPasswordScreen({super.key});

  @override
  ConsumerState<ForgotResetPasswordScreen> createState() =>
      _ForgotResetPasswordScreenState();
}

class _ForgotResetPasswordScreenState
    extends ConsumerState<ForgotResetPasswordScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 1; // 1 = Request Token, 2 = Reset Password
  bool _isSubmitting = false;
  String? _statusMessage;
  ApiException? _lastApiException;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitStep1() async {
    if (!_step1FormKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _lastApiException = null;
      _statusMessage = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    try {
      final res =
          await authRepo.forgotPassword(email: _emailController.text.trim());
      final token = res['token']?.toString();

      setState(() {
        _currentStep = 2;
        if (token != null && token.isNotEmpty) {
          _tokenController.text = token;
          _statusMessage = 'Mã xác thực đã được tự động điền (Demo Mode).';
        } else {
          _statusMessage = 'Mã xác thực đã được gửi về email của bạn.';
        }
      });
    } catch (e) {
      if (e is ApiException) {
        setState(() => _lastApiException = e);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitStep2() async {
    if (!_step2FormKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _lastApiException = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    try {
      final success = await authRepo.resetPassword(
        email: _emailController.text.trim(),
        token: _tokenController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.pineDeep,
            content:
                Text('Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.'),
          ),
        );
        context.go(AppRoutes.login);
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
    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: IzithriftGlobalAppBar.subPage(
        title: _currentStep == 1 ? 'Quên mật khẩu' : 'Đặt lại mật khẩu',
        showNotificationsAction: false,
        showCartAction: false,
      ),
      body: RetroAmbientSnowflakes(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IzithriftLogo(iconSize: 34, fontSize: 20),
                const SizedBox(height: DesignTokens.spaceMd),
                // 2-Step Indicator Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.creamBadgeBg,
                    borderRadius: DesignTokens.borderRadiusFull,
                    border: Border.all(color: AppColors.creamBadgeBorder),
                  ),
                  child: Text(
                    _currentStep == 1
                        ? 'Bước 1 / 2 • Xác nhận email'
                        : 'Bước 2 / 2 • Thiết lập mật khẩu mới',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.creamBadgeText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceMd),
                Text(
                  _currentStep == 1 ? 'Khôi phục tài khoản' : 'Tạo mật khẩu mới',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.pineDeep,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceXs),
                Text(
                  _currentStep == 1
                      ? 'Nhập địa chỉ email đăng ký để nhận mã xác thực đặt lại mật khẩu.'
                      : 'Nhập mã xác thực đã nhận cùng mật khẩu mới của bạn.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceLg),

                if (_statusMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceMd),
                    decoration: BoxDecoration(
                      color: AppColors.verifiedLeafBg,
                      borderRadius: DesignTokens.borderRadiusMd,
                      border: Border.all(
                        color: AppColors.verifiedLeaf.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.verifiedLeaf,
                          size: 20,
                        ),
                        const SizedBox(width: DesignTokens.spaceSm),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.pineDeep,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                ],

                if (_lastApiException != null) ...[
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

                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: DesignTokens.borderRadiusBanner,
                    border: Border.all(color: AppColors.borderWarm),
                    boxShadow: DesignTokens.cardElevation,
                  ),
                  child: _currentStep == 1
                      ? _buildStep1Form()
                      : _buildStep2Form(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Form() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Địa chỉ Email', style: AppTypography.labelMedium),
          const SizedBox(height: DesignTokens.spaceXs),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'vidu@gmail.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Vui lòng nhập email.';
              }
              if (!val.contains('@') || !val.contains('.')) {
                return 'Email không hợp lệ.';
              }
              return null;
            },
          ),
          const SizedBox(height: DesignTokens.spaceXl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitStep1,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textLight,
                      ),
                    )
                  : const Text('Gửi mã xác thực'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Form() {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mã xác thực (Token)', style: AppTypography.labelMedium),
          const SizedBox(height: DesignTokens.spaceXs),
          TextFormField(
            controller: _tokenController,
            decoration: const InputDecoration(
              hintText: 'Nhập mã token từ email',
              prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Vui lòng nhập token.' : null,
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          Text('Mật khẩu mới', style: AppTypography.labelMedium),
          const SizedBox(height: DesignTokens.spaceXs),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Tối thiểu 8 ký tự',
              prefixIcon: Icon(Icons.lock_outline, size: 20),
            ),
            validator: (val) => val == null || val.length < 8
                ? 'Mật khẩu phải từ 8 ký tự trở lên.'
                : null,
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          Text('Xác nhận mật khẩu mới', style: AppTypography.labelMedium),
          const SizedBox(height: DesignTokens.spaceXs),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Nhập lại mật khẩu mới',
              prefixIcon: Icon(Icons.lock_reset_outlined, size: 20),
            ),
            validator: (val) => val != _passwordController.text
                ? 'Mật khẩu xác nhận không khớp.'
                : null,
          ),
          const SizedBox(height: DesignTokens.spaceXl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitStep2,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textLight,
                      ),
                    )
                  : const Text('Đặt lại mật khẩu'),
            ),
          ),
        ],
      ),
    );
  }
}
