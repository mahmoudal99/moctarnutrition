import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingDesiredWeightStep extends StatefulWidget {
  final double desiredWeight;
  final ValueChanged<double> onDesiredWeightChanged;

  const OnboardingDesiredWeightStep({
    super.key,
    required this.desiredWeight,
    required this.onDesiredWeightChanged,
  });

  @override
  State<OnboardingDesiredWeightStep> createState() =>
      _OnboardingDesiredWeightStepState();
}

class _OnboardingDesiredWeightStepState
    extends State<OnboardingDesiredWeightStep> {
  late ScrollController _weightController;
  late double _currentWeight;

  @override
  void initState() {
    super.initState();
    _currentWeight = widget.desiredWeight;
    _initializeValues();

    // Add scroll listener to detect weight changes
    _weightController.addListener(() {
      _onWeightChanged(_weightController.offset);
    });
  }

  void _initializeValues() {
    // Clamp the initial value to ensure it's within the picker's range
    _currentWeight = _currentWeight.clamp(36.0, 100.5);

    _weightController = ScrollController(
      initialScrollOffset: _getInitialScrollOffset(),
    );
  }

  double _getInitialScrollOffset() {
    // Calculate the initial scroll offset to center the current weight
    int initialIndex = ((_currentWeight - 36.0) * 2).round();
    return initialIndex * 60.0; // 60 is the width of each item
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _onWeightChanged(double offset) {
    // Calculate which weight is currently centered
    int index = (offset / 60.0).round(); // 60 is the width of each item
    index = index.clamp(0, 129); // Ensure index is within bounds

    double newWeight = 36.0 + (index * 0.5);

    if (newWeight != _currentWeight) {
      setState(() {
        _currentWeight = newWeight;
      });

      HapticFeedback.lightImpact();
      widget.onDesiredWeightChanged(newWeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Selected Weight Display
        Text(
          '${_currentWeight.toStringAsFixed(1)} kg',
          style: AppTextStyles.heading1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: AppConstants.spacingXL),

        // Weight Selector - Ruler-like interface
        Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
          child: Stack(
            children: [
              // Ruler background with tick marks
              CustomPaint(
                size: Size.infinite,
                painter: RulerPainter(),
              ),

                            // Weight Picker - Horizontal scroll
              NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  if (notification is ScrollStartNotification) {
                    HapticFeedback.lightImpact();
                  }
                  return false;
                },
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  controller: _weightController,
                  itemCount: 130, // (100.5-36)*2 + 1
                  itemBuilder: (context, index) {
                    double weight = 36.0 + (index * 0.5);
                    bool isSelected = (weight == _currentWeight);
                    
                    return Container(
                      width: 60,
                      alignment: Alignment.center,
                      child: Text(
                        '${weight.toStringAsFixed(1)}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isSelected
                              ? AppConstants.textPrimary
                              : AppConstants.textSecondary.withOpacity(0.4),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Selection indicator - thick black line in center
              Positioned(
                top: 45,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 3,
                    height: 30,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),

              // Grey background for right side
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * 0.4,
                child: Container(
                  color: AppConstants.textTertiary.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom painter for ruler tick marks
class RulerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppConstants.textTertiary.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw vertical tick marks
    for (int i = 0; i < 50; i++) {
      double x = (size.width / 49) * i;
      double tickHeight = i % 5 == 0 ? 20 : 10; // Longer ticks every 5th mark

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, tickHeight),
        paint,
      );

      canvas.drawLine(
        Offset(x, size.height - tickHeight),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
