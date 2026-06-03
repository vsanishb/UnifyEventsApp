import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
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
    else if (route == 'events')
      shellIndex = 1;
    else if (route == 'cart')
      shellIndex = 2;
    else if (route == 'bookings')
      shellIndex = 3;
    else if (route == 'manage')
      shellIndex = 4;
    else if (route == 'profile')
      shellIndex = 5;

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
        'activeIcon': Icons.home_rounded,
        'label': 'Home',
      },
      {
        'route': 'bookings',
        'icon': Icons.confirmation_number_outlined,
        'activeIcon': Icons.confirmation_number_rounded,
        'label': 'Bookings',
      },
      {
        'route': 'cart',
        'icon': Icons.shopping_cart_outlined,
        'activeIcon': Icons.shopping_cart_rounded,
        'label': 'Cart',
      },
      if (isManager)
        {
          'route': 'scan',
          'icon': Icons.qr_code_scanner_outlined,
          'activeIcon': Icons.qr_code_scanner_rounded,
          'label': 'Scan',
        },
      if (isManager)
        {
          'route': 'manage',
          'icon': Icons.dashboard_customize_outlined,
          'activeIcon': Icons.dashboard_customize_rounded,
          'label': 'Manage',
        },
      {
        'route': 'profile',
        'icon': Icons.person_outline,
        'activeIcon': Icons.person_rounded,
        'label': 'Profile',
      },
    ];

    final availableRoutes = tabs.map((t) => t['route'] as String).toList();

    String currentRoute = 'home';
    final idx = widget.navigationShell.currentIndex;
    if (idx == 0)
      currentRoute = 'home';
    else if (idx == 1)
      currentRoute = 'events'; // Map to Explorer if needed, but visually home/bookings/cart/profile is shown
    else if (idx == 2)
      currentRoute = 'cart';
    else if (idx == 3)
      currentRoute = 'bookings';
    else if (idx == 4)
      currentRoute = 'manage';
    else if (idx == 5)
      currentRoute = 'profile';

    // Fallback logic to map visual tab index
    // Note: since the shell contains 6 branches (home, events, cart, bookings, manage, profile)
    // we want to ensure visual index represents the correct active route
    int currentIndex = availableRoutes.indexOf(currentRoute);
    if (currentIndex == -1) {
      if (currentRoute == 'events') {
        currentIndex = availableRoutes.indexOf('home'); // Map explorer to home visually if needed
      } else {
        currentIndex = 0;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        final curIdx = widget.navigationShell.currentIndex;

        if (curIdx == 0) {
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
        backgroundColor: const Color(0xFF0F0E11),
        body: widget.navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0E11),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.04),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(tabs.length, (index) {
                  final tab = tabs[index];
                  final isSelected = index == currentIndex;
                  final color = isSelected ? const Color(0xFFFECF65) : Colors.white30;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onTap(index, availableRoutes),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? tab['activeIcon'] : tab['icon'],
                            color: color,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab['label'],
                            style: GoogleFonts.breeSerif(
                              color: color,
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
