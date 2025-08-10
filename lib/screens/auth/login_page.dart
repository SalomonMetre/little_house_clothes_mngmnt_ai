// lib/screens/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Navigation is now handled by the GoRouter listener.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e.code);
        _loading = false;
      });
      // Use a SnackBar for specific errors like unverified email
      if (e.code == 'email-not-verified') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check your email to verify your account.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'An unexpected error occurred. Please try again.';
        _loading = false;
      });
    }
  }

  String _friendlyError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'email-not-verified':
        return ''; // We'll handle this error with a SnackBar
      default:
        return 'Login failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE0F7FA),
              Color(0xFFB3E5FC),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          decoration: _inputDecoration(
                            labelText: 'Email',
                            icon: Icons.email_outlined,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              (v == null || !v.contains('@'))
                                  ? 'Enter a valid email'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: _inputDecoration(
                            labelText: 'Password',
                            icon: Icons.lock_outline,
                          ),
                          obscureText: true,
                          validator: (v) =>
                              (v == null || v.isEmpty)
                                  ? 'Enter your password'
                                  : null,
                        ),
                        const SizedBox(height: 24),
                        if (_error != null && _error!.isNotEmpty)
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3, color: Colors.white),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('Create new account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.blue.shade50,
    );
  }
}