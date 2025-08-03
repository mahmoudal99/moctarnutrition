import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/providers/auth_provider.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isResetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
          child: Column(
            children: [
              const SizedBox(height: AppConstants.spacingXL),
              _buildHeader(),
              const SizedBox(height: AppConstants.spacingL),
              Expanded(
                child: _isResetSent ? _buildSuccessView() : _buildResetForm(),
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
            Icons.lock_reset,
            size: 40,
            color: AppConstants.surfaceColor,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          'Reset Password',
          style: AppTextStyles.heading3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingXS),
        Text(
          'Enter your email address and we\'ll send you a link to reset your password',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppConstants.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildEmailField(),
          const SizedBox(height: AppConstants.spacingL),
          _buildResetButton(),
          const SizedBox(height: AppConstants.spacingM),
          _buildBackToSignIn(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
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
        controller: _emailController,
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
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          labelText: 'Email',
          prefixIcon: const Icon(Icons.email, color: AppConstants.primaryColor, size: 20),
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

  Widget _buildResetButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: authProvider.isLoading ? 'Sending...' : 'Send Reset Link',
            isLoading: authProvider.isLoading,
            onPressed: _handleResetPassword,
          ),
        );
      },
    );
  }

  Widget _buildBackToSignIn() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Remember your password? ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: Text(
            'Sign In',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppConstants.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Icon(
            Icons.check_circle,
            size: 60,
            color: AppConstants.successColor,
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),
        Text(
          'Check Your Email',
          style: AppTextStyles.heading3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          'We\'ve sent a password reset link to\n${_emailController.text}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppConstants.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(
              color: AppConstants.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingXS),
                  Text(
                    'Email not in your inbox?',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingXS),
              Text(
                '• Check your spam/junk folder\n• Make sure the email address is correct\n• Wait a few minutes for delivery',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingXL),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: 'Back to Sign In',
            onPressed: () => context.pop(),
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        TextButton(
          onPressed: _handleResendEmail,
          child: Text(
            'Didn\'t receive the email? Resend',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(_emailController.text.trim());

    if (success && mounted) {
      setState(() {
        _isResetSent = true;
      });
    } else if (mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  void _handleResendEmail() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(_emailController.text.trim());

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset link sent again!'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } else if (mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }
} 