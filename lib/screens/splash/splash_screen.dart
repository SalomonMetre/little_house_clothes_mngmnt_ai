// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final auth = ref.read(authServiceProvider);
    final user = auth.currentUser;
    if (user == null) {
      // Not logged in - go to login
      if (!mounted) return;
      context.go('/login');
      return;
    }
    // ensure latest info
    await auth.reloadUser();
    if (!auth.currentUser!.emailVerified) {
      if (!mounted) return;
      context.go('/verify-email');
      return;
    }

    final doc = await auth.getUserDoc(user.uid);
    final data = doc.data();
    final role = data != null && data['role'] != null ? data['role'] as String : 'user';
    if (!mounted) return;
    if (role == 'admin') {
      context.go('/admin-home');
    } else {
      context.go('/user-home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}