import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/widgets/auth_login_bottom_sheet.dart';
import '../../features/cart/viewmodels/cart_view_model.dart';
import '../../features/engagement/viewmodels/notification_view_model.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/seasonal_decor_provider.dart';
import 'izithrift_logo.dart';
import 'retro_design_primitives.dart';

/// Identifies the currently active screen/destination in the standardized
/// Upper Navigation bar so Home and sub-screens share consistent active styling.
enum IzithriftUpperNavDestination {
  none,
  home,
  discover,
  messages,
  auctions,
  profile,
  notifications,
  cart,
}

/// Standardized global upper navigation bar shared across BOTH root tabs
/// (`Home`, `Messages`, `Auctions`, `Profile`) and sub-screens
/// (`CategoryTaxonomy`, `FeaturedSellers`, `ProductSearch`, `ProductDetail`,
/// `Notifications`, `Cart`, `Auth`).
///
/// Guarantees unified height ([toolbarHeight]), warm ivory-cream surface,
/// hairline bottom border, consistent spacing, and clear active state styling.
class IzithriftGlobalAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  static const double toolbarHeight = 58.0;

  final bool isSubPage;
  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final bool showBrandMark;
  final bool showNotificationsAction;
  final bool showCartAction;
  final IzithriftUpperNavDestination activeDestination;
  final List<Widget>? extraActions;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onLogoTap;
  final VoidCallback? onBackPressed;

  /// Root navigation upper bar (`[izithrift Logo] ... [Notifications] [Cart]`).
  const IzithriftGlobalAppBar({
    super.key,
    this.activeDestination = IzithriftUpperNavDestination.none,
    this.extraActions,
    this.bottom,
    this.onLogoTap,
    this.showNotificationsAction = true,
    this.showCartAction = true,
  })  : isSubPage = false,
        title = null,
        titleWidget = null,
        showBackButton = false,
        showBrandMark = false,
        onBackPressed = null;

  /// Sub-screen upper navigation bar sharing identical height, cream surface,
  /// border hairline, back affordance, and active destination states.
  const IzithriftGlobalAppBar.subPage({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = true,
    this.showBrandMark = false,
    this.showNotificationsAction = true,
    this.showCartAction = true,
    this.activeDestination = IzithriftUpperNavDestination.none,
    this.extraActions,
    this.bottom,
    this.onBackPressed,
  })  : isSubPage = true,
        onLogoTap = null;

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 1.0),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadNotifications = showNotificationsAction
        ? ref.watch(
            notificationViewModelProvider.select((vm) => vm.unreadCount),
          )
        : 0;
    final cartItemsCount = showCartAction
        ? ref.watch(
            cartViewModelProvider
                .select((vm) => vm.state.data?.totalItemsCount ?? 0),
          )
        : 0;
    final seasonalEnabled =
        !isSubPage ? ref.watch(seasonalDecorProvider) : false;

    final isHomeActive = activeDestination == IzithriftUpperNavDestination.home;
    final isNotificationsActive =
        activeDestination == IzithriftUpperNavDestination.notifications;
    final isCartActive = activeDestination == IzithriftUpperNavDestination.cart;

    return AppBar(
      toolbarHeight: toolbarHeight,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.surfaceCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      leadingWidth: isSubPage && showBackButton ? 52 : null,
      leading: isSubPage && showBackButton
          ? Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Material(
                  color: AppColors.canvasParchment,
                  shape: const CircleBorder(
                    side: BorderSide(color: AppColors.borderWarm, width: 1),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textCharcoal,
                      size: 20,
                    ),
                    tooltip: 'Quay lại',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: onBackPressed ??
                        () {
                          final navigator = Navigator.of(context);
                          if (navigator.canPop()) {
                            navigator.pop();
                          } else {
                            context.go(AppRoutes.home);
                          }
                        },
                  ),
                ),
              ),
            )
          : null,
      titleSpacing: isSubPage
          ? (showBackButton ? 6 : 16)
          : 16,
      title: isSubPage
          ? _buildSubPageTitle()
          : _buildRootBrandTitle(
              context,
              isHomeActive: isHomeActive,
              seasonalEnabled: seasonalEnabled,
            ),
      actions: [
        ...?extraActions,
        if (showNotificationsAction)
          RetroHeaderIconButton(
            icon: Icons.notifications_none_rounded,
            activeIcon: Icons.notifications_rounded,
            tooltip: 'Thông báo',
            badgeCount: unreadNotifications,
            isActive: isNotificationsActive,
            onPressed: () {
              if (isNotificationsActive) return;
              context.push(AppRoutes.notifications);
            },
          ),
        if (showCartAction)
          RetroHeaderIconButton(
            icon: Icons.shopping_cart_outlined,
            activeIcon: Icons.shopping_cart_rounded,
            tooltip: 'Giỏ hàng',
            badgeCount: cartItemsCount,
            isActive: isCartActive,
            onPressed: () {
              if (isCartActive) return;
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
        const SizedBox(width: 8),
      ],
      bottom: bottom ??
          const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: ColoredBox(
              color: AppColors.borderWarm,
              child: SizedBox(height: 1, width: double.infinity),
            ),
          ),
    );
  }

  Widget _buildRootBrandTitle(
    BuildContext context, {
    required bool isHomeActive,
    required bool seasonalEnabled,
  }) {
    return InkWell(
      onTap: onLogoTap ?? () => context.go(AppRoutes.home),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: isHomeActive
              ? AppColors.primaryForestGreenLight.withValues(alpha: 0.65)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isHomeActive
              ? Border.all(
                  color: AppColors.pineDeep.withValues(alpha: 0.16),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IzithriftLogo(
              iconSize: 30,
              fontSize: 20,
              showWordmark: true,
            ),
            if (seasonalEnabled) ...[
              const SizedBox(width: 5),
              Icon(
                Icons.auto_awesome_rounded,
                size: 13,
                color: AppColors.starGold.withValues(alpha: 0.90),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubPageTitle() {
    if (titleWidget != null) {
      return titleWidget!;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBrandMark) ...[
          const IzithriftLogo.iconOnly(iconSize: 26),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            title ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headingSmall.copyWith(
              fontSize: 17,
              color: AppColors.pineDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
