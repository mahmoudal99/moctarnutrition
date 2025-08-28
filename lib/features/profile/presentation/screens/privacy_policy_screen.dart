import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Information We Collect',
              content: [
                'Personal information (name, email address, profile photo)',
                'Health and fitness data (weight, height, BMI, dietary preferences)',
                'Meal plan and nutrition information',
                'Check-in data and progress tracking',
                'App usage data and preferences',
                'Device information and analytics',
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'How We Use Your Information',
              content: [
                'To provide personalized meal plans and nutrition recommendations',
                'To track your progress and provide insights',
                'To improve our services and user experience',
                'To communicate with you about your account and updates',
                'To ensure app security and prevent fraud',
                'To comply with legal obligations',
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Data Storage Services',
              content: [
                'Firebase Authentication - User authentication and account management',
                'Cloud Firestore - Database storage for user data, meal plans, and progress',
                'Firebase Storage - File storage for profile photos and images',
                'Firebase Analytics - App usage analytics and performance monitoring',
                'Firebase Cloud Functions - Backend processing and AI meal generation',
                'Local Device Storage - Cached data for offline functionality',
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Third-Party Services',
              content: [
                'Google Sign-In - Authentication service',
                'Apple Sign-In - Authentication service (iOS)',
                'USDA Food Database API - Nutritional information',
                'Open Food Facts API - Food product data',
                'Payment processors (for premium subscriptions)',
                'Analytics and crash reporting services',
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Data Security',
              content: [
                'All data is encrypted in transit using HTTPS/TLS',
                'Firebase provides enterprise-grade security',
                'Authentication is handled securely through Firebase Auth',
                'Regular security audits and updates',
                'Access controls and user permissions',
                'Data backup and disaster recovery procedures',
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Data Retention',
              content: [
                'Account data is retained while your account is active',
                'You can request data deletion at any time',
                'Some data may be retained for legal compliance',
                'Analytics data is anonymized and retained for service improvement',
                'Backup data is retained for disaster recovery',
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Your Rights',
              content: [
                'Access your personal data',
                'Update or correct your information',
                'Request data deletion',
                'Export your data',
                'Opt-out of analytics and marketing communications',
                'Contact us with privacy concerns',
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Children\'s Privacy',
              content: [
                'Our service is not intended for children under 13',
                'We do not knowingly collect data from children under 13',
                'If we discover we have collected data from a child under 13, we will delete it',
                'Parents can contact us to request data deletion for their children',
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'International Data Transfers',
              content: [
                'Data may be processed in countries other than your own',
                'We ensure adequate data protection measures are in place',
                'Firebase services comply with international data protection standards',
                'We follow applicable data protection laws and regulations',
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Changes to This Policy',
              content: [
                'We may update this privacy policy from time to time',
                'You will be notified of significant changes via email or app notification',
                'Continued use of the app after changes constitutes acceptance',
                'You can review the current policy at any time in the app',
              ],
            ),
            const SizedBox(height: 20),
            _buildContactSection(),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip,
                    color: AppConstants.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Privacy Policy',
                  style: AppTextStyles.heading5.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().year}',
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This Privacy Policy explains how Moctar Nutrition collects, uses, and protects your personal information when you use our mobile application.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> content,
  }) {
    return Card(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...content.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Us',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'If you have any questions about this Privacy Policy or our data practices, please contact us:',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildContactItem(
              icon: Icons.email,
              label: 'Email',
              value: 'mahmoud.al808@gmail.com',
            ),
            const SizedBox(height: 8),
            _buildContactItem(
              icon: Icons.access_time,
              label: 'Response Time',
              value: 'Within 48 hours',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppConstants.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
