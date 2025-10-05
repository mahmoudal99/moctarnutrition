import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingRatingStep extends StatelessWidget {
  const OnboardingRatingStep({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
