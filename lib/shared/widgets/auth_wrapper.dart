import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../providers/auth_provider.dart';
import '../services/onboarding_service.dart';
import '../../features/onboarding/presentation/screens/get_started_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  static final _logger = Logger();
  String? _initialRoute;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    _logger.i('AuthWrapper - Determining initial route');
    try {
      final route = await OnboardingService.getInitialRoute();
      _logger.i('AuthWrapper - Got initial route: $route');
      if (mounted) {
        setState(() {
          _initialRoute = route;
          _isLoading = false;
        });
        _logger.i('AuthWrapper - State updated, isLoading: $_isLoading');
      }
    } catch (e) {
      _logger.e('AuthWrapper - Error determining initial route: $e');
      if (mounted) {
        setState(() {
          _initialRoute = '/get-started';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Debug logging
        _logger.i('AuthWrapper - Building with state:');
        _logger.i('  isAuthenticated: ${authProvider.isAuthenticated}');
        _logger.i('  isLoading: ${authProvider.isLoading}');
        _logger.i('  userModel: ${authProvider.userModel?.name ?? 'null'}');
        _logger.i('  firebaseUser: ${authProvider.firebaseUser?.email ?? 'null'}');
        _logger.i('  initialRoute: $_initialRoute');

        // Show loading screen while initializing
        if (authProvider.isLoading || _isLoading) {
          _logger.i('AuthWrapper - Loading state: authProvider.isLoading=${authProvider.isLoading}, _isLoading=$_isLoading');
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
              ),
            ),
          );
        }

        // If user is not authenticated, show get started screen
        if (!authProvider.isAuthenticated) {
          _logger.i('AuthWrapper - User not authenticated, showing GetStartedScreen');
          return const GetStartedScreen();
        }

        // User is authenticated, show home screen
        _logger.i('AuthWrapper - User authenticated, showing home screen');
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
