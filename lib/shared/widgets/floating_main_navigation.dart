import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import '../../core/constants/app_constants.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class FloatingMainNavigation extends StatefulWidget {
  final Widget child;

  const FloatingMainNavigation({
    super.key,
    required this.child,
  });

  @override
  State<FloatingMainNavigation> createState() => _FloatingMainNavigationState();
}

class _FloatingMainNavigationState extends State<FloatingMainNavigation> {
  int _currentIndex = 0;

  List<_NavItem> _buildNavItems(UserModel? user) {
    print(
        'FloatingMainNavigation - Building nav items for user: ${user?.name ?? 'null'} with role: ${user?.role ?? 'null'}');

    if (user != null && user.role == UserRole.admin) {
      print('FloatingMainNavigation - Building ADMIN navigation items');
      return [
        const _NavItem(
          icon: Icons.home,
          label: 'Home',
          route: '/admin-home',
        ),
        const _NavItem(
          icon: Icons.group,
          label: 'Clients',
          route: '/admin-users',
        ),
        const _NavItem(
          icon: Icons.account_circle,
          label: 'Profile',
          route: '/profile',
        ),
      ];
    }
    // Non-admins: original tabs
    print('FloatingMainNavigation - Building USER navigation items');
    return [
      const _NavItem(
        icon: Icons.fitness_center,
        label: 'Workouts',
        route: '/workouts',
      ),
      const _NavItem(
        icon: Icons.restaurant_menu,
        label: 'Meal Prep',
        route: '/meal-prep',
      ),
      const _NavItem(
        icon: Icons.account_circle,
        label: 'Profile',
        route: '/profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel;

        // Debug logging
        print('FloatingMainNavigation - AuthProvider state:');
        print('  isLoading: ${authProvider.isLoading}');
        print('  isAuthenticated: ${authProvider.isAuthenticated}');
        print('  user: ${user?.name ?? 'null'}');
        print('  user role: ${user?.role ?? 'null'}');

        final items = _buildNavItems(user);
        // Find the current index based on the current route
        final location =
            GoRouter.of(context).routeInformationProvider.value.uri.toString();
        final idx = items.indexWhere((item) => location == item.route);
        final currentIndex = idx != -1 ? idx : _currentIndex;

        return BottomBar(
          body: (context, controller) => widget.child,
          borderRadius: BorderRadius.circular(25),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: MediaQuery.of(context).size.width * 0.9,
          barColor: Colors.white,
          start: 2,
          end: 0,
          offset: 16,
          barAlignment: Alignment.bottomCenter,
          hideOnScroll: true,
          showIcon: false,
          barDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _buildFloatingBottomBar(items, currentIndex, context),
        );
      },
    );
  }

  Widget _buildFloatingBottomBar(List<_NavItem> items, int currentIndex, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = currentIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
                context.go(item.route);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected ? AppConstants.primaryColor : AppConstants.textTertiary,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected ? AppConstants.primaryColor : AppConstants.textTertiary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
} 