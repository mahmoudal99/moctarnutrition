import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../../../shared/providers/auth_provider.dart';

class UserNameExtractor {
  static String extractFirstName(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final name = authProvider.userModel?.name;

    if (name != null && name.isNotEmpty) {
      return name.split(' ').first;
    }
    return 'there';
  }
}
