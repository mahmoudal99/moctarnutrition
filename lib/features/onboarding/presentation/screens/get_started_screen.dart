import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/onboarding_service.dart';
import 'package:google_fonts/google_fonts.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<FeatureCard> _features = [
    FeatureCard(
      title: 'Training',
      description: 'Access personalized workout plans and track your progress',
      icon: "weights.png",
      color: const Color(0xFF2196F3),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
      ),
    ),
    FeatureCard(
      title: 'Meal Prepping',
      description:
          'Plan and prepare your meals for optimal nutrition and convenience',
      icon: "calendar.png",
      color: const Color(0xFF4CAF50),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
      ),
    ),
    FeatureCard(
      title: 'Fitness',
      description:
          'Monitor your overall fitness journey and achieve your goals',
      icon: "treadmill.png",
      color: const Color(0xFFFF9800),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
      ),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DecoratedBox(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage(
                  "assets/images/muk_one.jpg",
                ),
                fit: BoxFit.cover)),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // // Skip button
              // Align(
              //   alignment: Alignment.topRight,
              //   child: Padding(
              //     padding: const EdgeInsets.all(16.0),
              //     child: TextButton(
              //       onPressed: () => context.go('/onboarding'),
              //       child: Text(
              //         'Skip',
              //         style: GoogleFonts.nunitoSans(
              //           fontSize: 16,
              //           fontWeight: FontWeight.w600,
              //           color: AppConstants.textSecondary,
              //         ),
              //       ),
              //     ),
              //   ),
              // ),

              // Carousel
              // Expanded(
              //   child: PageView.builder(
              //     controller: _pageController,
              //     onPageChanged: _onPageChanged,
              //     itemCount: _features.length,
              //     itemBuilder: (context, index) {
              //       return _FeatureCardWidget(feature: _features[index]);
              //     },
              //   ),
              // ),

              // Page indicators
              // Padding(
              //   padding: const EdgeInsets.symmetric(vertical: 24.0),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: List.generate(_features.length, (index) {
              //       return AnimatedContainer(
              //         duration: const Duration(milliseconds: 300),
              //         margin: const EdgeInsets.symmetric(horizontal: 4),
              //         width: _currentPage == index ? 24 : 8,
              //         height: 8,
              //         decoration: BoxDecoration(
              //           color: _currentPage == index
              //               ? AppConstants.primaryColor
              //               : AppConstants.textTertiary.withOpacity(0.3),
              //           borderRadius: BorderRadius.circular(4),
              //         ),
              //       );
              //     }),
              //   ),
              // ),
              Text(
                'ACHIEVE YOUR FITNESS\nGOALS, YOUR WAY',
                textAlign: TextAlign.center,
                style: GoogleFonts.leagueSpartan(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // Get Started button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      await OnboardingService.markGetStartedAsSeen();
                      if (mounted) {
                        context.go('/onboarding');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await OnboardingService.markGetStartedAsSeen();
                  await OnboardingService.markOnboardingAsSeen();
                  if (mounted) {
                    context.go('/auth');
                  }
                },
                child: Column(
                  children: [
                    Text(
                      'Already a Member?',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'LOG IN',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureCard {
  final String title;
  final String description;
  final String icon;
  final Color color;
  final LinearGradient gradient;

  FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}

class _FeatureCardWidget extends StatelessWidget {
  final FeatureCard feature;

  const _FeatureCardWidget({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with gradient
          // Image.asset(
          //   "assets/images/${feature.icon}",
          //   height: 250,
          // ),

          const SizedBox(height: 40),

          // Title
          Text(
            feature.title,
            style: GoogleFonts.nunitoSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppConstants.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            feature.description,
            style: GoogleFonts.nunitoSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppConstants.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
