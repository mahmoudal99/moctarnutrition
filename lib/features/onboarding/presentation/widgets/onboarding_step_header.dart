import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/onboarding_step.dart';

class OnboardingStepHeader extends StatelessWidget {
  final OnboardingStep step;

  const OnboardingStepHeader({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Column(
              children: [
                // Container(
                //   width: step.icon.contains("arrow") ? 80 : 48,
                //   height: step.icon.contains("arrow") ? 80 : 48,
                //   decoration: const BoxDecoration(),
                //   child: Lottie.asset(
                //     "assets/animations/${step.icon}",
                //     delegates: LottieDelegates(
                //       values: step.showIconColor
                //           ? [
                //               ValueDelegate.color(
                //                 const ['**', 'Fill 1'],
                //                 value: step.color,
                //               ),
                //             ]
                //           : [],
                //     ),
                //   ),
                // ),
                SizedBox(
                    height: step.icon.contains("arrow")
                        ? 0
                        : AppConstants.spacingS),
                _buildHighlightedTitle(),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  step.subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHighlightedTitle() {
    if (step.highlightedWords.isEmpty) {
      return Text(
        step.title,
        style: AppTextStyles.heading5,
        textAlign: TextAlign.center,
      );
    }

    final words = step.title.split(' ');
    final spans = <InlineSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final isHighlighted = step.highlightedWords.any((highlight) =>
          word.toLowerCase().contains(highlight.toLowerCase()));

      if (isHighlighted) {
        spans.add(
          WidgetSpan(
            child: SquigglyUnderlineText(
              text: word,
              color: step.color,
              textStyle: AppTextStyles.heading5,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: word,
            style: AppTextStyles.heading5,
          ),
        );
      }

      // Add space between words (except for the last word)
      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }
}

class SquigglyUnderlineText extends StatelessWidget {
  final String text;
  final Color color;
  final TextStyle textStyle;

  const SquigglyUnderlineText({
    super.key,
    required this.text,
    required this.color,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SquigglyUnderlinePainter(color: color),
      child: Text(
        text,
        style: textStyle.copyWith(color: color),
      ),
    );
  }
}

class SquigglyUnderlinePainter extends CustomPainter {
  final Color color;

  SquigglyUnderlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final startY = size.height - 1;
    
    // Create a slightly curved line like a hand-drawn marker
    path.moveTo(0, startY + 0.5);
    
    // Add subtle curves to make it look more organic/hand-drawn
    final curvePoint1X = size.width * 0.25;
    final curvePoint2X = size.width * 0.5;
    final curvePoint3X = size.width * 0.75;
    
    path.quadraticBezierTo(
      curvePoint1X,
      startY - 0.5,
      curvePoint2X,
      startY,
    );
    
    path.quadraticBezierTo(
      curvePoint3X,
      startY + 0.5,
      size.width,
      startY - 0.3,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SquigglyUnderlinePainter oldDelegate) =>
      oldDelegate.color != color;
}
