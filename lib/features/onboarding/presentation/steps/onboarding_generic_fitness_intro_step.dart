import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import 'benefit_card.dart';
import 'benefit_item.dart';

class OnboardingGenericFitnessIntroStep extends StatefulWidget {
  const OnboardingGenericFitnessIntroStep({super.key});

  @override
  State<OnboardingGenericFitnessIntroStep> createState() =>
      _OnboardingGenericFitnessIntroStepState();
}

class _OnboardingGenericFitnessIntroStepState
    extends State<OnboardingGenericFitnessIntroStep> {
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

  Widget _buildIntroductionText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: Column(
        children: [
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Welcome to your personalized fitness journey! Get ready to build a healthier lifestyle through balanced nutrition and effective workout routines that fit into your daily life.',
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
        title: 'Fitness Plans for Everyone',
        description:
            'Flexible workout routines and nutrition guidance that adapt to your schedule and lifestyle',
      ),
      BenefitItem(
        icon: "chart-line-data-01-stroke-rounded.svg",
        title: 'Simple Progress Tracking',
        description:
            'Easy-to-understand metrics to help you see improvements in your health and fitness',
      ),
      BenefitItem(
        icon: "comment-01-stroke-rounded.svg",
        title: 'Friendly Support',
        description:
            'Get practical tips, motivation, and encouragement to help you build healthy habits',
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
