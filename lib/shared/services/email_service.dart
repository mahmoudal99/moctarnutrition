import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../core/constants/emailjs_config.dart';

class EmailService {
  static final Logger _logger = Logger();

  /// Send a meal plan ready notification email
  static Future<bool> sendMealPlanReadyEmail({
    required String userEmail,
    required String userName,
    required String mealPlanId,
    required int planDuration,
    required String fitnessGoal,
    required int targetCalories,
  }) async {
    try {
      _logger.i('Sending meal plan ready email to: $userEmail');

      // Check if EmailJS is enabled
      if (!EmailJSConfig.enabled) {
        _logger.i('EmailJS is disabled, skipping email send');
        return true;
      }

      // Try direct EmailJS API call first
      final response = await http.post(
        Uri.parse(EmailJSConfig.apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': EmailJSConfig.serviceId,
          'template_id': EmailJSConfig.templateId,
          'user_id': EmailJSConfig.publicKey,
          'accessToken': EmailJSConfig.privateKey,
          'template_params': {
            'user_email': userEmail,
            'user_name': userName,
            'meal_plan_id': mealPlanId,
            'plan_duration': planDuration.toString(),
            'fitness_goal': fitnessGoal,
            'target_calories': targetCalories.toString(),
            'app_name': 'Moctar Nutrition',
            'current_date': DateTime.now().toIso8601String(),
          },
        }),
      );

      if (response.statusCode == 200) {
        _logger.i('Meal plan ready email sent successfully to: $userEmail');
        return true;
      } else if (response.statusCode == 403 &&
          response.body.contains('non-browser applications')) {
        _logger.w(
            'EmailJS API calls are disabled for non-browser applications. This is expected for mobile apps.');
        _logger.i(
            'Consider using a web proxy service or alternative email service for production.');
        return false;
      } else {
        _logger.e(
            'Failed to send meal plan ready email. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('Error sending meal plan ready email: $e');
      return false;
    }
  }

  /// Send a generic notification email
  static Future<bool> sendNotificationEmail({
    required String userEmail,
    required String userName,
    required String subject,
    required String message,
    Map<String, String>? additionalParams,
  }) async {
    try {
      _logger.i('Sending notification email to: $userEmail');

      // Check if EmailJS is enabled
      if (!EmailJSConfig.enabled) {
        _logger.i('EmailJS is disabled, skipping email send');
        return true;
      }

      final templateParams = {
        'user_email': userEmail,
        'user_name': userName,
        'subject': subject,
        'message': message,
        'app_name': 'Moctar Nutrition',
        'current_date': DateTime.now().toIso8601String(),
        ...?additionalParams,
      };

      final response = await http.post(
        Uri.parse(EmailJSConfig.apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': EmailJSConfig.serviceId,
          'template_id': EmailJSConfig.templateId,
          'user_id': EmailJSConfig.publicKey,
          'accessToken': EmailJSConfig.privateKey,
          'template_params': templateParams,
        }),
      );

      if (response.statusCode == 200) {
        _logger.i('Notification email sent successfully to: $userEmail');
        return true;
      } else if (response.statusCode == 403 &&
          response.body.contains('non-browser applications')) {
        _logger.w(
            'EmailJS API calls are disabled for non-browser applications. This is expected for mobile apps.');
        return false;
      } else {
        _logger.e(
            'Failed to send notification email. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('Error sending notification email: $e');
      return false;
    }
  }

  /// Test the EmailJS connection
  static Future<bool> testConnection() async {
    try {
      _logger.i('Testing EmailJS connection...');

      // Check if EmailJS is enabled
      if (!EmailJSConfig.enabled) {
        _logger.i('EmailJS is disabled, connection test skipped');
        return true;
      }

      final response = await http.post(
        Uri.parse(EmailJSConfig.apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': EmailJSConfig.serviceId,
          'template_id': EmailJSConfig.templateId,
          'user_id': EmailJSConfig.publicKey,
          'accessToken': EmailJSConfig.privateKey,
          'template_params': {
            'user_email': 'test@example.com',
            'user_name': 'Test User',
            'subject': 'Test Email',
            'message': 'This is a test email from Moctar Nutrition app.',
            'app_name': 'Moctar Nutrition',
            'current_date': DateTime.now().toIso8601String(),
          },
        }),
      );

      if (response.statusCode == 200) {
        _logger.i('EmailJS connection test successful');
        return true;
      } else if (response.statusCode == 403 &&
          response.body.contains('non-browser applications')) {
        _logger.w(
            'EmailJS API calls are disabled for non-browser applications. This is expected for mobile apps.');
        return false;
      } else {
        _logger.e(
            'EmailJS connection test failed. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('Error testing EmailJS connection: $e');
      return false;
    }
  }

  /// Send a test meal plan ready email
  static Future<bool> sendTestMealPlanEmail({
    required String testEmail,
    String? testName,
  }) async {
    try {
      _logger.i('Sending test meal plan email to: $testEmail');

      // Check if EmailJS is enabled
      if (!EmailJSConfig.enabled) {
        _logger.i('EmailJS is disabled, skipping test email');
        return true;
      }

      final response = await http.post(
        Uri.parse(EmailJSConfig.apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': EmailJSConfig.serviceId,
          'template_id': EmailJSConfig.templateId,
          'user_id': EmailJSConfig.publicKey,
          'accessToken': EmailJSConfig.privateKey,
          'template_params': {
            'user_email': testEmail,
            'user_name': testName ?? testEmail.split('@').first,
            'meal_plan_id':
                'TEST_PLAN_${DateTime.now().millisecondsSinceEpoch}',
            'plan_duration': '7',
            'fitness_goal': 'Weight Loss',
            'target_calories': '2000',
            'app_name': 'Moctar Nutrition',
            'current_date': DateTime.now().toIso8601String(),
          },
        }),
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Test meal plan email sent successfully to: $testEmail');
        return true;
      } else if (response.statusCode == 403 &&
          response.body.contains('non-browser applications')) {
        _logger
            .w('❌ EmailJS API calls are disabled for non-browser applications');
        return false;
      } else {
        _logger.e(
            '❌ Failed to send test email. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Error sending test email: $e');
      return false;
    }
  }

  /// Alternative: Send email using a web proxy service
  /// This is a workaround for the EmailJS browser-only restriction
  static Future<bool> sendEmailViaProxy({
    required String userEmail,
    required String userName,
    required String subject,
    required String message,
    Map<String, String>? additionalParams,
  }) async {
    try {
      _logger.i('Attempting to send email via proxy to: $userEmail');

      // This would require setting up a web proxy service
      // For now, we'll just log that this method is available
      _logger.w(
          'Proxy email service not implemented yet. Consider using a service like:');
      _logger.w('- Firebase Functions with Nodemailer');
      _logger.w('- AWS Lambda with SES');
      _logger.w('- Google Cloud Functions with SendGrid');

      return false;
    } catch (e) {
      _logger.e('Error sending email via proxy: $e');
      return false;
    }
  }
}
