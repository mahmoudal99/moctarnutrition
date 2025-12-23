import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/onboarding_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // Dark background color
  static const Color _backgroundColor = Color(0xFF191a1a);
  static const Color _accentColor = Color(0xFF4CAF50);
  static const Color _secondaryAccent = Color(0xFF81C784);

  @override
  void initState() {
    super.initState();
    
    // Fade animation for the image
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Scale animation for the image
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Slide animation for content
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Pulse animation for the glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Stagger the animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imageSize = size.width * 0.65;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Subtle gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  _accentColor.withOpacity(0.05),
                  _backgroundColor,
                ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                // Center image with animations
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _fadeAnimation,
                    _scaleAnimation,
                    _pulseAnimation,
                  ]),
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: imageSize,
                          height: imageSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              // Outer glow
                              BoxShadow(
                                color: _accentColor.withOpacity(_pulseAnimation.value * 0.3),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                              // Inner shadow
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.asset(
                                  'assets/images/nature.jpeg',
                                  fit: BoxFit.cover,
                                  width: imageSize,
                                  height: imageSize,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const Spacer(flex: 1),
                
                // Text content with slide animation
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          // Main headline
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Achieve your fitness\n',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    height: 1.3,
                                  ),
                                ),
                                TextSpan(
                                  text: 'goals',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                    color: _secondaryAccent,
                                  ),
                                ),
                                TextSpan(
                                  text: ', your way',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Subtitle
                          Text(
                            "Build strength, balance and energy\none session at a time.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.6),
                              height: 1.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const Spacer(flex: 1),
                
                // Buttons with slide animation
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Get Started Button
                          SizedBox(
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
                                foregroundColor: _backgroundColor,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Get Started',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _backgroundColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Login link
                          GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              await OnboardingService.markGetStartedAsSeen();
                              await OnboardingService.markOnboardingAsSeen();
                              if (mounted) {
                                context.go('/auth');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Already a Member? ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Log In',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
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
          const SizedBox(height: 40),
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
