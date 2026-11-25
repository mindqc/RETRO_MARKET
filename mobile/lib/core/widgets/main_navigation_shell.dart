import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// Five-tab stateful navigation shell (NAV-DEC-01) for izithrift.
/// Styled after the approved Cozy Vintage Editorial reference:
/// - Elevated crisp-white rounded-top bar (24px top radius + soft upward shadow)
/// - Festive crimson active icon, bold label, and bottom pill accent bar
/// - Clean outlined charcoal inactive icons
class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    _NavItem(
      label: 'Trang chủ',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: 'Khám phá',
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
    ),
    _NavItem(
      label: 'Đấu giá',
      icon: Icons.gavel_outlined,
      activeIcon: Icons.gavel_rounded,
    ),
    _NavItem(
      label: 'Tin nhắn',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
    ),
    _NavItem(
      label: 'Cá nhân',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusXl),
          ),
          border: Border(
            top: BorderSide(
              color: AppColors.borderSubtle,
              width: DesignTokens.borderThin,
            ),
          ),
          boxShadow: DesignTokens.bottomNavElevation,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final isSelected = index == currentIndex;
                final fgColor = isSelected
                    ? AppColors.priceCrimson
                    : AppColors.textCharcoal;

                return Expanded(
                  child: InkWell(
                    onTap: () => _onDestinationSelected(index),
                    borderRadius: DesignTokens.borderRadiusMd,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 24,
                            color: fgColor,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              color: fgColor,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: isSelected ? 22 : 0,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.priceCrimson
                                  : Colors.transparent,
                              borderRadius: DesignTokens.borderRadiusFull,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
