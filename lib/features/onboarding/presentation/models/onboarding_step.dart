import 'package:flutter/material.dart';

class OnboardingStep {
  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  bool showIconColor = true;
  final List<String>? _highlightedWords;

  OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.showIconColor = true,
    List<String>? highlightedWords,
  }) : _highlightedWords = highlightedWords;

  List<String> get highlightedWords => _highlightedWords ?? [];
}
