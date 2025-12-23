import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class Testimonial {
  final String name;
  final String message;
  final int rating;
  final Color avatarColor;

  const Testimonial({
    required this.name,
    required this.message,
    required this.rating,
    required this.avatarColor,
  });
}

class OnboardingRatingStep extends StatefulWidget {
  const OnboardingRatingStep({
    super.key,
  });

  @override
  State<OnboardingRatingStep> createState() => _OnboardingRatingStepState();
}

class _OnboardingRatingStepState extends State<OnboardingRatingStep> {
  late List<Testimonial> _displayedTestimonials;

  final List<Testimonial> _allTestimonials = [
    const Testimonial(
      name: 'Jake Sullivan',
      message:
          'I lost 15 lbs in 2 months! I was about to go on Ozempic but decided to give this app a shot and it worked :)',
      rating: 5,
      avatarColor: Colors.blue,
    ),
    const Testimonial(
      name: 'Maria Rodriguez',
      message:
          'Amazing results! Lost 12 pounds in 6 weeks. The meal plans are so easy to follow and actually taste good!',
      rating: 5,
      avatarColor: Colors.purple,
    ),
    const Testimonial(
      name: 'David Chen',
      message:
          'Finally found an app that works. Down 20 lbs in 3 months. The tracking features keep me motivated every day.',
      rating: 5,
      avatarColor: Colors.green,
    ),
    const Testimonial(
      name: 'Sarah Johnson',
      message:
          'Lost 8 pounds in my first month! The recipes are delicious and the portion control is perfect.',
      rating: 4,
      avatarColor: Colors.pink,
    ),
    const Testimonial(
      name: 'Mike Thompson',
      message:
          'This app changed my life. Lost 25 lbs and kept it off for a year now. Highly recommend!',
      rating: 5,
      avatarColor: Colors.orange,
    ),
    const Testimonial(
      name: 'Emily Davis',
      message:
          'Easy to use and effective. Lost 10 pounds in 2 months. Love the variety of meal options.',
      rating: 4,
      avatarColor: Colors.teal,
    ),
    const Testimonial(
      name: 'Alex Martinez',
      message:
          'Great app for busy people. Lost 18 lbs in 4 months. The workout plans are perfect for home workouts.',
      rating: 5,
      avatarColor: Colors.indigo,
    ),
    const Testimonial(
      name: 'Lisa Wong',
      message:
          'Incredible transformation! Lost 22 pounds in 5 months. The nutrition tracking is spot on.',
      rating: 5,
      avatarColor: Colors.red,
    ),
    const Testimonial(
      name: 'Tom Anderson',
      message:
          'Lost 14 pounds and gained so much energy! The app makes healthy eating fun and achievable.',
      rating: 4,
      avatarColor: Colors.cyan,
    ),
    const Testimonial(
      name: 'Rachel Green',
      message:
          'From skeptic to believer! Lost 16 lbs in 3 months. This app delivers real results.',
      rating: 5,
      avatarColor: Colors.amber,
    ),
    const Testimonial(
      name: 'Kevin Park',
      message:
          'Perfect for busy professionals! Lost 12 lbs in 2 months while working 60+ hours a week.',
      rating: 4,
      avatarColor: Colors.deepOrange,
    ),
    const Testimonial(
      name: 'Amanda Foster',
      message:
          'The meal planning saved me hours each week! Lost 18 lbs in 4 months and actually enjoy healthy eating now.',
      rating: 5,
      avatarColor: Colors.purpleAccent,
    ),
    const Testimonial(
      name: 'Carlos Mendez',
      message:
          'Great workout integration with nutrition. Lost 20 lbs in 5 months and feel stronger than ever.',
      rating: 5,
      avatarColor: Colors.lightGreen,
    ),
    const Testimonial(
      name: 'Sophie Turner',
      message:
          'Started as a challenge with my partner. We both lost weight and it brought us closer together!',
      rating: 4,
      avatarColor: Colors.pinkAccent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectRandomTestimonials();
  }

  void _selectRandomTestimonials() {
    final random = Random();
    final shuffled = List<Testimonial>.from(_allTestimonials)..shuffle(random);
    _displayedTestimonials = shuffled.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App Rating Card
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scaleX: -1,
                  child: Image.asset(
                    'assets/images/wreath.png',
                    width: 48,
                    height: 48,
                    color: Colors.black,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                        (index) => Icon(
                      Icons.star,
                      color: Colors.black,
                      size: 36,
                    ),
                  ),
                ),
                Image.asset(
                  'assets/images/wreath.png',
                  width: 48,
                  height: 48,
                  color: Colors.black,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: AppConstants.spacingXL),

        // User testimonial cards - show all testimonials
        Column(
          children: _allTestimonials
              .map((testimonial) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppConstants.spacingM),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectRandomTestimonials();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppConstants.spacingL),
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceColor,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusL),
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
                                  backgroundColor:
                                      testimonial.avatarColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    color: testimonial.avatarColor,
                                    size: 24,
                                  ),
                                ),

                                const SizedBox(width: AppConstants.spacingM),

                                // User name and rating
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        testimonial.name,
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (index) => Icon(
                                            index < testimonial.rating
                                                ? Icons.star
                                                : Icons.star_border,
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

                            // Testimonial text with quotes
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.format_quote,
                                  color: AppConstants.textTertiary.withOpacity(0.3),
                                  size: 24,
                                ),
                                Expanded(
                                  child: Text(
                                    '"${testimonial.message}"',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppConstants.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),

        const SizedBox(height: AppConstants.spacingXL),
      ],
    );
  }
}
