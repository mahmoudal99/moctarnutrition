import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/version_tracking_service.dart';
import 'whats_new_modal.dart';

class WhatsNewWrapper extends StatefulWidget {
  final Widget child;
  final bool shouldCheckForNewVersion;

  const WhatsNewWrapper({
    super.key,
    required this.child,
    this.shouldCheckForNewVersion = true,
  });

  @override
  State<WhatsNewWrapper> createState() => _WhatsNewWrapperState();
}

class _WhatsNewWrapperState extends State<WhatsNewWrapper> {
  PackageInfo? _packageInfo;
  bool _hasCheckedVersion = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = packageInfo;
      });
      
      if (widget.shouldCheckForNewVersion) {
        _checkAndShowWhatsNew(packageInfo.version);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _checkAndShowWhatsNew(String currentVersion) async {
    if (_hasCheckedVersion) return;
    
    try {
      final hasViewed = await VersionTrackingService.hasViewedCurrentVersion(currentVersion);
      
      if (!hasViewed && mounted) {
        // Show the modal after a short delay to ensure the UI is fully loaded
        await Future.delayed(const Duration(milliseconds: 1000));
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => WhatsNewModal(currentVersion: currentVersion),
          );
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() {
        _hasCheckedVersion = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
} 