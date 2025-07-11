import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            children: [
              const SizedBox(height: AppConstants.spacingXL),
              _buildHeader(),
              const SizedBox(height: AppConstants.spacingXL),
              _buildAuthForm(),
              const SizedBox(height: AppConstants.spacingL),
              _buildSocialAuth(),
              const SizedBox(height: AppConstants.spacingL),
              _buildGuestOption(),
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
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: AppConstants.primaryGradient,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            boxShadow: AppConstants.shadowL,
          ),
          child: const Icon(
            Icons.fitness_center,
            size: 60,
            color: AppConstants.surfaceColor,
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),
        Text(
          'Almost there!',
          style: AppTextStyles.heading2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          _isSignUp 
              ? 'Create your account to save your progress'
              : 'Welcome back! Sign in to continue',
          style: AppTextStyles.bodyLarge.copyWith(
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
            const SizedBox(height: AppConstants.spacingM),
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
          const SizedBox(height: AppConstants.spacingM),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: AppConstants.textTertiary,
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
          const SizedBox(height: AppConstants.spacingL),
          _buildAuthButton(),
          const SizedBox(height: AppConstants.spacingM),
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
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.3),
        ),
        boxShadow: AppConstants.shadowS,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppConstants.primaryColor),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppConstants.spacingL),
          labelStyle: TextStyle(color: AppConstants.textSecondary),
        ),
      ),
    );
  }

  Widget _buildAuthButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: _isLoading 
            ? 'Please wait...' 
            : (_isSignUp ? 'Create Account' : 'Sign In'),
        isLoading: _isLoading,
        onPressed: _handleAuth,
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
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isSignUp = !_isSignUp;
            });
          },
          child: Text(
            _isSignUp ? 'Sign In' : 'Sign Up',
            style: AppTextStyles.bodyMedium.copyWith(
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
            Expanded(child: Divider(color: AppConstants.textTertiary)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
              child: Text(
                'Or continue with',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppConstants.textTertiary)),
          ],
        ),
        const SizedBox(height: AppConstants.spacingL),
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
            const SizedBox(width: AppConstants.spacingM),
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
      height: 56,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.3),
        ),
        boxShadow: AppConstants.shadowS,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
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
        const SizedBox(height: AppConstants.spacingL),
        Text(
          'Want to try first?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        TextButton(
          onPressed: _handleGuestAccess,
          child: Text(
            'Continue as Guest',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual authentication
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      // Navigate to main app
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement Google Sign-In
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement Apple Sign-In
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple Sign-In failed: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleGuestAccess() {
    // TODO: Save user preferences and continue as guest
    context.go('/');
  }
} 