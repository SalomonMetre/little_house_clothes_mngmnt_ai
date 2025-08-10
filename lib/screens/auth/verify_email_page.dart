// lib/screens/auth/verify_email_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  bool _isResending = false;
  bool _isRefreshing = false;

  Future<void> _resendVerification() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null && !user.emailVerified) {
      if (!mounted) return;
      
      setState(() {
        _isResending = true;
      });

      try {
        await user.sendEmailVerification();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resend email. Try again later.')),
        );
      } finally {
        if (!mounted) return;
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _refreshAndContinue() async {
    final auth = ref.read(authServiceProvider);
    final user = auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      context.go('/login'); // Redirect to login if user is null
      return;
    }
    
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await auth.reloadUser();
      // Check for user.emailVerified again after reloading
      if (user.emailVerified) {
        final role = await auth.getUserRole();
        if (!mounted) return;
        // Navigate based on the fetched role
        if (role == 'admin') {
          context.go('/admin-home');
        } else {
          context.go('/user-home');
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email still not verified. Check your inbox.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not refresh status. Please try again.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);
    final email = auth.currentUser?.email ?? '';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE0F7FA), // Light blue
              Color(0xFFB3E5FC), // Lighter blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Verify Your Email',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Icon(Icons.email_outlined, size: 80, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'A verification email was sent to $email. Please check your inbox and spam folder to confirm your account.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isRefreshing ? null : _refreshAndContinue,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isRefreshing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                              )
                            : const Text('I have verified — continue'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isResending ? null : _resendVerification,
                        child: _isResending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Resend Verification Email'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          await auth.signOut();
                          context.go('/login');
                        },
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}