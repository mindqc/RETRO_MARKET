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
  ConsumerState<SubmitVerifiedReviewScreen> createState() => _SubmitVerifiedReviewScreenState();
}

class _SubmitVerifiedReviewScreenState extends ConsumerState<SubmitVerifiedReviewScreen> {
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
            content: Text('Cảm ơn bạn! Đánh giá xác thực đã được lưu vào hồ sơ tiệm.'),
            backgroundColor: AppColors.secondaryPineGreen,
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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textCharcoal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Đánh Giá Đơn Hàng',
          style: AppTypography.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textCharcoal,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.borderWarm,
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header Card
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceMd),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                border: Border.all(color: AppColors.borderWarm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, color: AppColors.secondaryPineGreen, size: 28),
                  const SizedBox(width: DesignTokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn Hàng: #${widget.orderCode ?? widget.orderId}',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Đã giao thành công • Đánh giá xác minh người mua thật',
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceXl),

            // Star Rating Picker
            Center(
              child: Column(
                children: [
                  Text(
                    'Bạn cảm nhận thế nào về món đồ nhận được?',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textCharcoal,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final isFilled = starValue <= _rating;
                      return IconButton(
                        iconSize: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        icon: Icon(
                          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isFilled ? AppColors.accentVintageGold : AppColors.borderWarm,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = starValue;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Text(
                    _ratingLabels[_rating] ?? '',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTerracotta,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceXl),

            // Comment text area
            Text(
              'NHẬN XÉT CHI TIẾT',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textCharcoal,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Chia sẻ cảm nhận về tình trạng đồ si, độ chuẩn xác của mô tả và độ sạch sẽ khi nhận đồ...',
                hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceCard,
                contentPadding: const EdgeInsets.all(DesignTokens.spaceMd),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  borderSide: const BorderSide(color: AppColors.borderWarm),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  borderSide: const BorderSide(color: AppColors.borderWarm),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  borderSide: const BorderSide(color: AppColors.primaryTerracotta, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMd),

            // Trust badge note
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceMd),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EFE6),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                border: Border.all(color: AppColors.borderWarm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 20, color: AppColors.secondaryPineGreen),
                  const SizedBox(width: DesignTokens.spaceSm),
                  Expanded(
                    child: Text(
                      'Đánh giá của bạn sẽ được gắn huy hiệu Đã mua hàng xác thực để tăng độ tin cậy cho cộng đồng izithrift.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textCharcoal,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_validationError != null) ...[
              const SizedBox(height: DesignTokens.spaceMd),
              Text(
                _validationError!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.statusDanger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            const SizedBox(height: DesignTokens.spaceXl),

            // Submit CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: reviewVm.isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTerracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
                icon: reviewVm.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(
                  reviewVm.isSubmitting ? 'Đang gửi đánh giá...' : 'Gửi Đánh Giá Xác Thực',
                  style: AppTypography.button.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
