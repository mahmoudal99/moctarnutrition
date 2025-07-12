import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';

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
  int _currentIndex = 0;

  final List<_NavItem> _items = [
    _NavItem(
      icon: Icons.fitness_center,
      label: 'Workouts',
      route: '/workouts',
    ),
    _NavItem(
      icon: Icons.restaurant_menu,
      label: 'Meal Prep',
      route: '/meal-prep',
    ),
    _NavItem(
      icon: Icons.person,
      label: 'Trainers',
      route: '/trainers',
    ),
    _NavItem(
      icon: Icons.account_circle,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set the current index based on the current route
    final location = GoRouter.of(context).routeInformationProvider.value.uri;
    final idx = _items.indexWhere((item) => location == item.route);
    if (idx != -1 && idx != _currentIndex) {
      setState(() {
        _currentIndex = idx;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          context.go(_items[index].route);
        },
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.textTertiary,
        showUnselectedLabels: true,
        items: _items
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
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