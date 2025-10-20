import 'package:champions_gym_app/shared/services/onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:auth_buttons/auth_buttons.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
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
  late bool _isSignUp; // Will be initialized in initState
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false; // New field for terms acceptance
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isSignUp;
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animation with a small delay to ensure it's visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingL),
                child: Column(
                  children: [
                    const SizedBox(height: AppConstants.spacingXL * 1),
                    _buildAnimatedWidget(_buildHeader(), 0),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildAnimatedWidget(_buildAuthForm(), 1),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildAnimatedWidget(_buildSocialAuth(), 2),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildAnimatedWidget(_buildOnboardingOption(), 3),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildAnimatedWidget(_buildToggleAuth(), 4),
                    const SizedBox(height: AppConstants.spacingL),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedWidget(Widget child, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Create staggered delay for each widget
        final delay = index * 0.15; // 150ms delay between each widget
        final animationValue = (_animationController.value - delay).clamp(0.0, 1.0);
        
        return FadeTransition(
          opacity: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: AlwaysStoppedAnimation(animationValue),
            curve: Curves.easeInOut,
          )),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: AlwaysStoppedAnimation(animationValue),
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.spacingS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Welcome to ',
                  style: GoogleFonts.aBeeZee(
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                      color: Colors.black87),
                ),
                TextSpan(
                  text: 'Moctar Nutrition',
                  style:
                      GoogleFonts.ptSerif(fontSize: 24, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            _isSignUp
                ? 'Create your account to save your progress'
                : 'Let’s keep the momentum going!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_isSignUp) ...[
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              validator: (value) {
                if (_isSignUp && (value == null || value.isEmpty)) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spacingS),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (_isSignUp && (value == null || value.isEmpty)) {
                  return 'Please enter your phone number';
                }
                if (_isSignUp && value != null && value.isNotEmpty) {
                  // Basic phone number validation - can be enhanced
                  final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'Please enter a valid phone number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spacingS),
          ],
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingS),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: AppConstants.textTertiary,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          if (!_isSignUp) ...[
            const SizedBox(height: AppConstants.spacingS),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/password-reset'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingS),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  'Forgot Password?',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          if (_isSignUp) ...[
            const SizedBox(height: AppConstants.spacingM),
            _buildTermsCheckbox(),
          ],
          const SizedBox(height: AppConstants.spacingM),
          _buildAuthButton(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
        ),
        boxShadow: AppConstants.shadowS,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.black87, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          labelStyle: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 14,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppConstants.primaryColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            type: ButtonType.auth,
            text: authProvider.isLoading
                ? 'Please wait...'
                : (_isSignUp ? 'Sign Up' : 'Sign In'),
            isLoading: authProvider.isLoading,
            onPressed: _handleAuth,
          ),
        );
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptedTerms,
            onChanged: (value) {
              setState(() {
                _acceptedTerms = value ?? false;
              });
            },
            activeColor: AppConstants.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingS),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall.copyWith(
                color: AppConstants.textSecondary,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: _showTermsAndConditions,
                    child: Text(
                      'Terms and Conditions',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ' and '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: _showPrivacyPolicy,
                    child: Text(
                      'Privacy Policy',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleAuth() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? 'Already have an account? ' : 'Don\'t have an account? ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isSignUp = !_isSignUp;
              _acceptedTerms =
                  false; // Reset terms acceptance when switching modes
            });
            // Restart animation for smooth transition
            _animationController.reset();
            _animationController.forward();
          },
          child: Text(
            _isSignUp ? 'Sign In' : 'Sign Up',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialAuth() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child:
                    Divider(color: AppConstants.textTertiary.withOpacity(0.3))),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
              child: Text(
                'or',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textTertiary,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Expanded(
                child:
                    Divider(color: AppConstants.textTertiary.withOpacity(0.3))),
          ],
        ),
        const SizedBox(height: AppConstants.spacingL),
        Column(
          children: [
            GoogleAuthButton(
              onPressed: _handleGoogleSignIn,
              style: AuthButtonStyle(
                width: double.infinity,
                height: 52,
                borderRadius: AppConstants.radiusM,
                buttonType: AuthButtonType.secondary,
                textStyle: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                buttonColor: AppConstants.surfaceColor,
                borderColor: AppConstants.textTertiary.withOpacity(0.2),
                borderWidth: 1.0,
                iconSize: 20,
                elevation: 2.0,
                shadowColor: AppConstants.textTertiary.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            AppleAuthButton(
              onPressed: _handleAppleSignIn,
              style: AuthButtonStyle(
                width: double.infinity,
                height: 52,
                borderRadius: AppConstants.radiusM,
                buttonType: AuthButtonType.secondary,
                iconSize: 20,
                textStyle: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                buttonColor: AppConstants.surfaceColor,
                borderColor: AppConstants.textTertiary.withOpacity(0.2),
                borderWidth: 1.0,
                elevation: 2.0,
                shadowColor: AppConstants.textTertiary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOnboardingOption() {
    return Column(
      children: [
        TextButton(
          onPressed: _handleBackToOnboarding,
          style: TextButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
            minimumSize: const Size(0, 32),
          ),
          child: Text(
            'Back to Onboarding',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;

    if (_isSignUp) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please accept terms and conditions to create an account.'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
        return;
      }
      success = await authProvider.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
    } else {
      success = await authProvider.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      // Wait for user data to be loaded before navigating
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel != null) {
        _logger.i('AuthScreen - User data loaded, navigating to main route');
        context.go('/');
      } else {
        _logger.d('AuthScreen - Waiting for user data to load...');
        // Wait a bit for the auth state listener to load the user data
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && authProvider.userModel != null) {
          _logger.i(
              'AuthScreen - User data loaded after delay, navigating to main route');
          context.go('/');
        }
      }
    } else if (mounted && authProvider.error != null) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  void _handleGoogleSignIn() async {
    if (_isSignUp && !_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please accept terms and conditions to create an account.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      // Wait for user data to be loaded before navigating
      if (authProvider.userModel != null) {
        _logger.i('AuthScreen - User data loaded, navigating to main route');
        context.go('/');
      } else {
        _logger.d('AuthScreen - Waiting for user data to load...');
        // Wait a bit for the auth state listener to load the user data
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
          content: Text(authProvider.error!),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  void _handleAppleSignIn() async {
    if (_isSignUp && !_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please accept terms and conditions to create an account.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithApple();

    if (success && mounted) {
      // Wait for user data to be loaded before navigating
      if (authProvider.userModel != null) {
        _logger.i('AuthScreen - User data loaded, navigating to main route');
        context.go('/');
      } else {
        _logger.d('AuthScreen - Waiting for user data to load...');
        // Wait a bit for the auth state listener to load the user data
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && authProvider.userModel != null) {
          _logger.i(
              'AuthScreen - User data loaded after delay, navigating to main route');
          context.go('/');
        }
      }
    } else if (mounted && authProvider.error != null) {
      // Show a more helpful error message for Apple Sign-In
      String errorMessage = authProvider.error!;
      if (errorMessage.contains('Apple sign in')) {
        errorMessage =
            'Apple Sign-In is not configured yet. Please use email/password or Google Sign-In for now.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppConstants.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _handleBackToOnboarding() async {
    _logger.i('Back to Onboarding button pressed');
    // Reset onboarding state to show get started screen
    await OnboardingService.resetOnboardingState();
    if (mounted) {
      _logger.i('Navigating to get-started screen');
      // Navigate to get started screen directly
      context.go('/get-started');
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Terms and Conditions',
          style: AppTextStyles.heading4,
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
            style: AppTextStyles.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.primaryColor,
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
