import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  State<FloatingAdminScreenWrapper> createState() =>
      _FloatingAdminScreenWrapperState();
}

class _FloatingAdminScreenWrapperState
    extends State<FloatingAdminScreenWrapper> {
  @override
  Widget build(BuildContext context) {
    return BottomBar(
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
      child: _buildFloatingBottomBar(),
    );
  }

  Widget _buildFloatingBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomNavItem(0, 'Profile', 'assets/images/profile.svg'),
          _buildBottomNavItem(1, 'Check-ins', 'assets/images/checkin.svg'),
          _buildBottomNavItem(2, 'Meal Plan', 'assets/images/meal.svg'),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(int index, String label, String svgPath) {
    final isSelected = widget.currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onIndexChanged(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                svgPath,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  isSelected
                      ? AppConstants.primaryColor
                      : AppConstants.textTertiary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected
                      ? AppConstants.primaryColor
                      : AppConstants.textTertiary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
