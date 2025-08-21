import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingRatingStep extends StatelessWidget {
  final VoidCallback onContinue;

  const OnboardingRatingStep({
    super.key,
    required this.onContinue,
  });

  Future<void> _showRatingDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          title: Text(
            'Rate Cal AI',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enjoying Cal AI? Please take a moment to rate us!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () async {
                      // Open app store for rating
                      final Uri url = Uri.parse(
                          'https://apps.apple.com/app/id123456789' // Replace with actual app store URL
                          );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      }
                      Navigator.of(context).pop();
                      onContinue();
                    },
                    icon: Icon(
                      Icons.star,
                      color: Colors.amber[600],
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onContinue();
              },
              child: Text(
                'Maybe Later',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Main Title
        Text(
          'Give us a rating',
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppConstants.spacingXL),

        // App Rating Card
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            border: Border.all(
              color: AppConstants.textTertiary.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: AppConstants.shadowS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left decorative branch
              Icon(
                Icons.emoji_events,
                color: Colors.amber[600],
                size: 24,
              ),

              const SizedBox(width: AppConstants.spacingM),

              // Rating content
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '4.8',
                        style: AppTextStyles.heading1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingS),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            Icons.star,
                            color: Colors.amber[600],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingXS),
                  Text(
                    '100K+ App Ratings',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: AppConstants.spacingM),

              // Right decorative branch
              Icon(
                Icons.emoji_events,
                color: Colors.amber[600],
                size: 24,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.spacingXL),

        // User-centric message
        Text(
          'Cal AI was made for\npeople like you',
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppConstants.spacingL),

        // User avatars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUserAvatar('assets/images/user1.jpg', 0),
            _buildUserAvatar('assets/images/user2.jpg', -10),
            _buildUserAvatar('assets/images/user3.jpg', -20),
          ],
        ),

        const SizedBox(height: AppConstants.spacingS),

        Text(
          '5M+ Cal AI Users',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),

        const SizedBox(height: AppConstants.spacingXL),

        // User testimonial card
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            border: Border.all(
              color: AppConstants.textTertiary.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: AppConstants.shadowS,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                    child: const Icon(
                      Icons.person,
                      color: AppConstants.primaryColor,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: AppConstants.spacingM),

                  // User name and rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jake Sullivan',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              Icons.star,
                              color: Colors.amber[600],
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spacingM),

              // Testimonial text
              Text(
                'I lost 15 lbs in 2 months! I was about to go on Ozempic but decided to give this app a shot and it worked :)',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.spacingXL),

        // Continue button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _showRatingDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.textPrimary,
              foregroundColor: AppConstants.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              elevation: 0,
            ),
            child: Text(
              'Continue',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppConstants.surfaceColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(String imagePath, double offset) {
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppConstants.surfaceColor,
            width: 2,
          ),
          image: const DecorationImage(
            image: AssetImage('assets/images/user1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
