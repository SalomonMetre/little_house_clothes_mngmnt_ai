// lib/providers/request_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../models/request.dart';

// Service class for request operations
class RequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submit a new request
  Future<void> submitRequest(String userId, Map<String, int> selectedItems) async {
    try {
      // Get user email from auth or fetch from user collection
      // For now, we'll use the userId - you might want to get actual email
      final userDoc = await _db.collection('users').doc(userId).get();
      final userEmail = userDoc.data()?['email'] ?? 'unknown@email.com';

      final request = Request(
        id: _db.collection('requests').doc().id,
        userId: userId,
        userEmail: userEmail,
        items: selectedItems,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _db.collection('requests').doc(request.id).set(request.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting request: $e');
      }
      rethrow;
    }
  }

  /// Update request status (approve/decline)
  Future<void> updateRequestStatus(
    String requestId, 
    String status, {
    String? adminNote,
  }) async {
    try {
      // Get the request first
      final requestDoc = await _db.collection('requests').doc(requestId).get();
      if (!requestDoc.exists) {
        throw Exception('Request not found');
      }

      final request = Request.fromMap(requestDoc.data()!, requestDoc.id);

      // If approving, update cloth quantities
      if (status == 'approved') {
        await _updateClothQuantities(request.items);
      }

      // Update request status
      await _db.collection('requests').doc(requestId).update({
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        if (adminNote != null) 'adminNote': adminNote,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating request status: $e');
      }
      rethrow;
    }
  }

  /// Update cloth quantities when request is approved
  Future<void> _updateClothQuantities(Map<String, int> requestedItems) async {
    final batch = _db.batch();

    try {
      for (final entry in requestedItems.entries) {
        final clothId = entry.key;
        final requestedQuantity = entry.value;

        // Get current cloth data
        final clothDoc = await _db.collection('clothes').doc(clothId).get();
        if (!clothDoc.exists) {
          throw Exception('Cloth item not found: $clothId');
        }

        final clothData = clothDoc.data()!;
        final currentQuantity = clothData['quantity'] as int;

        if (currentQuantity < requestedQuantity) {
          throw Exception('Insufficient quantity for item: $clothId');
        }

        // Update quantity
        final newQuantity = currentQuantity - requestedQuantity;
        batch.update(
          _db.collection('clothes').doc(clothId),
          {'quantity': newQuantity},
        );
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating cloth quantities: $e');
      }
      rethrow;
    }
  }

  /// Get all requests
  Stream<List<Request>> getAllRequests() {
    return _db
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Request.fromMap(doc.data(), doc.id);
        } catch (e) {
          if (kDebugMode) {
            print('Error mapping request ${doc.id}: $e');
          }
          return null;
        }
      }).whereType<Request>().toList();
    });
  }

  /// Get requests by user ID
  Stream<List<Request>> getRequestsByUser(String userId) {
    return _db
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Request.fromMap(doc.data(), doc.id);
        } catch (e) {
          if (kDebugMode) {
            print('Error mapping request ${doc.id}: $e');
          }
          return null;
        }
      }).whereType<Request>().toList();
    });
  }

  /// Get requests by status
  Stream<List<Request>> getRequestsByStatus(String status) {
    return _db
        .collection('requests')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Request.fromMap(doc.data(), doc.id);
        } catch (e) {
          if (kDebugMode) {
            print('Error mapping request ${doc.id}: $e');
          }
          return null;
        }
      }).whereType<Request>().toList();
    });
  }

  /// Delete a request (optional functionality)
  Future<void> deleteRequest(String requestId) async {
    try {
      await _db.collection('requests').doc(requestId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting request: $e');
      }
      rethrow;
    }
  }
}

// Provider for the request service
final requestServiceProvider = Provider<RequestService>((ref) {
  return RequestService();
});

// Stream provider for all requests (for admin)
final requestsProvider = StreamProvider<List<Request>>((ref) {
  final requestService = ref.watch(requestServiceProvider);
  return requestService.getAllRequests();
});

// Stream provider for pending requests
final pendingRequestsProvider = StreamProvider<List<Request>>((ref) {
  final requestService = ref.watch(requestServiceProvider);
  return requestService.getRequestsByStatus('pending');
});

// Stream provider for user's requests
final userRequestsProvider = StreamProvider.family<List<Request>, String>((ref, userId) {
  final requestService = ref.watch(requestServiceProvider);
  return requestService.getRequestsByUser(userId);
});