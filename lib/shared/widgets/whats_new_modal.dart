import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../services/version_tracking_service.dart';

class WhatsNewModal extends StatelessWidget {
  final String currentVersion;

  const WhatsNewModal({
    super.key,
    required this.currentVersion,
  });

  void _markVersionAsViewed() {
    VersionTrackingService.markCurrentVersionAsViewed(currentVersion);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.new_releases,
                  color: AppConstants.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "What's New",
                    style: AppTextStyles.heading4.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _markVersionAsViewed();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVersionSection(
                      _getInitialVersion(currentVersion),
                      "Initial Release",
                      [
                        "🎉 Welcome to Moctar Nutrition!",
                        "📋 Personalized meal planning",
                        "🏋️ Custom workout plans",
                        "📈 Progress tracking and analytics",
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _markVersionAsViewed();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Got it!",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviousVersion(String currentVersion) {
    // Parse version string (e.g., "1.2.0" -> "1.1.0")
    final parts = currentVersion.split('.');
    if (parts.length >= 3) {
      final major = int.tryParse(parts[0]) ?? 1;
      final minor = int.tryParse(parts[1]) ?? 0;
      final patch = int.tryParse(parts[2]) ?? 0;

      if (patch > 0) {
        return '$major.$minor.${patch - 1}';
      } else if (minor > 0) {
        return '$major.${minor - 1}.9';
      } else if (major > 1) {
        return '${major - 1}.9.9';
      }
    }
    return '1.0.0';
  }

  String _getInitialVersion(String currentVersion) {
    // Always show 1.0.0 as initial version
    return '1.0.0';
  }

  Widget _buildVersionSection(
      String version, String title, List<String> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                version,
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
