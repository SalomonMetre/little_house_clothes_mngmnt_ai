// lib/services/request_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submits a new clothes request to Firestore.
  ///
  /// The request includes the user's ID, a map of the requested
  /// items and their quantities, the current timestamp, and
  /// a 'pending' status.
  Future<void> submitRequest(String userId, Map<String, int> items) async {
    try {
      await _db.collection('requests').add({
        'userId': userId,
        'items': items,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors
      throw Exception('Failed to submit request: ${e.message}');
    } catch (e) {
      // Handle any other unexpected errors
      throw Exception('An unknown error occurred while submitting the request.');
    }
  }

  // We can add more methods here later for admin functionalities,
  // such as fetching pending requests, approving, or declining them.
}