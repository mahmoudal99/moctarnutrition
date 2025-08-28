import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar with Skip
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Skip',
                        style: TextStyle(color: AppConstants.textSecondary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Stacked activity cards
            _ActivityCardsStack(),
            const SizedBox(height: 24),
            // Avatars row
            _AvatarsRow(),
            const SizedBox(height: 28),
            // Motivational text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(
                    'Crush Your Goals, Together',
                    style: AppTextStyles.heading3
                        .copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Plan your workouts, sync with friends, and stay motivated.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppConstants.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Progress dots
            _ProgressDots(current: 0, total: 3),
            const SizedBox(height: 24),
            // Continue button
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
                  child: const Text('Continue',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ActivityCardsStack extends StatelessWidget {
  final List<_ActivityCardData> cards = const [
    _ActivityCardData(
      title: 'Leg Day 💪',
      time: '09:00am - 10:00am',
      color: Color(0xFFFFE0E6),
      emoji: '💪',
    ),
    _ActivityCardData(
      title: 'Yoga with Lisa 🧘',
      time: '10:30am - 11:15am',
      color: Color(0xFFD6F5FF),
      emoji: '🧘',
    ),
    _ActivityCardData(
      title: 'HIIT with Mike 🔥',
      time: '12:00pm - 12:45pm',
      color: Color(0xFFFFF4D6),
      emoji: '🔥',
    ),
  ];

  const _ActivityCardsStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(cards.length, (i) {
          final card = cards[i];
          return Positioned(
            top: 18.0 * i,
            left: 0,
            right: 0,
            child:
                _ActivityCard(card: card, elevation: (cards.length - i) * 2.0),
          );
        }),
      ),
    );
  }
}

class _ActivityCardData {
  final String title;
  final String time;
  final Color color;
  final String emoji;
  const _ActivityCardData(
      {required this.title,
      required this.time,
      required this.color,
      required this.emoji});
}

class _ActivityCard extends StatelessWidget {
  final _ActivityCardData card;
  final double elevation;
  const _ActivityCard({required this.card, this.elevation = 2});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: card.color,
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 36, vertical: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Text(card.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.title,
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(card.time,
                      style: AppTextStyles.caption
                          .copyWith(color: AppConstants.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.more_horiz, color: AppConstants.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _AvatarsRow extends StatelessWidget {
  final List<_AvatarData> avatars = const [
    _AvatarData(
        name: 'You', imageUrl: 'https://randomuser.me/api/portraits/men/1.jpg'),
    _AvatarData(
        name: 'Lisa',
        imageUrl: 'https://randomuser.me/api/portraits/women/2.jpg'),
    _AvatarData(
        name: 'Mike',
        imageUrl: 'https://randomuser.me/api/portraits/men/3.jpg'),
  ];

  const _AvatarsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: avatars.map((avatar) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(avatar.imageUrl),
              ),
              const SizedBox(height: 8),
              Text(
                avatar.name,
                style:
                    AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AvatarData {
  final String name;
  final String imageUrl;
  const _AvatarData({required this.name, required this.imageUrl});
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
