import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/email_verification_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/device_detail/presentation/device_detail_screen.dart';
import '../../features/onboarding/presentation/add_device_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

class _RouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  _RouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final refreshListenable = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final location = state.matchedLocation;

      // Show loading screen while checking auth
      if (isLoading) {
        return location == '/loading' ? null : '/loading';
      }

      // Leave the loading screen once auth status is known
      if (location == '/loading') {
        return isAuthenticated ? '/dashboard' : '/login';
      }

      // Allow access to auth-related pages without authentication
      final authPages = ['/login', '/register', '/verify-email'];
      final isOnAuthPage = authPages.any(location.startsWith);

      // Handle root path gracefully
      if (location == '/' && isAuthenticated) {
        return '/dashboard';
      }
      if (location == '/' && !isAuthenticated) {
        return '/login';
      }

      // Redirect to login if not authenticated and not on auth pages
      if (!isAuthenticated && !isOnAuthPage) {
        return '/login';
      }

      // Redirect to dashboard if authenticated and on auth pages
      if (isAuthenticated && isOnAuthPage) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),
      GoRoute(
        path: '/loading',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/device/:deviceId',
        builder: (context, state) {
          final deviceId = state.pathParameters['deviceId']!;
          return DeviceDetailScreen(deviceId: deviceId);
        },
      ),
      GoRoute(
        path: '/add-device',
        builder: (context, state) => const AddDeviceScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

final _routerRefreshProvider = Provider<_RouterRefreshStream>((ref) {
  final authController = ref.watch(authControllerProvider.notifier);
  final notifier = _RouterRefreshStream(authController.stream);
  ref.onDispose(notifier.dispose);
  return notifier;
});
