import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingHowWeDoThisStep extends StatelessWidget {
  const OnboardingHowWeDoThisStep({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingS,
          vertical: AppConstants.spacingM,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Section Label - small muted "HOW WE DO THIS"
            Text(
              'HOW WE DO THIS',
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Headline - expressive serif font
            Text(
              'Fun & healthy\nplans you\'ll love!',
              textAlign: TextAlign.center,
              style: GoogleFonts.merriweather(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
                height: 1.2,
              ),
            ),

            const SizedBox(height: AppConstants.spacingL),

            // Phone Mockup with floating testimonial card
            _buildPhoneWithTestimonial(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneWithTestimonial(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Phone Mockup - main product preview
        Padding(
          padding: const EdgeInsets.only(bottom: 100),
          // Space for testimonial below with slight overlap
          child: _buildPhoneMockup(context),
        ),

        // Floating Testimonial Card - positioned to slightly overlap the phone bottom
        // Negative left/right to extend beyond phone width
        Positioned(
          bottom: 0,
          left: -40,
          right: -40,
          child: _buildTestimonialCard(),
        ),
      ],
    );
  }

  Widget _buildPhoneMockup(BuildContext context) {
    // Calculate max height based on screen size to ensure testimonial is visible
    final screenHeight = MediaQuery.of(context).size.height;
    final maxPhoneHeight = screenHeight * 0.35; // Use 35% of screen height max

    return Container(
      constraints: BoxConstraints(
        maxWidth: 260,
        maxHeight: maxPhoneHeight,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        child: Image.asset(
          'assets/images/howwedothis.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: maxPhoneHeight,
              width: 260,
              decoration: BoxDecoration(
                color: AppConstants.containerColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              ),
              child: const Center(
                child: Icon(
                  Icons.phone_iphone,
                  size: 80,
                  color: AppConstants.textTertiary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTestimonialCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: AppConstants.shadowS,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row with avatar, username, flag and rating
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/avatar_placeholder.png',
                      fit: BoxFit.cover,
                      width: 36,
                      height: 36,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: AppConstants.primaryColor,
                          size: 20,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                // Username and flag
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Patrick Mcdondald',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // UK Flag emoji
                      const Text(
                        '🇬🇧',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // 5-star rating
                Row(
                  children: List.generate(
                    5,
                    (index) => const Icon(
                      Icons.star,
                      color: Colors.black87,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            // Review quote in serif font for authenticity
            Text(
              '"Really enjoying this app and the meal plans that are made so easy to follow."',
              style: GoogleFonts.merriweather(
                fontSize: 15,
                fontWeight: FontWeight.normal,
                color: AppConstants.textPrimary,
                height: 1.5,
                fontStyle: FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
