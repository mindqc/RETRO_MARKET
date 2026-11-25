import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import 'sell_action_bottom_sheet.dart';

/// 5-destination bottom navigation bar for izithrift:
/// `Trang chủ` | `Tin nhắn` | **[+ Đăng bán]** | `Đấu giá` | `Cá nhân`
///
/// - Branches: [0] Home, [1] Messages, [2] Auctions, [3] Profile
/// - Center slot triggers the elevated Terracotta (#C65335) Sell Action Bottom Sheet
/// - Active tab highlight uses Deep Pine Green (#174D38)
/// - Explore tab has been removed from bottom navigation (kept as pushable route)
class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onBranchSelected(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
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
          border: Border(
            top: BorderSide(
              color: AppColors.borderWarm,
              width: DesignTokens.borderThin,
            ),
          ),
          boxShadow: DesignTokens.bottomNavElevation,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Trang chủ (Branch 0)
                    Expanded(
                      child: _BottomNavTabButton(
                        label: 'Trang chủ',
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        isSelected: currentIndex == 0,
                        onTap: () => _onBranchSelected(0),
                      ),
                    ),

                    // 2. Tin nhắn (Branch 1)
                    Expanded(
                      child: _BottomNavTabButton(
                        label: 'Tin nhắn',
                        icon: Icons.chat_bubble_outline_rounded,
                        activeIcon: Icons.chat_bubble_rounded,
                        isSelected: currentIndex == 1,
                        onTap: () => _onBranchSelected(1),
                      ),
                    ),

                    // 3. Spacer slot reserved for elevated central "Đăng bán"
                    const Expanded(child: SizedBox.shrink()),

                    // 4. Đấu giá (Branch 2)
                    Expanded(
                      child: _BottomNavTabButton(
                        label: 'Đấu giá',
                        icon: Icons.gavel_outlined,
                        activeIcon: Icons.gavel_rounded,
                        isSelected: currentIndex == 2,
                        onTap: () => _onBranchSelected(2),
                      ),
                    ),

                    // 5. Cá nhân (Branch 3)
                    Expanded(
                      child: _BottomNavTabButton(
                        label: 'Cá nhân',
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        isSelected: currentIndex == 3,
                        onTap: () => _onBranchSelected(3),
                      ),
                    ),
                  ],
                ),
                // Elevated circular central Sell action button
                Positioned(
                  top: -16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _CentralSellNavButton(
                      onTap: () => showSellActionBottomSheet(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavTabButton({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = isSelected ? AppColors.pineDeep : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: DesignTokens.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 23,
              color: fgColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 10.5,
                color: fgColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isSelected ? 20 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.pineDeep : Colors.transparent,
                borderRadius: DesignTokens.borderRadiusFull,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CentralSellNavButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CentralSellNavButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceCard,
              boxShadow: [
                BoxShadow(
                  color: AppColors.ctaTerracotta.withValues(alpha: 0.30),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            padding: const EdgeInsets.all(3.5),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.ctaTerracotta, AppColors.ctaTerracottaHover],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Đăng bán',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: 10.5,
              color: AppColors.ctaTerracotta,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
