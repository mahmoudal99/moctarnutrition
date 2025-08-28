import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class ProgressMetricsForm extends StatefulWidget {
  final TextEditingController weightController;
  final Map<String, double> measurements;
  final Function(Map<String, double>) onMeasurementsChanged;

  const ProgressMetricsForm({
    super.key,
    required this.weightController,
    required this.measurements,
    required this.onMeasurementsChanged,
  });

  @override
  State<ProgressMetricsForm> createState() => _ProgressMetricsFormState();
}

class _ProgressMetricsFormState extends State<ProgressMetricsForm> {
  final Map<String, TextEditingController> _measurementControllers = {};
  final List<String> _measurementTypes = [
    'Chest',
    'Waist',
    'Hips',
    'Left Arm',
    'Right Arm',
    'Left Thigh',
    'Right Thigh',
    'Left Calf',
    'Right Calf',
  ];

  bool _showMeasurements = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Show measurements if there's existing data
    _showMeasurements = widget.measurements.isNotEmpty;
  }

  @override
  void didUpdateWidget(ProgressMetricsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if measurements changed
    if (oldWidget.measurements != widget.measurements) {
      for (final type in _measurementTypes) {
        final controller = _measurementControllers[type]!;
        final newValue = widget.measurements[type]?.toString() ?? '';
        if (controller.text != newValue) {
          controller.text = newValue;
        }
      }
      // Update visibility based on new data
      _showMeasurements = widget.measurements.isNotEmpty;
    }
  }

  void _initializeControllers() {
    for (final type in _measurementTypes) {
      _measurementControllers[type] = TextEditingController(
        text: widget.measurements[type]?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _measurementControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBasicMetrics(),
        const SizedBox(height: 24),
        _buildMeasurementsSection(),
      ],
    );
  }

  Widget _buildBasicMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Metrics',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildMetricField(
          controller: widget.weightController,
          label: 'Weight',
          hint: '70.5',
          suffix: 'kg',
          icon: Icons.monitor_weight,
        ),
      ],
    );
  }

  Widget _buildMeasurementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Body Measurements',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: _toggleMeasurements,
              icon: Icon(
                _showMeasurements ? Icons.visibility_off : Icons.visibility,
                size: 16,
              ),
              label: Text(
                _showMeasurements ? 'Hide' : 'Add',
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_showMeasurements) ...[
          Text(
            'Track your body measurements to monitor your progress over time.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildMeasurementsGrid(),
        ],
      ],
    );
  }

  Widget _buildMeasurementsGrid() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _measurementTypes.length,
        itemBuilder: (context, index) {
          final type = _measurementTypes[index];
          final controller = _measurementControllers[type]!;

          return _buildMeasurementField(
            controller: controller,
            label: type,
            hint: '0.0',
            suffix: 'cm',
            onChanged: (value) => _updateMeasurement(type, value),
          );
        },
      ),
    );
  }

  Widget _buildMetricField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppConstants.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textTertiary,
            ),
            suffixText: suffix,
            suffixStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppConstants.textTertiary.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppConstants.textTertiary.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppConstants.primaryColor,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppConstants.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppConstants.textTertiary,
              ),
              suffixText: suffix,
              suffixStyle: AppTextStyles.bodySmall.copyWith(
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: AppConstants.textTertiary.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: AppConstants.textTertiary.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: AppConstants.primaryColor,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleMeasurements() {
    setState(() {
      _showMeasurements = !_showMeasurements;
    });

    // If hiding measurements, clear all data
    if (!_showMeasurements) {
      for (final controller in _measurementControllers.values) {
        controller.clear();
      }
      widget.onMeasurementsChanged({});
    }
  }

  void _updateMeasurement(String type, String value) {
    final measurements = Map<String, double>.from(widget.measurements);

    if (value.isNotEmpty) {
      final doubleValue = double.tryParse(value);
      if (doubleValue != null) {
        measurements[type] = doubleValue;
      }
    } else {
      measurements.remove(type);
    }

    widget.onMeasurementsChanged(measurements);
  }
}
