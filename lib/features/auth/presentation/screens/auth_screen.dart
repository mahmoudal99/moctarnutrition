import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../profile/presentation/screens/privacy_policy_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool isSignUp;

  const AuthScreen({super.key, this.isSignUp = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  static final _logger = Logger();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Dark background color
  static const Color _backgroundColor = Color(0xFF191a1a);
  static const Color _surfaceColor = Color(0xFF2a2b2b);
  static const Color _borderColor = Color(0xFF3a3b3b);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Top image with gradient blend
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: Stack(
              children: [
                // Image
                Image.asset(
                  'assets/images/public_gym.jpeg',
                  width: double.infinity,
                  height: size.height * 0.45,
                  fit: BoxFit.cover,
                ),
                // Gradient overlay to blend into background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        _backgroundColor.withOpacity(0.3),
                        _backgroundColor.withOpacity(0.7),
                        _backgroundColor,
                      ],
                      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cancel button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: TextButton(
              onPressed: () => context.go('/get-started'),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Spacer for image area
                SizedBox(height: size.height * 0.28),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL, vertical: AppConstants.spacingXXL * 2),
                          child: Column(
                            children: [
                              // Logo/App name
                              _buildLogo(),
                              const SizedBox(height: 24),

                              // Auth buttons
                              _buildAuthButtons(),

                              const SizedBox(height: 24),

                              // Privacy policy and Terms links
                              _buildFooterLinks(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Text(
      'regimen',
      style: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w300,
        color: Colors.white,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildAuthButtons() {
    return Column(
      children: [
        // Apple Sign In Button
        _buildAuthButton(
          onPressed: _handleAppleSignIn,
          icon: Icons.apple,
          label: 'Continue with Apple',
          backgroundColor: Colors.white,
          textColor: Colors.black,
        ),
        const SizedBox(height: 12),

        // Google Sign In Button
        _buildAuthButton(
          onPressed: _handleGoogleSignIn,
          icon: null,
          customIcon: Image.network(
            'https://www.google.com/favicon.ico',
            width: 20,
            height: 20,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.g_mobiledata,
              color: Colors.black,
              size: 24,
            ),
          ),
          label: 'Continue with Google',
          backgroundColor: Colors.white,
          textColor: Colors.black,
        ),
        const SizedBox(height: 12),

        // Email Sign In Button
        _buildAuthButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/email-auth');
          },
          icon: Icons.email_outlined,
          label: 'Continue with email',
          backgroundColor: _surfaceColor,
          textColor: Colors.white,
          borderColor: _borderColor,
        ),
        const SizedBox(height: 12),

        // Sign Up Button
        _buildAuthButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/email-auth-signup');
          },
          icon: Icons.person_add_outlined,
          label: 'Create account',
          backgroundColor: _surfaceColor,
          textColor: Colors.white,
          borderColor: _borderColor,
        ),
      ],
    );
  }

  Widget _buildAuthButton({
    required VoidCallback onPressed,
    IconData? icon,
    Widget? customIcon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: borderColor ?? Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: 20),
            if (customIcon != null) customIcon,
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _showPrivacyPolicy,
          child: Text(
            'Privacy policy',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: _showTermsAndConditions,
          child: Text(
            'Terms of service',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
        ),
      ],
    );
  }

  void _handleGoogleSignIn() async {
    HapticFeedback.lightImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      if (authProvider.userModel != null) {
        _logger.i('AuthScreen - User data loaded, navigating to main route');
        context.go('/');
      } else {
        _logger.d('AuthScreen - Waiting for user data to load...');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && authProvider.userModel != null) {
          _logger.i(
              'AuthScreen - User data loaded after delay, navigating to main route');
          context.go('/');
        }
      }
    } else if (mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.error!,
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleAppleSignIn() async {
    HapticFeedback.lightImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithApple();

    if (success && mounted) {
      if (authProvider.userModel != null) {
        _logger.i('AuthScreen - User data loaded, navigating to main route');
        context.go('/');
      } else {
        _logger.d('AuthScreen - Waiting for user data to load...');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && authProvider.userModel != null) {
          _logger.i(
              'AuthScreen - User data loaded after delay, navigating to main route');
          context.go('/');
        }
      }
    } else if (mounted && authProvider.error != null) {
      String errorMessage = authProvider.error!;
      if (errorMessage.contains('Apple sign in')) {
        errorMessage =
            'Apple Sign-In is not configured yet. Please use email/password or Google Sign-In for now.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceColor,
        title: Text(
          'Terms and Conditions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'By using Moctar Nutrition, you agree to:\n\n'
            '• Provide accurate information\n'
            '• Not share your account credentials with others\n'
            '• Respect the privacy and rights of other users\n'
            '• Follow our community guidelines\n\n'
            'We reserve the right to modify these terms at any time. '
            'Continued use of the app constitutes acceptance of any changes.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }
}
