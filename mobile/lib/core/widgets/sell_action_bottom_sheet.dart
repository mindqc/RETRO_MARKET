import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// Opens the central "Đăng bán" action bottom sheet from the bottom navigation bar.
///
/// Gives users two clear selling flows:
/// 1. Đăng bán sản phẩm (fixed-price secondhand listing -> PENDING_REVIEW)
/// 2. Tạo phiên đấu giá (scheduled/live auction listing -> PENDING_REVIEW)
Future<void> showSellActionBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceCard,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.radiusXl),
      ),
    ),
    builder: (sheetContext) => const _SellActionBottomSheetContent(),
  );
}

class _SellActionBottomSheetContent extends StatelessWidget {
  const _SellActionBottomSheetContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.ctaTerracottaSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_business_rounded,
                    color: AppColors.ctaTerracotta,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bạn muốn đăng gì hôm nay?',
                        style: AppTypography.headingSmall.copyWith(
                          fontSize: 17,
                          color: AppColors.textCharcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bài đăng mới sẽ được đội ngũ izithrift kiểm duyệt trước khi hiển thị.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SellOptionCard(
              icon: Icons.sell_outlined,
              iconBg: AppColors.primaryForestGreenLight,
              iconColor: AppColors.pineDeep,
              title: 'Đăng bán sản phẩm',
              description:
                  'Đăng món đồ với giá cố định. Người mua có thể đặt mua ngay.',
              badgeLabel: 'Giá cố định',
              badgeColor: AppColors.pineDeep,
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.sellerCreateListing);
              },
            ),
            const SizedBox(height: 12),
            _SellOptionCard(
              icon: Icons.gavel_rounded,
              iconBg: AppColors.ctaTerracottaSoft,
              iconColor: AppColors.ctaTerracotta,
              title: 'Tạo phiên đấu giá',
              description:
                  'Tạo phiên đấu giá với giá khởi điểm và thời gian tham gia.',
              badgeLabel: 'Đấu giá',
              badgeColor: AppColors.ctaTerracotta,
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.sellerCreateAuction);
              },
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.canvasParchment,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderWarm),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: AppColors.pineDeep,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mọi tin đăng đều qua bước duyệt minh bạch để bảo vệ người mua & người bán.',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final String badgeLabel;
  final Color badgeColor;
  final VoidCallback onTap;

  const _SellOptionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.badgeLabel,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderWarm, width: 1.2),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelStrong.copyWith(
                              fontSize: 15,
                              color: AppColors.textCharcoal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
