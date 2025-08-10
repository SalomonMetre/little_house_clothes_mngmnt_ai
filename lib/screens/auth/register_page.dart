// lib/screens/auth/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuthException
import '../../providers/auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // New controller for name
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // On success, the GoRouter listener will navigate away.
      // We don't need to call setState here.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e.code);
        _loading = false; // Stop loading on error
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'An unexpected error occurred. Please try again.';
        _loading = false; // Stop loading on error
      });
    }
  }

  String _friendlyError(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create New Account',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration(
                            labelText: 'Full Name',
                            icon: Icons.person_outline,
                          ),
                          keyboardType: TextInputType.name,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Enter your name'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: _inputDecoration(
                            labelText: 'Email',
                            icon: Icons.email_outlined,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || !v.contains('@'))
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
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter a password';
                            } else if (v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: _inputDecoration(
                            labelText: 'Confirm Password',
                            icon: Icons.lock_reset,
                          ),
                          obscureText: true,
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        if (_error != null)
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loading ? null : _register,
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
                                  'Register',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Already have an account? Login'),
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