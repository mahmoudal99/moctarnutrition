import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';

class AppConstants {
  // App Colors
  static const Color primaryColor = Color(0xFF10B981);
  static const Color secondaryColor = Color(0xFF34D399);
  static const Color accentColor = Color(0xFF059669);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color successColor = Color(0xFF10B981);

  // Macronutrient Colors
  static const Color proteinColor = Color(0xFF3B82F6); // Blue
  static const Color carbsColor = Color(0xFFF59E0B); // Orange
  static const Color fatColor = Color(0xFF8B5A2B); // Brown

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Border Colors
  static const Color borderColor = Color(0xFFE5E7EB);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryColor, Color(0xFF6EE7B7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Shadows
  static const List<BoxShadow> shadowS = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowM = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowL = [
    BoxShadow(
      color: Color(0x2A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}

class AppTextStyles {
  static TextStyle get heading1 => GoogleFonts.nunitoSans(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppConstants.textPrimary,
      );

  static TextStyle get heading2 => GoogleFonts.nunitoSans(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppConstants.textPrimary,
      );

  static TextStyle get heading3 => GoogleFonts.nunitoSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppConstants.textPrimary,
      );

  static TextStyle get heading4 => GoogleFonts.nunitoSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppConstants.textPrimary,
      );

  static TextStyle get heading5 => GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppConstants.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.nunitoSans(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: AppConstants.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppConstants.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppConstants.textSecondary,
      );

  static TextStyle get body1 => GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppConstants.textPrimary,
      );

  static TextStyle get body2 => GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppConstants.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.nunitoSans(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppConstants.textTertiary,
      );

  static TextStyle get button => GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppConstants.surfaceColor,
      );
}

/// Centralized logger configuration to fix ANSI escape codes
class AppLogger {
  static Logger get instance {
    return Logger(
      printer: PrettyPrinter(
        methodCount: 0, // Number of method calls to be displayed
        errorMethodCount: 8, // Number of method calls if stacktrace is provided
        lineLength: 120, // Width of the output
        colors: false, // Disable colors to avoid ANSI escape codes
        printEmojis: true, // Print an emoji for each log message
        printTime: true, // Should each log print contain a timestamp
      ),
    );
  }
}
