import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingHeightWeightStep extends StatefulWidget {
  final double height;
  final double weight;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onWeightChanged;

  const OnboardingHeightWeightStep({
    super.key,
    required this.height,
    required this.weight,
    required this.onHeightChanged,
    required this.onWeightChanged,
  });

  @override
  State<OnboardingHeightWeightStep> createState() =>
      _OnboardingHeightWeightStepState();
}

class _OnboardingHeightWeightStepState
    extends State<OnboardingHeightWeightStep> {
  bool _isImperial = true;

  // Imperial values
  int _feet = 5;
  int _inches = 6;
  int _pounds = 120;

  // Metric values
  double _centimeters = 170.0;
  double _kilograms = 70.0;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    if (_isImperial) {
      // Convert metric to imperial
      final totalInches = widget.height / 2.54;
      _feet = (totalInches / 12).floor();
      _inches = (totalInches % 12).round();
      _pounds = (widget.weight * 2.20462).round();
    } else {
      _centimeters = widget.height;
      _kilograms = widget.weight;
    }

    // Ensure values are within reasonable bounds
    _feet = _feet.clamp(2, 8);
    _inches = _inches.clamp(3, 10);
    _pounds = _pounds.clamp(80, 500);
    _centimeters = _centimeters.clamp(120.0, 220.0);
    _kilograms = _kilograms.clamp(36.0, 200.5);
  }

  void _toggleUnit() {
    HapticFeedback.lightImpact();
    setState(() {
      _isImperial = !_isImperial;
      if (_isImperial) {
        // Convert metric to imperial
        final totalInches = _centimeters / 2.54;
        _feet = (totalInches / 12).floor();
        _inches = (totalInches % 12).round();
        _pounds = (_kilograms * 2.20462).round();
      } else {
        // Convert imperial to metric
        final totalInches = (_feet * 12) + _inches;
        _centimeters = totalInches * 2.54;
        _kilograms = _pounds / 2.20462;
      }
    });
  }

  void _updateHeight() {
    if (_isImperial) {
      final totalInches = (_feet * 12) + _inches;
      final heightCm = totalInches * 2.54;
      widget.onHeightChanged(heightCm);
    } else {
      widget.onHeightChanged(_centimeters);
    }
  }

  void _updateWeight() {
    if (_isImperial) {
      final weightKg = _pounds / 2.20462;
      widget.onWeightChanged(weightKg);
    } else {
      widget.onWeightChanged(_kilograms);
    }
  }

  Widget _buildMeterDashes({
    required int totalItems,
    required double itemExtent,
    required double containerHeight,
    int majorInterval = 5,
    int minorInterval = 1,
  }) {
    return CustomPaint(
      painter: MeterDashPainter(
        totalItems: totalItems,
        itemExtent: itemExtent,
        containerHeight: containerHeight,
        majorInterval: majorInterval,
        minorInterval: minorInterval,
        dashColor: AppConstants.textSecondary.withOpacity(0.3),
        majorDashColor: AppConstants.textSecondary.withOpacity(0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Unit Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _isImperial ? null : _toggleUnit,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isImperial
                        ? AppConstants.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Imperial',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight:
                          _isImperial ? FontWeight.bold : FontWeight.normal,
                      color: _isImperial
                          ? AppConstants.surfaceColor
                          : AppConstants.textSecondary,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isImperial ? _toggleUnit : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: !_isImperial
                        ? AppConstants.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Metric',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight:
                          !_isImperial ? FontWeight.bold : FontWeight.normal,
                      color: !_isImperial
                          ? AppConstants.surfaceColor
                          : AppConstants.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.spacingXL),

        // Height and Weight Section
        Row(
          children: [
            // Height Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Height',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  if (_isImperial)
                    _buildImperialHeightPicker()
                  else
                    _buildMetricHeightPicker(),
                ],
              ),
            ),

            const SizedBox(width: AppConstants.spacingL),

            // Weight Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Weight',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  if (_isImperial)
                    _buildImperialWeightPicker()
                  else
                    _buildMetricWeightPicker(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImperialHeightPicker() {
    return Row(
      children: [
        // Feet Picker
        Expanded(
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Stack(
              children: [
                // Fade overlay at top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppConstants.surfaceColor,
                          AppConstants.surfaceColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Fade overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppConstants.surfaceColor,
                          AppConstants.surfaceColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Meter dashes
                Positioned.fill(
                  child: _buildMeterDashes(
                    totalItems: 7,
                    itemExtent: 40,
                    containerHeight: 200,
                    majorInterval: 1,
                    minorInterval: 1,
                  ),
                ),
                // Selection indicator
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppConstants.textTertiary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ListWheelScrollView(
                  itemExtent: 40,
                  diameterRatio: 1.5,
                  physics: const FixedExtentScrollPhysics(),
                  magnification: 1.1,
                  useMagnifier: true,
                  overAndUnderCenterOpacity: 0.5,
                  controller:
                      FixedExtentScrollController(initialItem: _feet - 2),
                  onSelectedItemChanged: (index) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _feet = 2 + index;
                    });
                    _updateHeight();
                  },
                  children: List.generate(7, (index) {
                    final feet = 2 + index;
                    final isSelected = _feet == feet;
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(
                          '$feet ft',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.normal,
                            color: isSelected
                                ? Colors.black
                                : AppConstants.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppConstants.spacingS),

        // Inches Picker
        Expanded(
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Stack(
              children: [
                // Fade overlay at top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppConstants.surfaceColor,
                          AppConstants.surfaceColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Fade overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppConstants.surfaceColor,
                          AppConstants.surfaceColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Meter dashes
                Positioned.fill(
                  child: _buildMeterDashes(
                    totalItems: 8,
                    itemExtent: 40,
                    containerHeight: 200,
                    majorInterval: 1,
                    minorInterval: 2,
                  ),
                ),
                // Selection indicator
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppConstants.textTertiary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ListWheelScrollView(
                  itemExtent: 40,
                  diameterRatio: 1.5,
                  physics: const FixedExtentScrollPhysics(),
                  magnification: 1.1,
                  useMagnifier: true,
                  overAndUnderCenterOpacity: 0.5,
                  controller:
                      FixedExtentScrollController(initialItem: _inches - 3),
                  onSelectedItemChanged: (index) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _inches = 3 + index;
                    });
                    _updateHeight();
                  },
                  children: List.generate(8, (index) {
                    final inches = 3 + index;
                    final isSelected = _inches == inches;
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(
                          '$inches in',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.normal,
                            color: isSelected
                                ? Colors.black
                                : AppConstants.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricHeightPicker() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Stack(
        children: [
          // Fade overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppConstants.surfaceColor,
                    AppConstants.surfaceColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Fade overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppConstants.surfaceColor,
                    AppConstants.surfaceColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Meter dashes
          Positioned.fill(
            child: _buildMeterDashes(
              totalItems: 101,
              itemExtent: 40,
              containerHeight: 200,
              majorInterval: 10,
              minorInterval: 2,
            ),
          ),
          // Selection indicator
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.textTertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          ListWheelScrollView(
            itemExtent: 40,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            magnification: 1.1,
            useMagnifier: true,
            overAndUnderCenterOpacity: 0.5,
            controller: FixedExtentScrollController(
                initialItem: (_centimeters - 120).round()),
            onSelectedItemChanged: (index) {
              HapticFeedback.lightImpact();
              setState(() {
                _centimeters = 120.0 + index;
              });
              _updateHeight();
            },
            children: List.generate(101, (index) {
              final cm = 120.0 + index;
              final isSelected = (_centimeters - cm).abs() < 1;
              return Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '${cm.toInt()} cm',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.normal,
                      color: isSelected
                          ? Colors.black
                          : AppConstants.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildImperialWeightPicker() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Stack(
        children: [
          // Fade overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppConstants.surfaceColor,
                    AppConstants.surfaceColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Fade overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppConstants.surfaceColor,
                    AppConstants.surfaceColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Meter dashes
          Positioned.fill(
            child: _buildMeterDashes(
              totalItems: 241,
              itemExtent: 40,
              containerHeight: 200,
              majorInterval: 10,
              minorInterval: 1,
            ),
          ),
          // Selection indicator
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.textTertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          ListWheelScrollView(
            itemExtent: 40,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            magnification: 1.1,
            useMagnifier: true,
            overAndUnderCenterOpacity: 0.5,
            controller: FixedExtentScrollController(initialItem: _pounds - 80),
            onSelectedItemChanged: (index) {
              HapticFeedback.lightImpact();
              setState(() {
                _pounds = 80 + index;
              });
              _updateWeight();
            },
            children: List.generate(241, (index) {
              final pounds = 80 + index;
              final isSelected = _pounds == pounds;
              return Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '$pounds lb',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.normal,
                      color: isSelected
                          ? Colors.black
                          : AppConstants.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricWeightPicker() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Stack(
        children: [
          // Fade overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppConstants.surfaceColor,
                    AppConstants.surfaceColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Fade overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppConstants.surfaceColor,
                    AppConstants.surfaceColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Meter dashes
          Positioned.fill(
            child: _buildMeterDashes(
              totalItems: 129,
              itemExtent: 40,
              containerHeight: 200,
              majorInterval: 5,
              minorInterval: 1,
            ),
          ),
          // Selection indicator
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.textTertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          ListWheelScrollView(
            itemExtent: 40,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            magnification: 1.1,
            useMagnifier: true,
            overAndUnderCenterOpacity: 0.5,
            controller: FixedExtentScrollController(
                initialItem: ((_kilograms - 36.0) / 0.5).round()),
            onSelectedItemChanged: (index) {
              HapticFeedback.lightImpact();
              setState(() {
                _kilograms = 36.0 + (index * 0.5);
              });
              _updateWeight();
            },
            children: List.generate(129, (index) {
              final kg = 36.0 + (index * 0.5);
              final isSelected = (_kilograms - kg).abs() < 0.25;
              return Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '${kg.toStringAsFixed(1)} kg',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.normal,
                      color: isSelected
                          ? Colors.black
                          : AppConstants.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class MeterDashPainter extends CustomPainter {
  final int totalItems;
  final double itemExtent;
  final double containerHeight;
  final int majorInterval;
  final int minorInterval;
  final Color dashColor;
  final Color majorDashColor;

  MeterDashPainter({
    required this.totalItems,
    required this.itemExtent,
    required this.containerHeight,
    required this.majorInterval,
    required this.minorInterval,
    required this.dashColor,
    required this.majorDashColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final startY = (containerHeight - (totalItems * itemExtent)) / 2;

    // Draw dashes for each item
    for (int i = 0; i < totalItems; i++) {
      final y = startY + (i * itemExtent) + (itemExtent / 2);

      if (y >= 0 && y <= containerHeight) {
        final isMajor = i % majorInterval == 0;
        final isMinor = i % minorInterval == 0 && !isMajor;

        if (isMajor || isMinor) {
          paint.color = isMajor ? majorDashColor : dashColor;

          // Draw dash only on the left side
          final dashLength = isMajor ? 12.0 : 8.0;
          final leftEdge = 6.0; // Distance from left edge
          final dashStartX = leftEdge;
          final dashEndX = dashStartX + dashLength;

          canvas.drawLine(
            Offset(dashStartX, y),
            Offset(dashEndX, y),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
