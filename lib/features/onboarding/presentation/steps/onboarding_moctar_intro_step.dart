import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import 'benefit_card.dart';
import 'benefit_item.dart';

class OnboardingMoctarIntroStep extends StatefulWidget {
  const OnboardingMoctarIntroStep({super.key});

  @override
  State<OnboardingMoctarIntroStep> createState() =>
      _OnboardingMoctarIntroStepState();
}

class _OnboardingMoctarIntroStepState extends State<OnboardingMoctarIntroStep> {
  final List<bool> _benefitVisible = [false, false, false];
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    const int baseDelayMs = 300;
    const int stepDelayMs = 200;

    for (int i = 0; i < _benefitVisible.length; i++) {
      final timer =
          Timer(Duration(milliseconds: baseDelayMs + stepDelayMs * i), () {
        if (!mounted) return;
        setState(() {
          _benefitVisible[i] = true;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Moctar Image
                _buildMoctarImage(),
                const SizedBox(height: AppConstants.spacingXL),

                // Introduction Text
                _buildIntroductionText(),
                const SizedBox(height: AppConstants.spacingXL),

                // Benefits List
                _buildBenefitsList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoctarImage() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppConstants.textTertiary.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(80),
        child: Image.asset(
          'assets/images/moc_one.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: AppConstants.textTertiary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 80,
                color: AppConstants.textSecondary,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntroductionText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: Column(
        children: [
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'I will be your personal trainer dedicated to helping you achieve your fitness goals through personalized nutrition and training plans.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      BenefitItem(
        icon: "file-01-stroke-rounded.svg",
        title: 'Personalized Plans',
        description:
            'Customized nutrition and workout programs tailored to your goals',
      ),
      BenefitItem(
        icon: "chart-line-data-01-stroke-rounded.svg",
        title: 'Track Your Progress',
        description:
            'Monitor your journey with detailed analytics and insights',
      ),
      BenefitItem(
        icon: "comment-01-stroke-rounded.svg",
        title: 'Expert Guidance',
        description:
            'Get professional support and advice throughout your fitness journey',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: Column(
        children: benefits.asMap().entries.map((entry) {
          final index = entry.key;
          final benefit = entry.value;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            opacity: _benefitVisible[index] ? 1 : 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
              child: BenefitCard(
                icon: benefit.icon,
                title: benefit.title,
                description: benefit.description,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
