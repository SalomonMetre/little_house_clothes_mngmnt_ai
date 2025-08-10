// lib/providers/auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

// Service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Stream of Firebase User (null if signed out)
final authStateProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges();
});
