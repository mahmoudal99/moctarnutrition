import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingWelcomeStep extends StatelessWidget {
  const OnboardingWelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Testimonial Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              boxShadow: AppConstants.shadowM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info row
                Row(
                  children: [
                    // Avatar with light green background
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFE8F5E9), // Light green
                      child: Icon(
                        Icons.person,
                        color: AppConstants.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    // Name
                    Expanded(
                      child: Text(
                        'James Finn',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // 5-star rating
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          color: Colors.black87,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingM),
                // Review text in serif font
                Text(
                  "I’ve tried many fitness apps, but nothing compares to this. The workouts are clear, the meal plans are practical, everything feels tailored to help you stay consistent. This is the first time I’ve felt genuinely motivated to stick to my goals.",
                  style: GoogleFonts.merriweather(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: AppConstants.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingXXL),
          
          // Section title: "ACHIEVE YOUR GOALS"
          Text(
            'ACHIEVE YOUR GOALS',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingL),
          
          // Main message: "Complete all your obligatory knowledge"
          Text(
            'Reach all your fitness goals',
            textAlign: TextAlign.center,
            style: GoogleFonts.merriweather(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
