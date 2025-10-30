import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class OnboardingWelcomeStep extends StatefulWidget {
  const OnboardingWelcomeStep({super.key});

  @override
  State<OnboardingWelcomeStep> createState() => _OnboardingWelcomeStepState();
}

class _OnboardingWelcomeStepState extends State<OnboardingWelcomeStep> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Center(
        child: SizedBox(
          height: 540,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use full width minus horizontal margins (6 left + 6 right)
              final double maxW = constraints.maxWidth;
              final double cardWidth = (maxW - 100).clamp(0, maxW);
              const double cardHeight = 120;

              final double maxH = constraints.maxHeight;

              final double leftX = 1; // align with horizontal margin
              const double centerShiftX = 40; // push middle card to the right
              final double centerX = (maxW - cardWidth) / 2 + centerShiftX;

              final double topY = 0;
              final double centerY = (maxH - cardHeight) / 2;
              final double bottomY = maxH - cardHeight / 1;

              final Offset p1 =
                  Offset(leftX + cardWidth, topY + cardHeight / 2);
              final Offset p2 =
                  Offset(centerX + cardWidth / 2, centerY + cardHeight / 2);
              final Offset p3 =
                  Offset(leftX + cardWidth, bottomY + cardHeight / 2);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Dotted road connecting cards
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DottedRoadPainter(points: [p1, p2, p3]),
                    ),
                  ),

                  // Step numbers outside the cards
                  Positioned(
                    left: leftX,
                    top: topY - 24,
                    child: Text(
                      '1.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Positioned(
                    left: centerX,
                    top: centerY - 24,
                    child: Text(
                      '2.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Positioned(
                    left: leftX,
                    top: bottomY - 24,
                    child: Text(
                      '3.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),

                  // Cards
                  Positioned(
                    left: leftX,
                    top: topY,
                    child: _StepCard(stepNumber: 1, width: cardWidth, cardMessage: "Define your goals tell us what success looks like to you.",),
                  ),
                  Positioned(
                    left: centerX,
                    top: centerY,
                    child: _StepCard(stepNumber: 2, width: cardWidth, cardMessage: "Create your account it only takes a minute.",),
                  ),
                  Positioned(
                    left: leftX,
                    top: bottomY,
                    child: _StepCard(stepNumber: 3, width: cardWidth, cardMessage: "Check in with Moctar we’ll tailor your plan to your goals.",),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int stepNumber;
  final double width;
  final String cardMessage;

  const _StepCard({required this.stepNumber, required this.width, required this.cardMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: Text(
            cardMessage,
            textAlign: TextAlign.center,
            maxLines: 5,
            style: AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _DottedRoadPainter extends CustomPainter {
  final List<Offset> points;
  final double dotRadius;
  final double gap;

  _DottedRoadPainter({
    required this.points,
    this.dotRadius = 2,
    this.gap = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final segment = end - start;
      final length = segment.distance;
      final direction = segment / length;

      double traveled = 0;
      while (traveled <= length) {
        final center = start + direction * traveled;
        canvas.drawCircle(center, dotRadius, paint);
        traveled += dotRadius * 2 + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedRoadPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.gap != gap;
  }
}
