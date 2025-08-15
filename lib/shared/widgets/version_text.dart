import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'whats_new_modal.dart';

class VersionText extends StatefulWidget {
  const VersionText({super.key});

  @override
  State<VersionText> createState() => _VersionTextState();
}

class _VersionTextState extends State<VersionText> {
  PackageInfo? packageInfo;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    loadPackageInfo();
    super.initState();
  }

  void loadPackageInfo() async {
    var result = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = result;
    });
  }

  void _showWhatsNewModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => WhatsNewModal(
        currentVersion: packageInfo?.version ?? "1.0.0",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _showWhatsNewModal(context),
      child: Center(
        child: Text(
          "Moctar Nutrition v${packageInfo != null ? packageInfo!.version : ""} [${packageInfo != null ? packageInfo!.buildNumber : ""}]",
          style: TextStyle(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[300]
                : Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
