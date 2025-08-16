import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../../core/constants/app_constants.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class MainNavigation extends StatefulWidget {
  final Widget child;

  const MainNavigation({
    super.key,
    required this.child,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  static final _logger = Logger();
  int _currentIndex = 0;

  List<_NavItem> _buildNavItems(UserModel? user) {
    _logger.d(
        'MainNavigation - Building nav items for user: ${user?.name ?? 'null'} with role: ${user?.role ?? 'null'}');

    if (user != null && user.role == UserRole.admin) {
      _logger.d('MainNavigation - Building ADMIN navigation items');
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
        // const _NavItem(
        //   icon: Icons.person,
        //   label: 'Trainers',
        //   route: '/trainers',
        // ),
        const _NavItem(
          icon: Icons.account_circle,
          label: 'Profile',
          route: '/profile',
        ),
      ];
    }
    // Non-admins: original tabs
    _logger.d('MainNavigation - Building USER navigation items');
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
      // const _NavItem(
      //   icon: Icons.person,
      //   label: 'Trainers',
      //   route: '/trainers',
      // ),
      const _NavItem(
        icon: Icons.account_circle,
        label: 'Profile',
        route: '/profile',
      ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set the current index based on the current route
    final location = GoRouter.of(context).routeInformationProvider.value.uri;
    // We'll update _currentIndex in build based on nav items
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel;

        // Debug logging
        _logger.d('MainNavigation - AuthProvider state:');
        _logger.d('  isLoading: ${authProvider.isLoading}');
        _logger.d('  isAuthenticated: ${authProvider.isAuthenticated}');
        _logger.d('  user: ${user?.name ?? 'null'}');
        _logger.d('  user role: ${user?.role ?? 'null'}');

        final items = _buildNavItems(user);
        // Find the current index based on the current route
        final location =
            GoRouter.of(context).routeInformationProvider.value.uri.toString();
        final idx = items.indexWhere((item) => location == item.route);
        final currentIndex = idx != -1 ? idx : _currentIndex;
        
        // Only show bottom navigation bar for main tab routes
        final shouldShowBottomNav = idx != -1;
        
        return Scaffold(
          body: widget.child,
          bottomNavigationBar: shouldShowBottomNav
              ? BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                    context.go(items[index].route);
                  },
                  selectedItemColor: AppConstants.primaryColor,
                  unselectedItemColor: AppConstants.textTertiary,
                  showUnselectedLabels: true,
                  items: items
                      .map((item) => BottomNavigationBarItem(
                            icon: Icon(item.icon),
                            label: item.label,
                          ))
                      .toList(),
                )
              : null,
        );
      },
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
