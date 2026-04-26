import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout>
    with TickerProviderStateMixin {
  DateTime? _lastPressedAt;

  void _onTap(int index, List<String> availableRoutes) {
    final route = availableRoutes[index];

    if (route == 'scan') {
      context.push('/scan');
      return;
    }

    int shellIndex = 0;
    if (route == 'home')
      shellIndex = 0;
    else if (route == 'cart')
      shellIndex = 1; // Index shifted because 'events' was index 1
    else if (route == 'bookings')
      shellIndex = 2; // Index shifted
    else if (route == 'manage')
      shellIndex = 3; // Index shifted
    else if (route == 'profile')
      shellIndex = 4; // Index shifted

    widget.navigationShell.goBranch(
      shellIndex,
      initialLocation: shellIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isManager = user?.isAdmin == true || user?.isOrganiser == true;

    final List<Map<String, dynamic>> tabs = [
      {
        'route': 'home',
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
      },
      {
        'route': 'cart',
        'icon': Icons.shopping_cart_outlined,
        'activeIcon': Icons.shopping_cart,
      },
      {
        'route': 'bookings',
        'icon': Icons.calendar_today_outlined,
        'activeIcon': Icons.calendar_today,
      },
      {
        'route': 'scan',
        'icon': Icons.qr_code_scanner_outlined,
        'activeIcon': Icons.qr_code_scanner,
      },
      if (isManager)
        {
          'route': 'manage',
          'icon': Icons.grid_view_outlined,
          'activeIcon': Icons.grid_view,
        },
      {
        'route': 'profile',
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
      },
    ];

    final availableRoutes = tabs.map((t) => t['route'] as String).toList();

    String currentRoute = 'home';
    final idx = widget.navigationShell.currentIndex;
    if (idx == 0)
      currentRoute = 'home';
    else if (idx == 1)
      currentRoute = 'cart';
    else if (idx == 2)
      currentRoute = 'bookings';
    else if (idx == 3)
      currentRoute = 'manage';
    else if (idx == 4)
      currentRoute = 'profile';

    final currentIndex = availableRoutes.indexOf(currentRoute) != -1
        ? availableRoutes.indexOf(currentRoute)
        : 0;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (widget.navigationShell.currentIndex == 0) {
          final now = DateTime.now();
          if (_lastPressedAt == null ||
              now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
            _lastPressedAt = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          SystemNavigator.pop();
          return;
        }
        widget.navigationShell.goBranch(0);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: widget.navigationShell,
        bottomNavigationBar: _buildFixedNavbar(tabs, currentIndex, availableRoutes),
      ),
    );
  }

  Widget _buildFixedNavbar(
    List<Map<String, dynamic>> tabs,
    int currentIndex,
    List<String> availableRoutes,
  ) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isSelected = index == currentIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => _onTap(index, availableRoutes),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? tab['activeIcon'] : tab['icon'],
                    color: isSelected ? const Color(0xFFFF1C7C) : Colors.white54,
                    size: 26,
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF1C7C),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
