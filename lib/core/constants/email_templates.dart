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
} 