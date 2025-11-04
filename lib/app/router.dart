import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/confirm_signup_screen.dart';
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
      final requiresVerification = authState.requiresEmailVerification;
      final location = state.matchedLocation;

      // Pages allowed when NOT authenticated
      final authPages = <String>[
        '/login',
        '/register',
        '/confirm-signup',
        '/loading',
      ];
      final isOnAuthPage = authPages.any(location.startsWith);

      // 1) Only redirect to /loading when not already on an auth page.
      if (isLoading && !isOnAuthPage) {
        return '/loading';
      }

      // 2) If we are on /loading, decide where to go next after loading completes
      if (location == '/loading' && !isLoading) {
        if (isAuthenticated) {
          return '/dashboard';
        }
        // If signup requires email verification, send to confirm-signup with pending email
        if (requiresVerification) {
          final email = Uri.encodeComponent(authState.pendingEmail ?? '');
          return '/confirm-signup?email=$email';
        }
        return '/login';
      }

      // 3) Root path routing
      if (location == '/') {
        return isAuthenticated ? '/dashboard' : '/login';
      }

      // 4) If user needs email verification and not already on confirm-signup, redirect there
      if (requiresVerification && !location.startsWith('/confirm-signup')) {
        final email = Uri.encodeComponent(authState.pendingEmail ?? '');
        return '/confirm-signup?email=$email';
      }

      // 5) Guard non-auth pages for unauthenticated users
      if (!isAuthenticated && !isOnAuthPage && !requiresVerification) {
        return '/login';
      }

      // 6) Keep authenticated users away from auth pages (but allow confirm-signup)
      if (isAuthenticated &&
          isOnAuthPage &&
          !location.startsWith('/confirm-signup')) {
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
        path: '/confirm-signup',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ConfirmSignupScreen(prefilledEmail: email);
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
