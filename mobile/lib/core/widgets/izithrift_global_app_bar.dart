import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/widgets/auth_login_bottom_sheet.dart';
import '../../features/cart/viewmodels/cart_view_model.dart';
import '../../features/engagement/viewmodels/notification_view_model.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/seasonal_decor_provider.dart';
import 'izithrift_logo.dart';
import 'retro_design_primitives.dart';

/// Standardized global upper navigation bar across primary izithrift tabs
/// (`Trang chủ`, `Tin nhắn`, `Đấu giá`, `Cá nhân`).
///
/// Exact structure:
/// `[App Logo] [izithrift] [Flexible Empty Space] [Notifications (badge)] [Shopping Cart (badge)]`
class IzithriftGlobalAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  final List<Widget>? extraActions;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onLogoTap;

  const IzithriftGlobalAppBar({
    super.key,
    this.extraActions,
    this.bottom,
    this.onLogoTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadNotifications = ref.watch(
      notificationViewModelProvider.select((vm) => vm.unreadCount),
    );
    final cartItemsCount = ref.watch(
      cartViewModelProvider.select((vm) => vm.state.data?.totalItemsCount ?? 0),
    );
    final seasonalEnabled = ref.watch(seasonalDecorProvider);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.surfaceCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleSpacing: 16,
      title: InkWell(
        onTap: onLogoTap ?? () => context.go(AppRoutes.home),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IzithriftLogo(
                iconSize: 30,
                fontSize: 20,
                showWordmark: true,
              ),
              if (seasonalEnabled) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.ac_unit_rounded,
                  size: 13,
                  color: AppColors.starGold.withValues(alpha: 0.85),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        ...?extraActions,
        RetroHeaderIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Thông báo',
          badgeCount: unreadNotifications,
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        RetroHeaderIconButton(
          icon: Icons.shopping_cart_outlined,
          tooltip: 'Giỏ hàng',
          badgeCount: cartItemsCount,
          onPressed: () {
            final allowed = requireAuthOrPrompt(
              context,
              ref,
              featureTitle: 'Đăng nhập để mở giỏ hàng',
              description:
                  'Xem các món đồ vintage bạn đã chọn và tiến hành thanh toán an toàn qua Escrow.',
              icon: Icons.shopping_cart_outlined,
              intendedTarget: const PendingNavigationTarget(
                route: AppRoutes.cart,
              ),
            );
            if (!allowed) return;
            context.push(AppRoutes.cart);
          },
        ),
        const SizedBox(width: 6),
      ],
      bottom: bottom ??
          PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: AppColors.borderWarm,
            ),
          ),
    );
  }
}
