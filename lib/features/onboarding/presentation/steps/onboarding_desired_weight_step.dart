import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../../shared/models/user_model.dart';

class OnboardingDesiredWeightStep extends StatefulWidget {
  final double desiredWeight;
  final double currentWeight;
  final FitnessGoal fitnessGoal;
  final ValueChanged<double> onDesiredWeightChanged;

  const OnboardingDesiredWeightStep({
    super.key,
    required this.desiredWeight,
    required this.currentWeight,
    required this.fitnessGoal,
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
    // Get min and max weight based on fitness goal
    final (minWeight, maxWeight) = _getWeightRange();
    
    // If desired weight is outside the allowed range, set a sensible default
    if (_currentWeight < minWeight || _currentWeight > maxWeight) {
      switch (widget.fitnessGoal) {
        case FitnessGoal.weightLoss:
          // Set to 5kg less than current weight, but not below minimum
          _currentWeight = (widget.currentWeight - 5.0).clamp(minWeight, maxWeight);
          break;
        case FitnessGoal.weightGain:
          // Set to 5kg more than current weight, but not above maximum
          _currentWeight = (widget.currentWeight + 5.0).clamp(minWeight, maxWeight);
          break;
        default:
          // Clamp to allowed range
          _currentWeight = _currentWeight.clamp(minWeight, maxWeight);
      }
      // Update the desired weight in the parent
      widget.onDesiredWeightChanged(_currentWeight);
    } else {
      // Clamp the initial value to ensure it's within the allowed range
      _currentWeight = _currentWeight.clamp(minWeight, maxWeight);
    }

    _weightController = ScrollController(
      initialScrollOffset: _getInitialScrollOffset(),
    );
  }

  (double, double) _getWeightRange() {
    switch (widget.fitnessGoal) {
      case FitnessGoal.weightLoss:
        // For weight loss, only allow weights lower than current weight
        final maxWeight = widget.currentWeight - 0.5;
        // Ensure we have a valid range (at least 0.5kg difference)
        if (maxWeight < 36.0) {
          // If current weight is too low, allow a small range around minimum
          return (36.0, 36.5);
        }
        return (36.0, maxWeight);
      case FitnessGoal.weightGain:
        // For weight gain, only allow weights higher than current weight
        final minWeight = widget.currentWeight + 0.5;
        // Ensure we have a valid range
        if (minWeight > 100.5) {
          // If current weight is too high, allow a small range around maximum
          return (100.0, 100.5);
        }
        return (minWeight, 100.5);
      default:
        // For other goals, allow full range
        return (36.0, 100.5);
    }
  }

  double _getInitialScrollOffset() {
    // Get min weight for calculation
    final (minWeight, _) = _getWeightRange();
    // Calculate the initial scroll offset to center the current weight
    int initialIndex = ((_currentWeight - minWeight) * 2).round();
    return initialIndex * 60.0; // 60 is the width of each item
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _onWeightChanged(double offset) {
    // Get weight range based on fitness goal
    final (minWeight, maxWeight) = _getWeightRange();
    
    // Calculate which weight is currently centered
    int index = (offset / 60.0).round(); // 60 is the width of each item
    
    // Calculate total possible items in the allowed range
    int totalItems = ((maxWeight - minWeight) * 2).round() + 1;
    index = index.clamp(0, totalItems - 1); // Ensure index is within bounds

    double newWeight = minWeight + (index * 0.5);
    
    // Clamp to ensure it's within the allowed range
    newWeight = newWeight.clamp(minWeight, maxWeight);

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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Selected Weight Display
            Text(
              '${_currentWeight.toStringAsFixed(1)} kg',
              style: AppTextStyles.heading4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Weight Selector - Ruler-like interface
            Container(
              height: 100,
              margin:
                  const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final (minWeight, maxWeight) = _getWeightRange();
                        final itemCount = ((maxWeight - minWeight) * 2).round() + 1;
                        
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          controller: _weightController,
                          padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth / 2 - 30),
                          // Half container width minus half item width
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            double weight = minWeight + (index * 0.5);
                            bool isSelected = (weight == _currentWeight);
                            bool isDisabled = _isWeightDisabled(weight);
                            return _buildWeightItem(weight, isSelected, isDisabled);
                          },
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
        ),
      ),
    );
  }

  bool _isWeightDisabled(double weight) {
    switch (widget.fitnessGoal) {
      case FitnessGoal.weightLoss:
        return weight >= widget.currentWeight;
      case FitnessGoal.weightGain:
        return weight <= widget.currentWeight;
      default:
        return false;
    }
  }

  Widget _buildWeightItem(double weight, bool isSelected, bool isDisabled) {
    return Container(
      width: 60,
      alignment: Alignment.center,
      child: Text(
        '${weight.toStringAsFixed(1)}',
        style: AppTextStyles.bodyLarge.copyWith(
          color: isDisabled
              ? AppConstants.textTertiary.withOpacity(0.2)
              : (isSelected
                  ? AppConstants.textPrimary
                  : AppConstants.textSecondary.withOpacity(0.4)),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
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
