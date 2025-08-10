// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Registers a new user with email and password,
  /// updates their display name, creates a Firestore document,
  /// and sends a verification email.
  Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);

        await _db.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await user.sendEmailVerification();
        return user;
      }
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('An unknown error occurred during registration.');
    }
    return null;
  }

  /// Signs in a user with email and password.
  /// The email verification check is now handled by the UI and GoRouter.
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('An unknown error occurred during sign-in.');
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Reloads the current user's profile information.
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Fetches a user's document from Firestore by their UID.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  /// Fetches the current user's role from their Firestore document.
  Future<String?> getUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final userDoc = await _db.collection('users').doc(uid).get();
      return userDoc.data()?['role'] as String?;
    }
    return null;
  }
}