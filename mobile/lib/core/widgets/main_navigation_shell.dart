import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 5-Tab Stateful Bottom Navigation Shell (NAV-DEC-01) for izithrift.
/// Preserves the scroll and widget state of all 5 tabs using StatefulNavigationShell.
class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    const forestGreen = Color(0xFF294638);
    const vintageBrown = Color(0xFF84664C);
    const warmCream = Color(0xFFF4EBDD);
    const softBeige = Color(0xFFE9DDCB);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: warmCream,
          border: Border(
            top: BorderSide(
              color: Color(0x3384664C),
              width: 1.0,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          backgroundColor: warmCream,
          indicatorColor: softBeige,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined, color: vintageBrown),
              selectedIcon: Icon(Icons.storefront, color: forestGreen),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: Icon(Icons.manage_search_outlined, color: vintageBrown),
              selectedIcon: Icon(Icons.manage_search, color: forestGreen),
              label: 'Khám phá',
            ),
            NavigationDestination(
              icon: Icon(Icons.gavel_outlined, color: vintageBrown),
              selectedIcon: Icon(Icons.gavel, color: forestGreen),
              label: 'Đấu giá',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline, color: vintageBrown),
              selectedIcon: Icon(Icons.chat_bubble, color: forestGreen),
              label: 'Tin nhắn',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: vintageBrown),
              selectedIcon: Icon(Icons.person, color: forestGreen),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
