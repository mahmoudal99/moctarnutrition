import 'dart:async';

import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class OnboardingWelcomeStep extends StatefulWidget {
  const OnboardingWelcomeStep({super.key});

  @override
  State<OnboardingWelcomeStep> createState() => _OnboardingWelcomeStepState();
}

class _OnboardingWelcomeStepState extends State<OnboardingWelcomeStep> {
  final List<bool> _cardVisible = [false, false, false];
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    const int baseDelayMs = 200;
    const int stepDelayMs = 1000;

    for (int i = 0; i < _cardVisible.length; i++) {
      final timer =
          Timer(Duration(milliseconds: baseDelayMs + stepDelayMs * i), () {
        if (!mounted) return;
        setState(() {
          _cardVisible[i] = true;
        });
      });
      _timers.add(timer);
    }
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

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


              return Stack(
                clipBehavior: Clip.none,
                children: [
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
                    child: _StepCard(
                      stepNumber: 1,
                      width: cardWidth,
                      icon: "targeting.png",
                      isVisible: _cardVisible[0],
                      highlightWords: ['goals'],
                      cardMessage:
                          "Define your goals tell us what success looks like to you.",
                    ),
                  ),
                  Positioned(
                    left: centerX,
                    top: centerY,
                    child: _StepCard(
                      stepNumber: 2,
                      icon: "user.png",
                      width: cardWidth,
                      isVisible: _cardVisible[1],
                      highlightWords: ["account"],
                      cardMessage:
                          "Create your account it only takes a minute.",
                    ),
                  ),
                  Positioned(
                    left: leftX,
                    top: bottomY,
                    child: _StepCard(
                      stepNumber: 3,
                      width: cardWidth,
                      icon: "check-in.png",
                      isVisible: _cardVisible[2],
                      highlightWords: ["Moctar"],
                      cardMessage:
                          "Check in with Moctar we’ll tailor your plan to your goals.",
                    ),
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
  final List<String> highlightWords;
  final bool isVisible;
  final String icon;

  const _StepCard(
      {required this.stepNumber,
      required this.width,
      required this.cardMessage,
      required this.isVisible,
      required this.icon,
      this.highlightWords = const []});

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.bodyMedium;
    final highlightStyle = baseStyle.copyWith(
      color: AppConstants.primaryColor,
      fontWeight: FontWeight.w600,
    );

    final normalizedHighlights =
        highlightWords.map((word) => word.toLowerCase()).toSet();

    final spans = <InlineSpan>[];
    final words = cardMessage.split(' ');

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final sanitizedWord = word.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      final isHighlight = sanitizedWord.isNotEmpty &&
          normalizedHighlights.contains(sanitizedWord.toLowerCase());

      spans.add(
        TextSpan(
          text: word,
          style: isHighlight ? highlightStyle : baseStyle,
        ),
      );

      if (isHighlight) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Image.asset(
                "assets/images/$icon",
                height: 16,
              ),
            ),
          ),
        );
      }

      if (i != words.length - 1) {
        spans.add(TextSpan(text: ' ', style: baseStyle));
      }
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      opacity: isVisible ? 1 : 0,
      child: Container(
        width: width,
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: RichText(
          textAlign: TextAlign.center,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(children: spans, style: baseStyle),
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
