import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class MoodEnergyForm extends StatelessWidget {
  final String? selectedMood;
  final int? selectedEnergyLevel;
  final int? selectedMotivationLevel;
  final Function(String?) onMoodChanged;
  final Function(int?) onEnergyLevelChanged;
  final Function(int?) onMotivationLevelChanged;

  const MoodEnergyForm({
    super.key,
    this.selectedMood,
    this.selectedEnergyLevel,
    this.selectedMotivationLevel,
    required this.onMoodChanged,
    required this.onEnergyLevelChanged,
    required this.onMotivationLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMoodSection(),
        const SizedBox(height: 24),
        _buildEnergySection(context),
        const SizedBox(height: 24),
        _buildMotivationSection(context),
      ],
    );
  }

  Widget _buildMoodSection() {
    final moods = [
      {'emoji': '😊', 'label': 'Happy', 'value': 'Happy'},
      {'emoji': '😌', 'label': 'Calm', 'value': 'Calm'},
      {'emoji': '😤', 'label': 'Motivated', 'value': 'Motivated'},
      {'emoji': '😴', 'label': 'Tired', 'value': 'Tired'},
      {'emoji': '😔', 'label': 'Stressed', 'value': 'Stressed'},
      {'emoji': '😡', 'label': 'Frustrated', 'value': 'Frustrated'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling today?',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: moods.length,
          itemBuilder: (context, index) {
            final mood = moods[index];
            final isSelected = selectedMood == mood['value'];

            return _buildMoodCard(
              emoji: mood['emoji']!,
              label: mood['label']!,
              isSelected: isSelected,
              onTap: () => onMoodChanged(isSelected ? null : mood['value']),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMoodCard({
    required String emoji,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.1)
              : AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : AppConstants.textTertiary.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Energy Level',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selectedEnergyLevel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$selectedEnergyLevel/10',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSlider(
          context: context,
          value: selectedEnergyLevel?.toDouble() ?? 5.0,
          min: 1,
          max: 10,
          divisions: 9,
          onChanged: (value) => onEnergyLevelChanged(value.toInt()),
          onChangeEnd: (value) => onEnergyLevelChanged(value.toInt()),
          activeColor: AppConstants.warningColor,
          thumbIcon: Icons.flash_on,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Low',
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textTertiary,
              ),
            ),
            Text(
              'High',
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMotivationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Motivation Level',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selectedMotivationLevel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$selectedMotivationLevel/10',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSlider(
          context: context,
          value: selectedMotivationLevel?.toDouble() ?? 5.0,
          min: 1,
          max: 10,
          divisions: 9,
          onChanged: (value) => onMotivationLevelChanged(value.toInt()),
          onChangeEnd: (value) => onMotivationLevelChanged(value.toInt()),
          activeColor: AppConstants.successColor,
          thumbIcon: Icons.psychology,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Low',
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textTertiary,
              ),
            ),
            Text(
              'High',
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlider({
    required BuildContext context,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
    required Color activeColor,
    required IconData thumbIcon,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: activeColor,
        inactiveTrackColor: AppConstants.textTertiary.withOpacity(0.3),
        thumbColor: activeColor,
        overlayColor: activeColor.withOpacity(0.2),
        thumbShape: CustomSliderThumbShape(
          thumbRadius: 12,
          icon: thumbIcon,
        ),
        trackHeight: 4,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}

class CustomSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final IconData icon;

  const CustomSliderThumbShape({
    required this.thumbRadius,
    required this.icon,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final paint = Paint()
      ..color = sliderTheme.thumbColor!
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Draw shadow
    canvas.drawCircle(
      center + const Offset(0, 2),
      thumbRadius,
      shadowPaint,
    );

    // Draw thumb
    canvas.drawCircle(center, thumbRadius, paint);

    // Draw icon
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final iconSize = thumbRadius * 0.6;

    // Simple icon representation
    canvas.drawCircle(
      center,
      iconSize * 0.3,
      iconPaint,
    );
  }
}
