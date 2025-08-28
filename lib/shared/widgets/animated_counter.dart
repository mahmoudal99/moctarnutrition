import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated counter widget that smoothly animates between different values
class AnimatedCounter extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String? suffix;
  final String? prefix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.suffix,
    this.prefix,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;
  double _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _currentValue = widget.value;
    _previousValue = widget.value;

    // Start the initial animation
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      print(
          'AnimatedCounter - Value changed from $_previousValue to ${widget.value}');
      _previousValue = _currentValue;
      _currentValue = widget.value;

      // Reset and start the animation
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedValue = _previousValue +
            (_currentValue - _previousValue) * _animation.value;

        final displayValue = animatedValue.isNaN ? 0.0 : animatedValue;

        return Text(
          '${widget.prefix ?? ''}${displayValue.round()}${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}
