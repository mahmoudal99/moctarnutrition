import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';

class FloatingAdminScreenWrapper extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onIndexChanged;

  const FloatingAdminScreenWrapper({
    Key? key,
    required this.child,
    required this.currentIndex,
    required this.onIndexChanged,
  }) : super(key: key);

  @override
  State<FloatingAdminScreenWrapper> createState() => _FloatingAdminScreenWrapperState();
}

class _FloatingAdminScreenWrapperState extends State<FloatingAdminScreenWrapper> {
  @override
  Widget build(BuildContext context) {
    return BottomBar(
      child: _buildFloatingBottomBar(),
      body: (context, controller) => NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Handle scroll notifications if needed
          return false;
        },
        child: widget.child,
      ),
      borderRadius: BorderRadius.circular(25),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: MediaQuery.of(context).size.width * 0.9,
      barColor: Colors.white,
      start: 2,
      end: 0,
      offset: 16,
      barAlignment: Alignment.bottomCenter,
      hideOnScroll: false,
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
    );
  }

  Widget _buildFloatingBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomNavItem(0, 'Profile'),
          _buildBottomNavItem(1, 'Check-ins'),
          _buildBottomNavItem(2, 'Meal Plan'),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(int index, String label) {
    final isSelected = widget.currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onIndexChanged(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? AppConstants.primaryColor : AppConstants.textTertiary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
} 