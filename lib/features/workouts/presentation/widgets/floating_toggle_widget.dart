import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/view_toggle.dart';

class FloatingToggleWidget extends StatelessWidget {
  final WorkoutViewType selectedView;
  final Function(WorkoutViewType) onViewChanged;
  final Animation<double> opacityAnimation;
  final Animation<double> scaleAnimation;

  const FloatingToggleWidget({
    super.key,
    required this.selectedView,
    required this.onViewChanged,
    required this.opacityAnimation,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: opacityAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: scaleAnimation.value,
              child: Opacity(
                opacity: opacityAnimation.value,
                child: _buildToggleContainer(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildToggleContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ViewToggle(
        selectedView: selectedView,
        onViewChanged: onViewChanged,
        isFloating: true,
      ),
    );
  }
}
