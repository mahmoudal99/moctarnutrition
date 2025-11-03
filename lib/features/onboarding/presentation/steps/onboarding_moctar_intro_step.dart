import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';

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
      _BenefitItem(
        icon: Icons.fitness_center,
        title: 'Personalized Plans',
        description:
            'Customized nutrition and workout programs tailored to your goals',
      ),
      _BenefitItem(
        icon: Icons.analytics_outlined,
        title: 'Track Your Progress',
        description:
            'Monitor your journey with detailed analytics and insights',
      ),
      _BenefitItem(
        icon: Icons.support_agent,
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
              child: _BenefitCard(
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

class _BenefitItem {
  final IconData icon;
  final String title;
  final String description;

  _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
        boxShadow: AppConstants.shadowS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Icon(
              icon,
              color: AppConstants.textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading5.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
