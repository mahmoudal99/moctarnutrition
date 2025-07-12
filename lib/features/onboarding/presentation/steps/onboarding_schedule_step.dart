import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingScheduleStep extends StatelessWidget {
  const OnboardingScheduleStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        // Avatars row with labels
        _TrainerAvatarsRow(),
        const SizedBox(height: 18),
        // Calendar with magnifier
        SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _FunCalendar(),
              // Magnifying glass overlay (use Icon for now)
              Positioned(
                left: 120,
                top: 110,
                child: _MagnifierOverlay(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Header and subtext
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                "See Everyone's Schedules",
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Sync your calendar and view your friends' availability in real-time to find the perfect time to meet.",
                style: AppTextStyles.bodyMedium.copyWith(color: AppConstants.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _ProgressDots(current: 1, total: 3),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {},
              child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _TrainerAvatarsRow extends StatelessWidget {
  final List<_TrainerAvatarData> trainers = const [
    _TrainerAvatarData(name: 'Johnson', imageUrl: 'https://randomuser.me/api/portraits/men/21.jpg', color: Color(0xFFB3E5FC)),
    _TrainerAvatarData(name: 'Alicia', imageUrl: 'https://randomuser.me/api/portraits/women/22.jpg', color: Color(0xFF81D4FA)),
    _TrainerAvatarData(name: 'Micheal', imageUrl: 'https://randomuser.me/api/portraits/men/23.jpg', color: Color(0xFFFFF59D)),
    _TrainerAvatarData(name: 'Tina', imageUrl: 'https://randomuser.me/api/portraits/women/24.jpg', color: Color(0xFFFFE0E6)),
    _TrainerAvatarData(name: 'Sam', imageUrl: 'https://randomuser.me/api/portraits/men/25.jpg', color: Color(0xFFC8E6C9)),
  ];

  const _TrainerAvatarsRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: trainers.map((trainer) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: trainer.color,
                      backgroundImage: NetworkImage(trainer.imageUrl),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          // Handwritten label for Johnson
          Positioned(
            left: 70.0,
            top: 0,
            child: Column(
              children: const [
                Text('Johnson', style: TextStyle(fontFamily: 'Caveat', fontSize: 16)),
                SizedBox(height: 2),
                Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerAvatarData {
  final String name;
  final String imageUrl;
  final Color color;
  const _TrainerAvatarData({required this.name, required this.imageUrl, required this.color});
}

class _FunCalendar extends StatelessWidget {
  final List<List<int?>> days = const [
    [6, 2, 3, 5, 4, 7],
    [8, 9, 10, 11, 12, 13],
    [6, 15, 16, 17, 18, 21],
    [8, 23, 24, 25, 26, 27],
    [8, 29, 30, null, null, null],
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
                color: isHighlighted ? AppConstants.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isHighlighted ? Border.all(color: AppConstants.primaryColor, width: 2) : null,
              ),
              child: Center(
                child: isHighlighted
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('2', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('19', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Text('$day', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _MagnifierOverlay extends StatelessWidget {
  const _MagnifierOverlay();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.search, size: 40, color: AppConstants.primaryColor),
            ),
            Positioned(
              bottom: 8,
              child: Text('2 Events', style: TextStyle(fontFamily: 'Caveat', fontSize: 14)),
            ),
          ],
        ),
      ],
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
            color: i == current ? AppConstants.primaryColor : AppConstants.textTertiary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
} 