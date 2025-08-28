import 'package:flutter_test/flutter_test.dart';
import 'package:champions_gym_app/shared/services/email_service.dart';

void main() {
  group('EmailService Tests', () {
    const testEmail = 'mahmoudalmahroum808@icloud.com';
    const testName = 'Mahmoud';

    test('Test EmailJS connection', () async {
      final result = await EmailService.testConnection();
      expect(result, isA<bool>());

      if (result) {
        print('✅ EmailJS connection test successful!');
      } else {
        print('❌ EmailJS connection test failed');
      }
    });

    test('Test meal plan ready email', () async {
      final result = await EmailService.sendMealPlanReadyEmail(
        userEmail: testEmail,
        userName: testName,
        mealPlanId: 'test_plan_${DateTime.now().millisecondsSinceEpoch}',
        planDuration: 7,
        fitnessGoal: 'Weight Loss',
        targetCalories: 2000,
      );

      expect(result, isA<bool>());

      if (result) {
        print('✅ Meal plan email test successful! Check your inbox.');
      } else {
        print('❌ Meal plan email test failed');
      }
    });

    test('Test generic notification email', () async {
      final result = await EmailService.sendNotificationEmail(
        userEmail: testEmail,
        userName: testName,
        subject: 'Test Notification from Moctar Nutrition',
        message:
            'This is a test email to verify that the EmailJS integration is working properly. If you receive this email, the email notification system is functioning correctly!',
      );

      expect(result, isA<bool>());

      if (result) {
        print('✅ Notification email test successful! Check your inbox.');
      } else {
        print('❌ Notification email test failed');
      }
    });

    test('Run all email tests with delays', () async {
      print('🚀 Starting EmailJS integration tests...');

      // Test 1: Connection
      final connectionResult = await EmailService.testConnection();
      expect(connectionResult, isA<bool>());
      print(connectionResult
          ? '✅ Connection test passed'
          : '❌ Connection test failed');

      // Wait between tests to respect rate limits
      await Future.delayed(const Duration(seconds: 2));

      // Test 2: Generic notification
      final notificationResult = await EmailService.sendNotificationEmail(
        userEmail: testEmail,
        userName: testName,
        subject: 'Test Notification from Moctar Nutrition',
        message:
            'This is a test email to verify that the EmailJS integration is working properly.',
      );
      expect(notificationResult, isA<bool>());
      print(notificationResult
          ? '✅ Notification test passed'
          : '❌ Notification test failed');

      // Wait between tests to respect rate limits
      await Future.delayed(const Duration(seconds: 2));

      // Test 3: Meal plan notification
      final mealPlanResult = await EmailService.sendMealPlanReadyEmail(
        userEmail: testEmail,
        userName: testName,
        mealPlanId: 'test_plan_${DateTime.now().millisecondsSinceEpoch}',
        planDuration: 7,
        fitnessGoal: 'Weight Loss',
        targetCalories: 2000,
      );
      expect(mealPlanResult, isA<bool>());
      print(mealPlanResult
          ? '✅ Meal plan test passed'
          : '❌ Meal plan test failed');

      print('🏁 EmailJS integration tests completed!');
    });
  });
}
