import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingWelcomeStep extends StatelessWidget {
  const OnboardingWelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActivityCardsStack(),
        SizedBox(height: 24),
      ],
    );
  }
}

class _ActivityCardsStack extends StatelessWidget {
  final List<_ActivityCardData> cards = const [
    _ActivityCardData(
      title: 'Work mode',
      time: '10:00am - 11:00am',
      color: Color(0xFFFFF4D6),
      accent: Color(0xFFFFB74D),
      titleColor: Color(0xFFE65100),
      emoji: '💻',
      avatars: [
        'https://randomuser.me/api/portraits/men/11.jpg',
        'https://randomuser.me/api/portraits/women/12.jpg',
      ],
    ),
    _ActivityCardData(
      title: 'Gym with Mike',
      time: '10:00am - 11:00am',
      color: Color(0xFFFFE0E6),
      accent: Color(0xFFFF80AB),
      titleColor: Color(0xFFD81B60),
      emoji: '💪',
      avatars: [
        'https://randomuser.me/api/portraits/men/13.jpg',
        'https://randomuser.me/api/portraits/women/14.jpg',
      ],
    ),
    _ActivityCardData(
      title: 'Chest & Biceps',
      time: '10:00am - 11:00am',
      color: Color(0xFFD6F5FF),
      accent: Color(0xFF4FC3F7),
      titleColor: Color(0xFF0277BD),
      emoji: '💪',
      avatars: [
        'https://randomuser.me/api/portraits/men/2.jpg',
      ],
    ),
  ];

  const _ActivityCardsStack();

  @override
  Widget build(BuildContext context) {
    final List<double> angles = [-0.08, 0.0, 0.08];
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(cards.length, (i) {
          final card = cards[i];
          return Positioned(
            top: 28.0 * i,
            left: 0,
            right: 0,
            child: Transform.rotate(
              angle: angles[i],
              child: _ActivityCard(
                  card: card, elevation: (cards.length - i) * 2.0),
            ),
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
  final Color accent;
  final Color titleColor;
  final String emoji;
  final List<String> avatars;

  const _ActivityCardData({
    required this.title,
    required this.time,
    required this.color,
    required this.accent,
    required this.titleColor,
    required this.emoji,
    required this.avatars,
  });
}

class _ActivityCard extends StatelessWidget {
  final _ActivityCardData card;
  final double elevation;

  const _ActivityCard({required this.card, this.elevation = 2});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left accent bar
              Container(
                width: 8,
                height: 130,
                margin: const EdgeInsets.only(
                    left: 0, top: 0, bottom: 0, right: 12),
                decoration: BoxDecoration(
                  color: card.accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              card.title,
                              style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6)
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: AppConstants.textTertiary),
                          const SizedBox(width: 4),
                          Text(card.time,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppConstants.textTertiary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 28,
                        child: Stack(
                          children: List.generate(card.avatars.length, (i) {
                            return Positioned(
                              left: i * 20.0,
                              child: CircleAvatar(
                                radius: 14,
                                foregroundColor: Colors.green,
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage(card.avatars[i]),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Three-dot menu
              const Padding(
                padding: EdgeInsets.only(top: 8, right: 12),
                child: Icon(Icons.more_horiz, color: AppConstants.textTertiary),
              ),
            ],
          ),
        ],
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

  // Fun pastel accent colors for borders
  final List<Color> borderColors = const [
    Color(0xFFB3E5FC), // Light Blue
    Color(0xFFFFE0E6), // Light Pink
    Color(0xFFC8E6C9), // Light Green
  ];

  const _AvatarsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(avatars.length, (i) {
        final avatar = avatars[i];
        final borderColor = borderColors[i % borderColors.length];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(avatar.imageUrl),
                ),
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
      }),
    );
  }
}

class _AvatarData {
  final String name;
  final String imageUrl;

  const _AvatarData({required this.name, required this.imageUrl});
}
