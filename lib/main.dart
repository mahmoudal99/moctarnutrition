import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart'   ;
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/onboarding/presentation/screens/get_started_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/subscription/presentation/screens/subscription_screen.dart';
import 'features/meal_prep/presentation/screens/meal_prep_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
// import 'features/trainers/presentation/screens/trainers_screen.dart';
// import 'features/workouts/presentation/screens/workouts_screen.dart';
// import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'shared/widgets/main_navigation.dart';
import 'shared/providers/user_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider()..loadUser(),
      child: const ChampionsGymApp(),
    ),
  );
}

class ChampionsGymApp extends StatelessWidget {
  const ChampionsGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Muktar Nutrition',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    // Splash Screen Route
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // Get Started Route
    GoRoute(
      path: '/get-started',
      builder: (context, state) => const GetStartedScreen(),
    ),

    // Auth Route
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),

    // Onboarding Route
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Subscription Route
    GoRoute(
      path: '/subscription',
      builder: (context, state) => const SubscriptionScreen(),
    ),

    // Main App Routes
    ShellRoute(
      builder: (context, state, child) => MainNavigation(child: child),
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
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);





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

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workouts')),
      body: const Center(
        child: Text('Workouts Screen - Coming Soon'),
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
