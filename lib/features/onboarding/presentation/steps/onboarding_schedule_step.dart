import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import 'dart:ui';

class OnboardingScheduleStep extends StatelessWidget {
  const OnboardingScheduleStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 8),
        // Avatars row with labels
        _TrainerAvatarsRow(),
        SizedBox(height: 18),
        // Calendar with static magnifier
        SizedBox(
          height: 260,
          child: _FunCalendar(),
        ),
      ],
    );
  }
}

class _TrainerAvatarsRow extends StatelessWidget {
  final List<_TrainerAvatarData> trainers = const [
    _TrainerAvatarData(
        name: 'Johnson',
        imageUrl: 'https://randomuser.me/api/portraits/men/21.jpg',
        color: Color(0xFFB3E5FC)),
    _TrainerAvatarData(
        name: 'Alicia',
        imageUrl: 'https://randomuser.me/api/portraits/women/22.jpg',
        color: Color(0xFF81D4FA)),
    _TrainerAvatarData(
        name: 'Micheal',
        imageUrl: 'https://randomuser.me/api/portraits/men/23.jpg',
        color: Color(0xFFFFF59D)),
    _TrainerAvatarData(
        name: 'Tina',
        imageUrl: 'https://randomuser.me/api/portraits/women/24.jpg',
        color: Color(0xFFFFE0E6)),
    _TrainerAvatarData(
        name: 'Sam',
        imageUrl: 'https://randomuser.me/api/portraits/men/25.jpg',
        color: Color(0xFFC8E6C9)),
  ];

  const _TrainerAvatarsRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: trainers.map((trainer) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: trainer.color.withOpacity(0.7),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: trainer.color.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: trainer.color,
                  backgroundImage: NetworkImage(trainer.imageUrl),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TrainerAvatarData {
  final String name;
  final String imageUrl;
  final Color color;

  const _TrainerAvatarData(
      {required this.name, required this.imageUrl, required this.color});
}

class _FunCalendar extends StatelessWidget {
  // July 2025 starts on a Tuesday and has 31 days
  final List<List<int?>> days = const [
    [null, 1, 2, 3, 4, 5, 6],      // Mon-Sun
    [7, 8, 9, 10, 11, 12, 13],
    [14, 15, 16, 17, 18, 19, 20],
    [21, 22, 23, 24, 25, 26, 27],
    [28, 29, 30, 31, null, null, null],
  ];
  const _FunCalendar();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: days.map((week) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: week.map((day) {
            if (day == null) {
              return const SizedBox(width: 38, height: 38);
            }
            final isHighlighted = day == 19;
            return Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isHighlighted ? AppConstants.successColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isHighlighted
                    ? Border.all(color: AppConstants.successColor, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == current ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == current
                ? AppConstants.primaryColor
                : AppConstants.textTertiary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}
