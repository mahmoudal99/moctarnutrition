import 'package:champions_gym_app/shared/services/onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../profile/presentation/screens/privacy_policy_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool isSignUp;
  
  const AuthScreen({super.key, this.isSignUp = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static final _logger = Logger();
  late bool _isSignUp; // Will be initialized in initState
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false; // New field for terms acceptance

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
          child: Column(
            children: [
              const SizedBox(height: AppConstants.spacingXL),
              _buildHeader(),
              const SizedBox(height: AppConstants.spacingL),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAuthForm(),
                    const SizedBox(height: AppConstants.spacingM),
                    _buildSocialAuth(),
                    const SizedBox(height: AppConstants.spacingM),
                    _buildGuestOption(),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppConstants.primaryGradient,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            boxShadow: AppConstants.shadowM,
          ),
          child: const Icon(
            Icons.fitness_center,
            size: 40,
            color: AppConstants.surfaceColor,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          _isSignUp ? 'Create Account' : 'Welcome Back!',
          style: AppTextStyles.heading3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingXS),
        Text(
          _isSignUp 
              ? 'Create your account to save your progress'
              : 'Welcome back! Sign in to continue',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppConstants.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  'Forgot Password?',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          if (_isSignUp) ...[
            const SizedBox(height: AppConstants.spacingS),
            _buildTermsCheckbox(),
          ],
          const SizedBox(height: AppConstants.spacingM),
          _buildAuthButton(),
          const SizedBox(height: AppConstants.spacingS),
          _buildToggleAuth(),
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
          prefixIcon: Icon(icon, color: AppConstants.primaryColor, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          labelStyle: TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 14,
          ),
          floatingLabelStyle: TextStyle(
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
            text: authProvider.isLoading 
                ? 'Please wait...' 
                : (_isSignUp ? 'Create Account' : 'Sign In'),
            isLoading: authProvider.isLoading,
            onPressed: _handleAuth,
          ),
        );
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
        ),
        boxShadow: AppConstants.shadowS,
      ),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
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
                          color: AppConstants.primaryColor,
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
                          color: AppConstants.primaryColor,
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
      ),
    );
  }

  Widget _buildToggleAuth() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp 
              ? 'Already have an account? ' 
              : 'Don\'t have an account? ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isSignUp = !_isSignUp;
              _acceptedTerms = false; // Reset terms acceptance when switching modes
            });
          },
          child: Text(
            _isSignUp ? 'Sign In' : 'Sign Up',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w600,
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
            Expanded(child: Divider(color: AppConstants.textTertiary.withOpacity(0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
              child: Text(
                'or',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textTertiary,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppConstants.textTertiary.withOpacity(0.3))),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                'Google',
                Icons.g_mobiledata,
                AppConstants.errorColor,
                () => _handleGoogleSignIn(),
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
            Expanded(
              child: _buildSocialButton(
                'Apple',
                Icons.apple,
                AppConstants.textPrimary,
                () => _handleAppleSignIn(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
        ),
        boxShadow: AppConstants.shadowS,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppConstants.spacingXS),
              Text(
                text,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestOption() {
    return Column(
      children: [
        // Text(
        //   'Want to try first?',
        //   style: AppTextStyles.caption.copyWith(
        //     color: AppConstants.textSecondary,
        //   ),
        // ),
        // TextButton(
        //   onPressed: _handleGuestAccess,
        //   style: TextButton.styleFrom(
        //     padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
        //     minimumSize: const Size(0, 32),
        //   ),
        //   child: Text(
        //     'Continue as Guest',
        //     style: AppTextStyles.caption.copyWith(
        //       color: AppConstants.primaryColor,
        //       fontWeight: FontWeight.w600,
        //     ),
        //   ),
        // ),
        // const SizedBox(height: AppConstants.spacingS),
        TextButton(
          onPressed: _handleBackToOnboarding,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
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
            content: Text('Please accept terms and conditions to create an account.'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
        return;
      }
      success = await authProvider.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
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
        _logger.i('AuthScreen - User data loaded, navigating to home');
        context.go('/home');
      } else {
        _logger.d('AuthScreen - Waiting for user data to load...');
        // Wait a bit for the auth state listener to load the user data
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && authProvider.userModel != null) {
          _logger.i('AuthScreen - User data loaded after delay, navigating to home');
          context.go('/home');
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
          content: Text('Please accept terms and conditions to create an account.'),
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
        _logger.i('AuthScreen - User data loaded, navigating to home');
        context.go('/home');
      } else {
        _logger.d('AuthScreen - Waiting for user data to load...');
        // Wait a bit for the auth state listener to load the user data
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && authProvider.userModel != null) {
          _logger.i('AuthScreen - User data loaded after delay, navigating to home');
          context.go('/home');
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
          content: Text('Please accept terms and conditions to create an account.'),
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
        _logger.i('AuthScreen - User data loaded, navigating to home');
        context.go('/home');
      } else {
        _logger.d('AuthScreen - Waiting for user data to load...');
        // Wait a bit for the auth state listener to load the user data
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && authProvider.userModel != null) {
          _logger.i('AuthScreen - User data loaded after delay, navigating to home');
          context.go('/home');
        }
      }
    } else if (mounted && authProvider.error != null) {
      // Show a more helpful error message for Apple Sign-In
      String errorMessage = authProvider.error!;
      if (errorMessage.contains('Apple sign in')) {
        errorMessage = 'Apple Sign-In is not configured yet. Please use email/password or Google Sign-In for now.';
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

  void _handleGuestAccess() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInAnonymously();

    if (success && mounted) {
      // Wait for user data to be loaded before navigating
      if (authProvider.userModel != null) {
        _logger.i('AuthScreen - User data loaded, navigating to home');
        context.go('/home');
      } else {
        _logger.d('AuthScreen - Waiting for user data to load...');
        // Wait a bit for the auth state listener to load the user data
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && authProvider.userModel != null) {
          _logger.i('AuthScreen - User data loaded after delay, navigating to home');
          context.go('/home');
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
            '• Use the app responsibly and in accordance with applicable laws\n'
            '• Provide accurate and truthful information\n'
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