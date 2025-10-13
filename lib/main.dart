import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'shared/services/logging_service.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/presentation/screens/account_settings_screen.dart';
import 'features/profile/presentation/screens/bug_report_screen.dart';
import 'features/profile/presentation/screens/feedback_screen.dart';
import 'features/profile/presentation/screens/help_center_screen.dart';

import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/password_reset_screen.dart';
import 'features/onboarding/presentation/screens/get_started_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/onboarding/presentation/screens/protein_calculation_screen.dart';
import 'features/subscription/presentation/screens/subscription_screen.dart';
import 'features/meal_prep/presentation/screens/meal_prep_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/checkin/presentation/screens/checkin_screen.dart';
import 'features/checkin/presentation/screens/checkin_form_screen.dart';
import 'features/checkin/presentation/screens/checkin_details_screen.dart';
import 'features/checkin/presentation/screens/checkin_history_screen.dart';
import 'features/progress/presentation/screens/progress_screen.dart';
import 'features/admin/presentation/screens/admin_user_list_screen.dart';
import 'features/admin/presentation/screens/admin_user_detail_screen.dart';
import 'features/admin/presentation/screens/admin_home_screen.dart';
import 'features/workouts/presentation/screens/workouts_screen.dart';
import 'features/workouts/presentation/screens/workout_details_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/profile/presentation/screens/workout_preferences_screen.dart';
import 'features/profile/presentation/screens/nutrition_preferences_screen.dart';
import 'features/profile/presentation/screens/privacy_policy_screen.dart';
import 'features/profile/presentation/screens/workout_notification_settings_screen.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'shared/models/workout_plan_model.dart';
import 'shared/services/background_upload_service.dart';
import 'shared/services/notification_service.dart';
import 'shared/providers/profile_photo_provider.dart';
import 'shared/widgets/floating_main_navigation.dart';
import 'shared/providers/user_provider.dart';
import 'shared/providers/meal_plan_provider.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/checkin_provider.dart';
import 'shared/providers/workout_provider.dart';
import 'shared/services/config_service.dart';
import 'shared/services/stripe_subscription_service.dart';
import 'shared/models/checkin_model.dart';

late final GoRouter _router;
// Remove the old logger instance
// final _logger = Logger();

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    routes: [
      // Main route that handles authentication flow
      GoRoute(
        path: '/',
        builder: (context, state) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);

          // Show loading indicator while determining auth state
          if (authProvider.isLoading) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                ),
              ),
            );
          }

          // If not authenticated, show get started screen
          if (!authProvider.isAuthenticated) {
            return const GetStartedScreen();
          }

          // If authenticated but user model is still loading, show loading
          if (authProvider.userModel == null) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                ),
              ),
            );
          }

          if (authProvider.userModel?.role == UserRole.admin) {
            // The redirect will handle navigation, just show a placeholder
            return const SizedBox.shrink();
          }

          // Check subscription status
          final user = authProvider.userModel!;
          final hasSubscription = user.subscriptionStatus != SubscriptionStatus.free;
          
          if (!hasSubscription) {
            return const SubscriptionScreen();
          }

          return const FloatingMainNavigation(child: HomeScreen());
        },
      ),

      // Get Started Route
      GoRoute(
        path: '/get-started',
        builder: (context, state) => const GetStartedScreen(),
      ),

      // Auth Route (for sign in - existing users)
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),

      // Auth Route (for sign up - new users after onboarding)
      GoRoute(
        path: '/auth-signup',
        builder: (context, state) => const AuthScreen(isSignUp: true),
      ),

      // Password Reset Route
      GoRoute(
        path: '/password-reset',
        builder: (context, state) => const PasswordResetScreen(),
      ),

      // Onboarding Route
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Protein Calculation Route
      GoRoute(
        path: '/protein-calculation',
        builder: (context, state) => const ProteinCalculationScreen(),
      ),

      // Subscription Route
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),

      // Main App Routes (protected)
      ShellRoute(
        builder: (context, state, child) =>
            FloatingMainNavigation(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/workouts',
            builder: (context, state) => const WorkoutsScreen(),
          ),
          GoRoute(
            path: '/meal-prep',
            builder: (context, state) => const MealPrepScreen(),
          ),
          GoRoute(
            path: '/trainers',
            builder: (context, state) => const TrainersScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin-users',
            builder: (context, state) => const AdminUserListScreen(),
          ),
          GoRoute(
            path: '/admin-home',
            builder: (context, state) => const AdminHomeScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Admin User Detail Route (outside shell route - no bottom navigation)
      GoRoute(
        path: '/admin/user-detail',
        builder: (context, state) {
          final user = state.extra as UserModel;
          return AdminUserDetailScreen(user: user);
        },
      ),

      // Workout Details Route (outside shell route - no bottom navigation)
      GoRoute(
        path: '/workout-details',
        builder: (context, state) {
          final dailyWorkout = state.extra as DailyWorkout;
          return WorkoutDetailsScreen(dailyWorkout: dailyWorkout);
        },
      ),

      // Checkin Routes (outside shell route - no bottom navigation)
      GoRoute(
        path: '/checkin',
        builder: (context, state) => const CheckinScreen(),
      ),
      GoRoute(
        path: '/checkin/form',
        builder: (context, state) => const CheckinFormScreen(),
      ),
      GoRoute(
        path: '/checkin/details',
        builder: (context, state) {
          final checkin = state.extra as CheckinModel;
          return CheckinDetailsScreen(checkin: checkin);
        },
      ),
      GoRoute(
        path: '/checkin/history',
        builder: (context, state) => const CheckinHistoryScreen(),
      ),

      // Progress Route (outside shell route - no bottom navigation)
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),

      // Profile Detail Routes (outside shell route - no bottom navigation)
      GoRoute(
        path: '/workout-preferences',
        builder: (context, state) => const WorkoutPreferencesScreen(),
      ),
      GoRoute(
        path: '/workout-notifications',
        builder: (context, state) => const WorkoutNotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/nutrition-preferences',
        builder: (context, state) => const NutritionPreferencesScreen(),
      ),
      GoRoute(
        path: '/account-settings',
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/help-center',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/bug-report',
        builder: (context, state) => const BugReportScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
    ],
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isLoading) return null;
      final isAdmin = authProvider.userModel?.role == UserRole.admin;
      final isAuthenticated = authProvider.isAuthenticated;
      const adminRoutes = [
        '/admin-home',
        '/admin-users',
        '/admin/user-detail',
        '/profile',
        '/trainers'
      ];
      final currentRoute = state.uri.toString();

      // If admin and authenticated, redirect to /admin-home only if not on an admin route
      if (isAuthenticated && isAdmin && !adminRoutes.contains(currentRoute)) {
        LoggingService.instance.d('Router redirect - Redirecting admin to /admin-home');
        return '/admin-home';
      }
      return null;
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Log app startup
  LoggingService.logAppStart();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    LoggingService.instance.i('Firebase initialized successfully');
  } catch (e) {
    LoggingService.logError('Firebase initialization error', error: e, context: 'Firebase');
    // Continue without Firebase for development
  }

  // Load environment variables
  try {
    await dotenv.load();
  } catch (e) {
    LoggingService.instance.w('Warning: Could not load .env file: $e');
    LoggingService.instance.w(
        'Please ensure you have copied .env.example to .env and configured your API key');
  }

  // Validate environment configuration
  try {
    ConfigService.validateEnvironment();
    LoggingService.instance.i('Environment configuration validated successfully');
    LoggingService.instance.i('Config summary: ${ConfigService.getConfigSummary()}');
  } catch (e) {
    LoggingService.logError('Environment configuration error', error: e, context: 'Config');
    LoggingService.instance.e('Please check your .env file and ensure OPENAI_API_KEY is set');
  }

  // Initialize background upload service
  try {
    await BackgroundUploadService.initialize();
    LoggingService.instance.i('Background upload service initialized successfully');
  } catch (e) {
    LoggingService.logError('Could not initialize background upload service', error: e, context: 'BackgroundUpload');
    // Continue without background upload service
  }

  // Initialize notification service
  try {
    await NotificationService.initialize();
    LoggingService.instance.i('Notification service initialized successfully');
  } catch (e) {
    LoggingService.logError('Could not initialize notification service', error: e, context: 'Notifications');
    // Continue without notification service
  }

  // Initialize Stripe service
  try {
    if (ConfigService.isStripeEnabled) {
      await StripeSubscriptionService.initialize(
        publishableKey: ConfigService.stripePublishableKey,
        backendUrl: ConfigService.stripeBackendUrl,
      );
      LoggingService.instance.i('Stripe service initialized successfully');
    } else {
      LoggingService.instance.w('Stripe service disabled - configuration not found');
    }
  } catch (e) {
    LoggingService.logError('Could not initialize Stripe service', error: e, context: 'Stripe');
    // Continue without Stripe service
  }

  final authProvider = AuthProvider();
  final profilePhotoProvider = ProfilePhotoProvider();

  // Connect auth provider with profile photo provider
  authProvider.setProfilePhotoProvider(profilePhotoProvider);

  // Initialize auth provider
  await authProvider.initialize();

  _router = createRouter(authProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
        ChangeNotifierProvider(create: (_) => CheckinProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => profilePhotoProvider),
      ],
      child: const ChampionsGymApp(),
    ),
  );
}

class ChampionsGymApp extends StatelessWidget {
  const ChampionsGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Moctar Nutrition',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}

class TrainersScreen extends StatelessWidget {
  const TrainersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trainers')),
      body: const Center(
        child: Text('Trainers Screen - Coming Soon'),
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: const Center(
        child: Text('Admin Dashboard Screen - Coming Soon'),
      ),
    );
  }
}
