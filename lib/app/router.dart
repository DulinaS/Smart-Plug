import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/confirm_signup_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/devices/presentation/device_detail_screen.dart';
import '../features/devices/presentation/user_devices_screen.dart';
import '../features/onboarding/presentation/add_device_screen.dart';
import '../../features/onboarding/presentation/device_details_page.dart';
import '../features/settings/presentation/settings_screen.dart';

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

      final authPages = <String>[
        '/login',
        '/register',
        '/confirm-signup',
        '/loading',
      ];
      final isOnAuthPage = authPages.any(location.startsWith);

      if (isLoading && !isOnAuthPage) return '/loading';
      if (location == '/loading' && !isLoading) {
        if (isAuthenticated) return '/dashboard';
        if (requiresVerification) {
          final email = Uri.encodeComponent(authState.pendingEmail ?? '');
          return '/confirm-signup?email=$email';
        }
        return '/login';
      }
      if (location == '/') return isAuthenticated ? '/dashboard' : '/login';
      if (requiresVerification && !location.startsWith('/confirm-signup')) {
        final email = Uri.encodeComponent(authState.pendingEmail ?? '');
        return '/confirm-signup?email=$email';
      }
      if (!isAuthenticated && !isOnAuthPage && !requiresVerification)
        return '/login';
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

      // Dedicated "My Devices" page (required)
      GoRoute(
        path: '/devices',
        builder: (context, state) => const UserDevicesScreen(),
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
      // NEW: Device details step to capture sticker ID, name, room, plug type
      GoRoute(
        path: '/provision/details',
        builder: (context, state) => const DeviceDetailsPage(),
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
