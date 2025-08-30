import 'package:flutter/material.dart';

class AvatarUtils {
  /// Generates initials from a user's name
  /// If name is null or empty, falls back to first letter of email
  /// If email is also null/empty, returns 'U' as default
  static String getInitials(String? name, String? email) {
    if (name != null && name.trim().isNotEmpty) {
      final nameParts = name.trim().split(' ');
      if (nameParts.length >= 2) {
        // Return first letter of first and last name
        return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
      } else if (nameParts.length == 1) {
        // Return first two letters of single name, or first letter if only one character
        final name = nameParts.first;
        return name.length >= 2
            ? name.substring(0, 2).toUpperCase()
            : name[0].toUpperCase();
      }
    }

    // Fallback to email
    if (email != null && email.trim().isNotEmpty) {
      final emailName = email.split('@').first;
      return emailName.length >= 2
          ? emailName.substring(0, 2).toUpperCase()
          : emailName[0].toUpperCase();
    }

    // Default fallback
    return 'U';
  }

  /// Generates a consistent background color for avatars based on user data
  /// This ensures the same user always gets the same color
  static Color getAvatarBackgroundColor(String? name, String? email) {
    final String seed = name ?? email ?? 'default';
    final int hash = seed.hashCode;

    // Use a predefined set of colors for consistency
    final List<Color> colors = [
      const Color(0xFF10B981), // Primary green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFEF4444), // Red
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF84CC16), // Lime
      const Color(0xFFEC4899), // Pink
    ];

    return colors[hash.abs() % colors.length];
  }

  /// Creates a CircleAvatar widget with consistent styling
  /// Shows user photo if available, otherwise shows initials
  static Widget buildAvatar({
    required String? photoUrl,
    required String? name,
    required String? email,
    double radius = 24,
    double? fontSize,
  }) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(photoUrl),
        backgroundColor: Colors.grey[200],
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback to initials if image fails to load
        },
      );
    } else {
      final initials = getInitials(name, email);
      final backgroundColor = getAvatarBackgroundColor(name, email);
      const textColor = Colors.white;

      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Text(
          initials,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize ?? (radius * 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }
}
