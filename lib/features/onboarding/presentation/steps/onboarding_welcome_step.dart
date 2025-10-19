import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class OnboardingWelcomeStep extends StatefulWidget {
  const OnboardingWelcomeStep({super.key});

  @override
  State<OnboardingWelcomeStep> createState() => _OnboardingWelcomeStepState();
}

class _OnboardingWelcomeStepState extends State<OnboardingWelcomeStep>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _fadeController;
  late Animation<double> _floatAnimation;
  late Animation<double> _fadeAnimation;

  final List<String> _transformationImages = [
    'assets/images/moc_one.jpg',
    'assets/images/moc_two.jpg',
    'assets/images/moc_three.jpg',
    'assets/images/moc_four.png',
    'assets/images/moc_five.png',
    'assets/images/moc_six.png',
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _floatController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Transformation Images Display
          SizedBox(
            height: 350,
            width: double.infinity,
            child: Stack(
              children: [
                // Floating transformation images
                ...List.generate(_transformationImages.length, (index) {
                  return _FloatingImage(
                    imagePath: _transformationImages[index],
                    index: index,
                    floatAnimation: _floatAnimation,
                    fadeAnimation: _fadeAnimation,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Lifestyle Transformation Message
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Transform Your Body,\n',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppConstants.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: 'Transform Your Life',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppConstants.primaryColor,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Join thousands who have discovered the power of\npersonalized nutrition and fitness coaching',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: AppConstants.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Your journey to a healthier you starts here',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingImage extends StatelessWidget {
  final String imagePath;
  final int index;
  final Animation<double> floatAnimation;
  final Animation<double> fadeAnimation;

  const _FloatingImage({
    required this.imagePath,
    required this.index,
    required this.floatAnimation,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = 350.0;
    final availableWidth = screenWidth - 48.0; // Account for 24px padding on each side from OnboardingStepPage
    
    final sizes = [120.0, 110.0, 130.0, 115.0, 125.0, 120.0];
    final rotations = [0.1, -0.15, 0.2, -0.1, 0.15, -0.2];
    
    final size = sizes[index % sizes.length];
    final rotation = rotations[index % rotations.length];
    
    // Simple balanced positioning
    final positions = [
      Offset(20, screenHeight * 0.1), // Top left
      Offset(availableWidth - size - 20, screenHeight * 0.05), // Top right
      Offset(10, screenHeight * 0.35), // Middle left
      Offset(availableWidth - size - 10, screenHeight * 0.3), // Middle right
      Offset(25, screenHeight * 0.6), // Bottom left
      Offset(availableWidth - size - 25, screenHeight * 0.55), // Bottom right
    ];
    
    final position = positions[index % positions.length];
    
    // Create floating animation offset
    final floatOffset = floatAnimation.value * 10 * math.sin(index * 0.5);
    
    return Positioned(
      left: position.dx,
      top: position.dy + floatOffset,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Transform.rotate(
          angle: rotation + (floatAnimation.value * 0.1),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: size,
                height: size,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
