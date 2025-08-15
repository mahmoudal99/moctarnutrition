import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<HelpItem> _allHelpItems = [];
  List<HelpItem> _filteredHelpItems = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeHelpItems();
    _filteredHelpItems = _allHelpItems;
  }

  void _initializeHelpItems() {
    _allHelpItems = [
      HelpItem(
        question: 'How do I get started with the app?',
        answer: 'Welcome to Moctar Nutrition! To get started:\n\n'
            '1. Complete the onboarding process to set up your profile\n'
            '2. Enter your fitness goals and preferences\n'
            '3. Set your activity level and dietary restrictions\n'
            '4. Start tracking your meals and workouts\n\n'
            'The app will guide you through each step to personalize your experience.',
        category: 'Getting Started',
      ),
      HelpItem(
        question: 'How do I track my meals?',
        answer: 'To track your meals:\n\n'
            '1. Go to the Meal Prep section\n'
            '2. Use the camera to scan food items or manually search\n'
            '3. Select your portion size\n'
            '4. Add the meal to your daily log\n\n'
            'The app will automatically calculate calories, protein, carbs, and fats for you.',
        category: 'Meal Tracking',
      ),
      HelpItem(
        question: 'How do weekly check-ins work?',
        answer: 'Weekly check-ins help you stay accountable:\n\n'
            '1. Take a photo of your progress\n'
            '2. Record your current weight and measurements\n'
            '3. Note any challenges or achievements\n'
            '4. Set goals for the upcoming week\n\n'
            'Your trainer will review your check-ins and provide personalized feedback.',
        category: 'Progress Tracking',
      ),
      HelpItem(
        question: 'How do I update my nutrition preferences?',
        answer: 'To update your nutrition preferences:\n\n'
            '1. Go to Profile → Settings → Nutrition Preferences\n'
            '2. Modify your dietary restrictions, allergies, or preferences\n'
            '3. Update your calorie and macro targets\n'
            '4. Save your changes\n\n'
            'Your meal recommendations will automatically adjust based on your preferences.',
        category: 'Settings',
      ),
      HelpItem(
        question: 'How do I contact my trainer?',
        answer: 'You can contact your trainer through:\n\n'
            '1. Weekly check-in comments\n'
            '2. Direct messaging in the app (Premium feature)\n'
            '3. Email support for urgent matters\n\n'
            'Trainers typically respond within 24 hours during business days.',
        category: 'Support',
      ),
      HelpItem(
        question: 'What\'s included in the Premium subscription?',
        answer: 'Premium features include:\n\n'
            '• Direct messaging with your trainer\n'
            '• Advanced meal planning and customization\n'
            '• Detailed progress analytics and reports\n'
            '• Priority customer support\n'
            '• Exclusive workout plans\n'
            '• No ads\n\n'
            'You can upgrade anytime from your Profile screen.',
        category: 'Subscription',
      ),
      HelpItem(
        question: 'How do I cancel my subscription?',
        answer: 'To cancel your subscription:\n\n'
            '1. Go to Profile → Settings → Account Settings\n'
            '2. Select "Manage Subscription"\n'
            '3. Follow the prompts to cancel\n\n'
            'You\'ll continue to have access until the end of your current billing period.',
        category: 'Subscription',
      ),
      HelpItem(
        question: 'How accurate is the nutrition information?',
        answer: 'Our nutrition database includes:\n\n'
            '• Verified USDA nutrition data\n'
            '• Restaurant and brand information\n'
            '• User-contributed data (verified)\n\n'
            'While we strive for accuracy, nutrition information can vary. '
            'For precise tracking, we recommend using a food scale and '
            'verifying information with product labels.',
        category: 'Nutrition',
      ),
      HelpItem(
        question: 'How do I reset my password?',
        answer: 'To reset your password:\n\n'
            '1. Go to the login screen\n'
            '2. Tap "Forgot Password?"\n'
            '3. Enter your email address\n'
            '4. Check your email for reset instructions\n'
            '5. Follow the link to create a new password\n\n'
            'If you don\'t receive the email, check your spam folder.',
        category: 'Account',
      ),
      HelpItem(
        question: 'How do I delete my account?',
        answer: 'To delete your account:\n\n'
            '1. Go to Profile → Privacy → Delete Account\n'
            '2. Confirm your decision\n'
            '3. Enter your password to verify\n\n'
            '⚠️ Warning: This action cannot be undone. All your data will be permanently deleted.',
        category: 'Account',
      ),
      HelpItem(
        question: 'How do I report a bug or issue?',
        answer: 'To report a bug or issue:\n\n'
            '1. Go to Profile → Support → Report a Bug\n'
            '2. Describe the problem in detail\n'
            '3. Include steps to reproduce the issue\n'
            '4. Add screenshots if helpful\n'
            '5. Submit the report\n\n'
            'Our team will investigate and get back to you as soon as possible.',
        category: 'Support',
      ),
      HelpItem(
        question: 'How do I sync my data across devices?',
        answer: 'Your data automatically syncs when you:\n\n'
            '• Sign in with the same account on multiple devices\n'
            '• Have an active internet connection\n'
            '• Use the latest version of the app\n\n'
            'Changes are synced in real-time, so your progress is always up to date.',
        category: 'Technical',
      ),
      HelpItem(
        question: 'What should I do if the app crashes?',
        answer: 'If the app crashes:\n\n'
            '1. Close the app completely\n'
            '2. Restart your device\n'
            '3. Update to the latest version of the app\n'
            '4. Clear the app cache if needed\n\n'
            'If the problem persists, please report it through Profile → Support → Report a Bug.',
        category: 'Technical',
      ),
    ];
  }

  void _filterHelpItems(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (query.isEmpty) {
        _filteredHelpItems = _allHelpItems;
      } else {
        _filteredHelpItems = _allHelpItems.where((item) {
          return item.question.toLowerCase().contains(_searchQuery) ||
              item.answer.toLowerCase().contains(_searchQuery) ||
              item.category.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterHelpItems,
              decoration: InputDecoration(
                hintText: 'Search help topics...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterHelpItems('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Help Items List
          Expanded(
            child: _filteredHelpItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredHelpItems.length,
                    itemBuilder: (context, index) {
                      return _HelpItemTile(
                        helpItem: _filteredHelpItems[index],
                      );
                    },
                  ),
          ),
          const SizedBox(
            height: 128,
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No help topics found',
            style: AppTextStyles.heading5.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _HelpItemTile extends StatefulWidget {
  final HelpItem helpItem;

  const _HelpItemTile({required this.helpItem});

  @override
  State<_HelpItemTile> createState() => _HelpItemTileState();
}

class _HelpItemTileState extends State<_HelpItemTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
          if (expanded) {
            HapticFeedback.lightImpact();
          }
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(widget.helpItem.category),
            color: AppConstants.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          widget.helpItem.question,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            widget.helpItem.category,
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
        ),
        trailing: Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          color: AppConstants.textSecondary,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.helpItem.answer,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.5,
                color: AppConstants.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'getting started':
        return Icons.play_circle_outline;
      case 'meal tracking':
        return Icons.restaurant;
      case 'progress tracking':
        return Icons.trending_up;
      case 'settings':
        return Icons.settings;
      case 'support':
        return Icons.support_agent;
      case 'subscription':
        return Icons.star;
      case 'nutrition':
        return Icons.food_bank_outlined;
      case 'account':
        return Icons.person;
      case 'technical':
        return Icons.build;
      default:
        return Icons.help_outline;
    }
  }
}

class HelpItem {
  final String question;
  final String answer;
  final String category;

  HelpItem({
    required this.question,
    required this.answer,
    required this.category,
  });
} 