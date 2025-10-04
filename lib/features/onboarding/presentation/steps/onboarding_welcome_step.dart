import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingWelcomeStep extends StatelessWidget {
  const OnboardingWelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActivityCardsStack(),
        ],
      ),
    );
  }
}

class _ActivityCardsStack extends StatefulWidget {
  const _ActivityCardsStack();

  @override
  State<_ActivityCardsStack> createState() => _ActivityCardsStackState();
}

class _ActivityCardsStackState extends State<_ActivityCardsStack> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _images = [
    'assets/images/moc_one.jpg',
    'assets/images/moc_two.jpg',
    'assets/images/moc_three.jpg',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 370,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _images.length,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              final isActive = index == _currentPage;
              final offset = (index - _currentPage).toDouble();
              final rotation = offset * 0.05;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.1,
                  vertical: 15,
                ),
                child: Transform.rotate(
                  angle: rotation,
                  child: _ImageCard(
                    imagePath: _images[index],
                    isActive: isActive,
                    elevation: isActive ? 8 : 4 - offset.abs(),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _PageIndicator(
          currentPage: _currentPage,
          pageCount: _images.length,
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const _PageIndicator({
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return Container(
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Theme.of(context).primaryColor
                : Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        );
      }),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String imagePath;
  final bool isActive;
  final double elevation;

  const _ImageCard({
    required this.imagePath,
    required this.isActive,
    required this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          height: 250,
        ),
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
