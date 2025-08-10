// lib/routes/app_router.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';

import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/auth/verify_email_page.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/user/user_home.dart';
import '../screens/admin/admin_home.dart';

// Helper to trigger go_router refreshes when the auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.read(authServiceProvider);
  final authState = ref.watch(authStateProvider); // To trigger rebuilds on auth changes

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges()),
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/verify-email', builder: (_, __) => const VerifyEmailPage()),
      GoRoute(path: '/user-home', builder: (_, __) => const UserHome()),
      GoRoute(path: '/admin-home', builder: (_, __) => const AdminHome()),
    ],
    redirect: (context, state) async {
      final user = authService.currentUser;
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isVerifying = state.matchedLocation == '/verify-email';

      // 1. Not logged in: Redirect to login page.
      if (user == null) {
        return loggingIn ? null : '/login';
      }

      // 2. Logged in but unverified: Redirect to verification page.
      if (!user.emailVerified) {
        // Use a non-blocking check with an explicit return path.
        return isVerifying ? null : '/verify-email';
      }

      // 3. Logged in and verified:
      // If on a login/register/verify page, redirect to the correct home page.
      if (loggingIn || isVerifying) {
        try {
          final userDoc = await authService.getUserDoc(user.uid);
          final role = userDoc.data()?['role'] ?? 'user';
          return role == 'admin' ? '/admin-home' : '/user-home';
        } catch (e) {
          // Fallback to the user home page if Firestore read fails.
          print('Error fetching user role: $e'); 
          return '/user-home';
        }
      }

      // 4. Otherwise, no redirection is needed. Stay on the current page.
      return null;
    },
  );
});