import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/profile_photo_provider.dart';
import '../../../../shared/utils/avatar_utils.dart';

class WorkoutGenerationLoadingState extends StatefulWidget {
  const WorkoutGenerationLoadingState({super.key});

  @override
  State<WorkoutGenerationLoadingState> createState() =>
      _WorkoutGenerationLoadingStateState();
}

class _WorkoutGenerationLoadingStateState
    extends State<WorkoutGenerationLoadingState> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentStep = 0;

  final List<String> _generationSteps = [
    'Analyzing your fitness profile...',
    'Designing personalized workouts...',
    'Optimizing exercise selection...',
    'Creating your perfect plan...',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _startStepAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startStepAnimation() {
    _animationController.forward().then((_) {
      if (mounted) {
        setState(() {
          _currentStep = (_currentStep + 1) % _generationSteps.length;
        });
        _animationController.reset();
        _startStepAnimation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppConstants.surfaceColor,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              child: _buildUserProfileIcon(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppConstants.surfaceColor,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.spacingM,
                    AppConstants.spacingXL,
                    AppConstants.spacingM,
                    AppConstants.spacingM,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Hi ${_getUserName(context)}!',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        'Creating your personalized workout plan...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // const SizedBox(height: AppConstants.spacingXL),
                  // _buildLoadingSpinner(),
                  const SizedBox(height: AppConstants.spacingXL),
                  _buildGenerationTitle(),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildCurrentStep(),
                  const SizedBox(height: AppConstants.spacingXL),
                  _buildGenerationProgress(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSpinner() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.shadowM,
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppConstants.primaryColor,
            strokeWidth: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationTitle() {
    return Text(
      'Creating Your Perfect Workout Plan',
      style: AppTextStyles.heading4.copyWith(
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCurrentStep() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Text(
          _generationSteps[_currentStep],
          key: ValueKey(_currentStep),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppConstants.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildGenerationProgress() {
    return Column(
      children: [
        Text(
          'This may take a few moments...',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppConstants.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            color: AppConstants.textTertiary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfileIcon(BuildContext context) {
    return Consumer<ProfilePhotoProvider>(
      builder: (context, profilePhotoProvider, child) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.userModel;

        if (user == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/profile');
          },
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppConstants.surfaceColor,
            child: AvatarUtils.buildAvatar(
              photoUrl: user.photoUrl,
              name: user.name,
              email: user.email,
              radius: 20,
            ),
          ),
        );
      },
    );
  }

  String _getUserName(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    return user?.name?.split(' ').first ?? 'there';
  }
}
