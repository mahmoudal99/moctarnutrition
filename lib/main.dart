import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
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
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'shared/services/background_upload_service.dart';
import 'shared/providers/profile_photo_provider.dart';

// import 'features/trainers/presentation/screens/trainers_screen.dart';
// import 'features/workouts/presentation/screens/workouts_screen.dart';
// import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'shared/widgets/main_navigation.dart';
import 'shared/widgets/floating_main_navigation.dart';
import 'shared/providers/user_provider.dart';
import 'shared/providers/meal_plan_provider.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/checkin_provider.dart';
import 'shared/providers/workout_provider.dart';
import 'shared/services/config_service.dart';
import 'shared/models/checkin_model.dart';

late final GoRouter _router;
final _logger = Logger();

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
          if (authProvider.isLoading) {
            return const SplashScreen();
          }
          if (!authProvider.isAuthenticated) {
            return const GetStartedScreen();
          }
          if (authProvider.userModel?.role == UserRole.admin) {
            // The redirect will handle navigation, just show a placeholder
            return const SizedBox.shrink();
          }
          return const FloatingMainNavigation(child: WorkoutsScreen());
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
            builder: (context, state) => const WorkoutsScreen(),
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
          GoRoute(
            path: '/progress',
            builder: (context, state) => const ProgressScreen(),
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
    ],
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Debug logging
      _logger.d('Router redirect - AuthProvider state:');
      _logger.d('  isLoading: ${authProvider.isLoading}');
      _logger.d('  isAuthenticated: ${authProvider.isAuthenticated}');
      _logger.d('  userModel: ${authProvider.userModel?.name ?? 'null'}');
      _logger.d('  user role: ${authProvider.userModel?.role ?? 'null'}');
      _logger.d('  current route: ${state.uri.toString()}');

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
        _logger.d('Router redirect - Redirecting admin to /admin-home');
        return '/admin-home';
      }
      
      _logger.d('Router redirect - No redirect needed');
      // Otherwise, no redirect
      return null;
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    _logger.i('Firebase initialized successfully');
  } catch (e) {
    _logger.e('Firebase initialization error: $e');
    // Continue without Firebase for development
  }

  // Load environment variables
  try {
    await dotenv.load();
    _logger.i('Environment file loaded successfully');
  } catch (e) {
    _logger.w('Warning: Could not load .env file: $e');
    _logger.w(
        'Please ensure you have copied .env.example to .env and configured your API key');
    // Continue with default configuration
  }

  // Validate environment configuration
  try {
    ConfigService.validateEnvironment();
    _logger.i('Environment configuration validated successfully');
    _logger.i('Config summary: ${ConfigService.getConfigSummary()}');
  } catch (e) {
    _logger.e('Environment configuration error: $e');
    _logger.e('Please check your .env file and ensure OPENAI_API_KEY is set');
    // In production, you might want to show a user-friendly error
    // or fall back to a safe default configuration
  }

  // Initialize background upload service
  try {
    await BackgroundUploadService.initialize();
    _logger.i('Background upload service initialized successfully');
  } catch (e) {
    _logger.w('Warning: Could not initialize background upload service: $e');
    // Continue without background upload service
  }

  final authProvider = AuthProvider();
  final profilePhotoProvider = ProfilePhotoProvider();
  
  // Connect auth provider with profile photo provider
  authProvider.setProfilePhotoProvider(profilePhotoProvider);
  
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
