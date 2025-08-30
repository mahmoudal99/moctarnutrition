import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/email_templates.dart';
import '../../../../shared/providers/auth_provider.dart';

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stepsController = TextEditingController();
  final _expectedBehaviorController = TextEditingController();
  final _actualBehaviorController = TextEditingController();
  bool _isLoading = false;

  String _selectedCategory = 'General';
  String _selectedPriority = 'Medium';

  final List<String> _categories = [
    'General',
    'Authentication',
    'Meal Planning',
    'Check-ins',
    'Progress Tracking',
    'Profile',
    'Navigation',
    'Performance',
    'UI/UX',
    'Other'
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stepsController.dispose();
    _expectedBehaviorController.dispose();
    _actualBehaviorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Report a Bug'),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildPriorityDropdown(),
              const SizedBox(height: 16),
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildStepsField(),
              const SizedBox(height: 16),
              _buildExpectedBehaviorField(),
              const SizedBox(height: 16),
              _buildActualBehaviorField(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report,
                    color: AppConstants.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Help Us Improve',
                  style: AppTextStyles.heading5.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Please provide as much detail as possible to help us identify and fix the issue quickly.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category *',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.primaryColor),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue!;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriorityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority *',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPriority,
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.primaryColor),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _priorities.map((String priority) {
            return DropdownMenuItem<String>(
              value: priority,
              child: Text(priority),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedPriority = newValue!;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a priority';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bug Title *',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Brief description of the issue',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.primaryColor),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description *',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Detailed description of the bug',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.primaryColor),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStepsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Steps to Reproduce',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _stepsController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '1. Go to...\n2. Click on...\n3. See error...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.primaryColor),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildExpectedBehaviorField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expected Behavior',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _expectedBehaviorController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'What should happen?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.primaryColor),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildActualBehaviorField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actual Behavior',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _actualBehaviorController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'What actually happens?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppConstants.primaryColor),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitBugReport,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Submit Bug Report',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  Future<void> _submitBugReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = context.read<AuthProvider>().userModel;
      final userInfo = user != null
          ? 'User: ${user.name} (${user.email})\nUser ID: ${user.id}'
          : 'User: Not logged in';

      final deviceInfo = await _getDeviceInfo();

      final emailBody = EmailTemplates.buildBugReportEmailBody(
        userInfo: userInfo,
        deviceInfo: deviceInfo,
        category: _selectedCategory,
        priority: _selectedPriority,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        stepsToReproduce: _stepsController.text.trim(),
        expectedBehavior: _expectedBehaviorController.text.trim(),
        actualBehavior: _actualBehaviorController.text.trim(),
      );
      final emailSubject =
          EmailTemplates.buildBugReportSubject(_titleController.text.trim());

      final emailUrl = Uri.parse(
          'mailto:${EmailTemplates.bugReportEmail}?subject=${Uri.encodeComponent(emailSubject)}&body=${Uri.encodeComponent(emailBody)}');

      if (await canLaunchUrl(emailUrl)) {
        await launchUrl(emailUrl);

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      if (mounted) {
        if (kDebugMode) {
          print("Exception: $e");
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _getDeviceInfo() async {
    try {
      // Basic device info - you can expand this with more details
      return '''
Platform: ${Theme.of(context).platform.name}
App Version: 1.0.0
''';
    } catch (e) {
      return 'Device info unavailable: $e';
    }
  }
}
