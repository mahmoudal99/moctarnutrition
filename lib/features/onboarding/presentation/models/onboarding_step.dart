import 'package:flutter/material.dart';

class OnboardingStep {
  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  bool showIconColor = true;

  OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.showIconColor = true,
  });
}
