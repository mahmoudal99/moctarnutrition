import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/onboarding_service.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/onboarding/presentation/screens/get_started_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/subscription/presentation/screens/subscription_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _initialRoute;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    final route = await OnboardingService.getInitialRoute();
    if (mounted) {
      setState(() {
        _initialRoute = route;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshRoute() async {
    final route = await OnboardingService.getInitialRoute();
    if (mounted) {
      setState(() {
        _initialRoute = route;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Debug logging
        print('AuthWrapper - AuthProvider state:');
        print('  isAuthenticated: ${authProvider.isAuthenticated}');
        print('  isLoading: ${authProvider.isLoading}');
        print('  userModel: ${authProvider.userModel?.name ?? 'null'}');
        print('  firebaseUser: ${authProvider.firebaseUser?.email ?? 'null'}');

        // Show loading screen while AuthProvider is initializing
        if (authProvider.isLoading) {
          return const SplashScreen();
        }

        // If user is not authenticated, show appropriate screen based on onboarding state
        if (!authProvider.isAuthenticated) {
          print('AuthWrapper - User not authenticated, showing route: $_initialRoute');
          // Force navigation to get-started when user logs out
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && _initialRoute != '/get-started') {
              context.go('/get-started');
            }
          });
          return const GetStartedScreen();
        }

        // User is authenticated, show home screen
        return const AuthenticatedApp();
      },
    );
  }
}

class AuthenticatedApp extends StatelessWidget {
  const AuthenticatedApp({super.key});

  @override
  Widget build(BuildContext context) {
    // This will be replaced by the main app navigation
    // For now, we'll navigate to home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go('/home');
      }
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
