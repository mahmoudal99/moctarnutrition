import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WorkoutScrollController {
  late ScrollController scrollController;
  late AnimationController toggleAnimationController;
  late Animation<double> toggleOpacityAnimation;
  late Animation<double> toggleScaleAnimation;

  double scrollOffset = 0.0;
  static const double scrollThreshold = 100.0;

  void initialize(TickerProvider vsync) {
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);

    toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );

    toggleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: toggleAnimationController,
      curve: Curves.easeInOut,
    ));

    toggleScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: toggleAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  void _onScroll() {
    scrollOffset = scrollController.offset;

    if (scrollOffset > scrollThreshold &&
        toggleAnimationController.value == 0) {
      toggleAnimationController.forward();
      // Add haptic feedback when toggle appears
      HapticFeedback.selectionClick();
    } else if (scrollOffset <= scrollThreshold &&
        toggleAnimationController.value == 1) {
      toggleAnimationController.reverse();
    }
  }

  void dispose() {
    scrollController.dispose();
    toggleAnimationController.dispose();
  }
}
