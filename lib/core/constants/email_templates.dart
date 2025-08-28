/// Email templates used throughout the app
class EmailTemplates {
  /// Template for bug report emails
  static String buildBugReportEmailBody({
    required String userInfo,
    required String deviceInfo,
    required String category,
    required String priority,
    required String title,
    required String description,
    required String stepsToReproduce,
    required String expectedBehavior,
    required String actualBehavior,
  }) {
    final timestamp = DateTime.now().toIso8601String();

    return '''
Bug Report Submission
====================

Timestamp: $timestamp

User Information:
$userInfo

Device Information:
$deviceInfo

Bug Details:
------------
Category: $category
Priority: $priority
Title: $title

Description:
$description

Steps to Reproduce:
${stepsToReproduce.isEmpty ? 'Not provided' : stepsToReproduce}

Expected Behavior:
${expectedBehavior.isEmpty ? 'Not provided' : expectedBehavior}

Actual Behavior:
${actualBehavior.isEmpty ? 'Not provided' : actualBehavior}

---
This bug report was submitted through the Moctar Nutrition app.
''';
  }

  /// Email subject template for bug reports
  static String buildBugReportSubject(String title) {
    return 'Bug Report: $title';
  }

  /// Email recipient for bug reports
  static const String bugReportEmail = 'mahmoud.al808@gmail.com';

  /// Template for feedback emails
  static String buildFeedbackEmailBody({
    required String userInfo,
    required String deviceInfo,
    required String category,
    required String rating,
    required String title,
    required String description,
    required String suggestions,
  }) {
    final timestamp = DateTime.now().toIso8601String();

    return '''
Feedback Submission
==================

Timestamp: $timestamp

User Information:
$userInfo

Device Information:
$deviceInfo

Feedback Details:
----------------
Category: $category
Rating: $rating
Title: $title

Description:
$description

Suggestions for Improvement:
${suggestions.isEmpty ? 'No suggestions provided' : suggestions}

---
This feedback was submitted through the Moctar Nutrition app.
''';
  }

  /// Email subject template for feedback
  static String buildFeedbackSubject(String title) {
    return 'Feedback: $title';
  }

  /// Email recipient for feedback
  static const String feedbackEmail = 'mahmoud.al808@gmail.com';

  /// EmailJS Template Examples
  ///
  /// These are examples of EmailJS templates you can use.
  /// Copy these templates to your EmailJS dashboard.

  /// Example EmailJS template for meal plan ready notification
  static const String emailJsMealPlanTemplate = '''
Subject: Your Personalized Meal Plan is Ready! 🍽️

<div style="font-family: system-ui, sans-serif, Arial; font-size: 14px; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="text-align: center; margin-bottom: 30px;">
    <h1 style="color: #2c3e50; margin: 0; font-size: 28px;">🍽️ Your Meal Plan is Ready!</h1>
    <p style="color: #7f8c8d; margin: 10px 0 0 0; font-size: 16px;">Personalized nutrition just for you</p>
  </div>

  <div style="background-color: #f8f9fa; padding: 25px; border-radius: 10px; margin-bottom: 25px;">
    <h2 style="color: #2c3e50; margin: 0 0 15px 0; font-size: 20px;">📋 Plan Details</h2>
    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
      <div style="background: white; padding: 15px; border-radius: 8px; border-left: 4px solid #3498db;">
        <div style="font-weight: bold; color: #2c3e50; margin-bottom: 5px;">Duration</div>
        <div style="color: #7f8c8d;">{{plan_duration}} days</div>
      </div>
      <div style="background: white; padding: 15px; border-radius: 8px; border-left: 4px solid #e74c3c;">
        <div style="font-weight: bold; color: #2c3e50; margin-bottom: 5px;">Fitness Goal</div>
        <div style="color: #7f8c8d;">{{fitness_goal}}</div>
      </div>
      <div style="background: white; padding: 15px; border-radius: 8px; border-left: 4px solid #f39c12;">
        <div style="font-weight: bold; color: #2c3e50; margin-bottom: 5px;">Daily Calories</div>
        <div style="color: #7f8c8d;">{{target_calories}} kcal</div>
      </div>
      <div style="background: white; padding: 15px; border-radius: 8px; border-left: 4px solid #27ae60;">
        <div style="font-weight: bold; color: #2c3e50; margin-bottom: 5px;">Plan ID</div>
        <div style="color: #7f8c8d; font-family: monospace; font-size: 12px;">{{meal_plan_id}}</div>
      </div>
    </div>
  </div>

  <div style="background-color: #e8f5e8; padding: 25px; border-radius: 10px; margin-bottom: 25px;">
    <h2 style="color: #2c3e50; margin: 0 0 15px 0; font-size: 20px;">🎯 What's Next?</h2>
    <ol style="color: #2c3e50; line-height: 1.6; margin: 0; padding-left: 20px;">
      <li>Open the Moctar Nutrition app</li>
      <li>Navigate to your meal plan section</li>
      <li>Start your nutrition journey!</li>
    </ol>
  </div>

  <div style="background-color: #fff3cd; padding: 25px; border-radius: 10px; margin-bottom: 25px;">
    <h2 style="color: #2c3e50; margin: 0 0 15px 0; font-size: 20px;">💡 Pro Tips</h2>
    <ul style="color: #2c3e50; line-height: 1.6; margin: 0; padding-left: 20px;">
      <li>Review your meal plan before starting</li>
      <li>Prepare your shopping list</li>
      <li>Consider batch cooking for convenience</li>
      <li>Stay hydrated throughout the day</li>
    </ul>
  </div>

  <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ecf0f1;">
    <p style="color: #7f8c8d; margin: 0; font-size: 14px;">
      Generated on: {{current_date}}<br>
      App: {{app_name}}
    </p>
  </div>
</div>
''';

  /// Example EmailJS template for generic notifications
  static const String emailJsNotificationTemplate = '''
Subject: {{subject}}

<div style="font-family: system-ui, sans-serif, Arial; font-size: 14px; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="text-align: center; margin-bottom: 30px;">
    <h1 style="color: #2c3e50; margin: 0; font-size: 24px;">{{subject}}</h1>
  </div>

  <div style="background-color: #f8f9fa; padding: 25px; border-radius: 10px; margin-bottom: 25px;">
    <div style="color: #2c3e50; line-height: 1.6; font-size: 16px;">
      {{message}}
    </div>
  </div>

  <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ecf0f1;">
    <p style="color: #7f8c8d; margin: 0; font-size: 14px;">
      Generated on: {{current_date}}<br>
      App: {{app_name}}
    </p>
  </div>
</div>
''';
}
