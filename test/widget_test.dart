// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:champions_gym_app/main.dart';
import 'package:champions_gym_app/features/admin/presentation/screens/admin_user_detail_screen.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Admin can start meal plan generation flow for a client', (WidgetTester tester) async {
    // Create a mock user
    final mockUser = UserModel(
      id: 'test_user',
      email: 'client@example.com',
      name: 'Test Client',
      role: UserRole.user,
      subscriptionStatus: SubscriptionStatus.premium,
      preferences: UserPreferences.defaultPreferences(),
      hasSeenSubscriptionScreen: true,
    );

    // Pump the AdminUserDetailScreen
    await tester.pumpWidget(
      MaterialApp(
        home: AdminUserDetailScreen(user: mockUser),
      ),
    );

    // Find the Generate Meal Plan button
    final generateButton = find.widgetWithText(ElevatedButton, 'Generate Meal Plan');
    expect(generateButton, findsOneWidget);

    // Tap the button and pump the navigation
    await tester.tap(generateButton);
    await tester.pumpAndSettle();

    // Should navigate to AdminMealPlanSetupScreen (look for AppBar title)
    expect(find.text('Generate Meal Plan'), findsOneWidget);

    // The DietPlanSetupFlow should be present (look for step 1 text)
    expect(find.text("What's your primary nutrition goal?"), findsOneWidget);
  });
}
