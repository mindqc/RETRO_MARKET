import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../viewmodels/engagement_and_review_view_model.dart';

/// M-RV-01: Submit Verified Review Form Screen (/orders/:orderId/review)
class SubmitVerifiedReviewScreen extends ConsumerStatefulWidget {
  final int orderId;
  final String? orderCode;

  const SubmitVerifiedReviewScreen({
    super.key,
    required this.orderId,
    this.orderCode,
  });

  @override
  ConsumerState<SubmitVerifiedReviewScreen> createState() =>
      _SubmitVerifiedReviewScreenState();
}

class _SubmitVerifiedReviewScreenState
    extends ConsumerState<SubmitVerifiedReviewScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  String? _validationError;

  final Map<int, String> _ratingLabels = {
    1: 'Rất không hài lòng',
    2: 'Chưa ưng ý',
    3: 'Bình thường',
    4: 'Hài lòng',
    5: 'Tuyệt vời, đúng chất vintage!',
  };

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final comment = _commentController.text.trim();
    if (comment.length < 5) {
      setState(() {
        _validationError = 'Nội dung nhận xét tối thiểu 5 ký tự';
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    final reviewVm = ref.read(reviewViewModelProvider);
    final success = await reviewVm.submitVerifiedReview(
      orderId: widget.orderId,
      rating: _rating,
      comment: comment,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cảm ơn bạn! Đánh giá xác thực đã được lưu vào hồ sơ tiệm.',
            ),
            backgroundColor: AppColors.pineDeep,
          ),
        );
        context.pop(true);
      } else {
        setState(() {
          _validationError = reviewVm.errorMessage ?? 'Không thể gửi đánh giá';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewVm = ref.watch(reviewViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textCharcoal,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Đánh Giá Đơn Hàng',
          style: AppTypography.headingMedium.copyWith(fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: DesignTokens.borderRadiusLg,
                  border: Border.all(color: AppColors.borderWarm),
                  boxShadow: DesignTokens.cardElevation,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.verifiedLeafBg,
                        border: Border.all(
                          color: AppColors.verifiedLeaf.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
                        color: AppColors.verifiedLeaf,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đơn Hàng: #${widget.orderCode ?? widget.orderId}',
                            style: AppTypography.labelStrong.copyWith(
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Đã giao thành công • Đánh giá xác minh người mua thật',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Star Rating Picker Card
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: DesignTokens.borderRadiusBanner,
                  border: Border.all(color: AppColors.borderWarm),
                  boxShadow: DesignTokens.cardElevation,
                ),
                child: Column(
                  children: [
                    Text(
                      'Bạn cảm nhận thế nào về món đồ nhận được?',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelStrong.copyWith(
                        fontSize: 14.5,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        final isFilled = starValue <= _rating;
                        return IconButton(
                          iconSize: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          icon: Icon(
                            isFilled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: isFilled
                                ? AppColors.starGold
                                : AppColors.borderWarm,
                          ),
                          onPressed: () {
                            setState(() => _rating = starValue);
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.creamBadgeSoft,
                        borderRadius: DesignTokens.borderRadiusFull,
                        border: Border.all(color: AppColors.creamBadgeBorder),
                      ),
                      child: Text(
                        _ratingLabels[_rating] ?? '',
                        style: AppTypography.labelStrong.copyWith(
                          color: AppColors.ctaTerracotta,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Comment Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: DesignTokens.borderRadiusBanner,
                  border: Border.all(color: AppColors.borderWarm),
                  boxShadow: DesignTokens.cardElevation,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NHẬN XÉT CHI TIẾT',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _commentController,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText:
                            'Chia sẻ cảm nhận về tình trạng đồ si, độ chuẩn xác của mô tả và độ sạch sẽ khi nhận đồ...',
                        hintStyle: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceWarm,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: DesignTokens.borderRadiusMd,
                          borderSide:
                              const BorderSide(color: AppColors.borderWarm),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: DesignTokens.borderRadiusMd,
                          borderSide:
                              const BorderSide(color: AppColors.borderWarm),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: DesignTokens.borderRadiusMd,
                          borderSide: const BorderSide(
                            color: AppColors.pineDeep,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Trust badge note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.verifiedLeafBg,
                  borderRadius: DesignTokens.borderRadiusLg,
                  border: Border.all(
                    color: AppColors.verifiedLeaf.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 20,
                      color: AppColors.verifiedLeaf,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Đánh giá của bạn sẽ được gắn huy hiệu Đã mua hàng xác thực để tăng độ tin cậy cho cộng đồng izithrift.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.pineDeep,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_validationError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.priceCrimsonSoft,
                    borderRadius: DesignTokens.borderRadiusMd,
                    border: Border.all(color: AppColors.priceCrimsonBorder),
                  ),
                  child: Text(
                    _validationError!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.priceCrimson,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),

              // Submit CTA Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: reviewVm.isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaTerracotta,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  icon: reviewVm.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 19),
                  label: Text(
                    reviewVm.isSubmitting
                        ? 'Đang gửi đánh giá...'
                        : 'Gửi Đánh Giá Xác Thực',
                    style: AppTypography.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
