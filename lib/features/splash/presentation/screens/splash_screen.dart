import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _fadeController;

  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _fadeAnimation;
  
  int _authCheckAttempts = 0;
  static const int _maxAuthCheckAttempts = 10; // Max 2 seconds of waiting

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers with shorter durations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Text slide animation
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Fade animation for subtitle
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start text animation
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _textController.forward();
    }

    // Start fade animation
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      _fadeController.forward();
    }

    // Wait for animations to complete, then check auth state and navigate
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      _navigateBasedOnAuthState();
    }
  }

  void _navigateBasedOnAuthState() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Wait a bit more for auth state to be fully determined
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _authCheckAttempts++;
        
        if (authProvider.isLoading && _authCheckAttempts < _maxAuthCheckAttempts) {
          // Still loading, wait a bit more
          print('SplashScreen - Auth still loading, attempt $_authCheckAttempts/$_maxAuthCheckAttempts, waiting...');
          _navigateBasedOnAuthState();
          return;
        }
        
        // Either auth is ready or we've waited long enough
        if (_authCheckAttempts >= _maxAuthCheckAttempts) {
          print('SplashScreen - Max auth check attempts reached, proceeding with current state');
        }
        
        print('SplashScreen - Auth state determined:');
        print('  - isLoading: ${authProvider.isLoading}');
        print('  - isAuthenticated: ${authProvider.isAuthenticated}');
        print('  - firebaseUser: ${authProvider.firebaseUser?.email ?? 'null'}');
        print('  - userModel: ${authProvider.userModel?.name ?? 'null'}');
        
        if (authProvider.isAuthenticated) {
          // User is authenticated, navigate to home
          if (authProvider.userModel?.role == UserRole.admin) {
            print('SplashScreen - Navigating authenticated admin to /admin-home');
            context.go('/admin-home');
          } else {
            print('SplashScreen - Navigating authenticated user to /home');
            context.go('/home');
          }
        } else {
          // User is not authenticated, navigate to get-started
          print('SplashScreen - Navigating unauthenticated user to /get-started');
          context.go('/get-started');
        }
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Main title with slide animation
                SlideTransition(
                  position: _textSlideAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'MOCTAR NUTRITION',
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Subtitle with fade animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Personalized Nutrition & Fitness',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.black.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: 80),

                // Loading indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
