// lib/providers/clothes_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../models/cloth.dart';

// Stream provider for reading clothes
final clothesProvider = StreamProvider<List<Cloth>>((ref) {
  final db = FirebaseFirestore.instance;
  return db.collection('clothes').snapshots().map((snapshot) {
    if (snapshot.docs.isEmpty) {
      return []; // Handle empty collection gracefully
    }
    return snapshot.docs
        .map((doc) {
          try {
            return Cloth.fromMap(doc.data(), doc.id);
          } catch (e) {
            if (kDebugMode) {
              print('Error mapping document ${doc.id}: $e');
            }
            return null; // Return null for invalid documents
          }
        })
        .whereType<Cloth>()
        .toList(); // Filter out any nulls
  });
});

// Service class for clothes operations
class ClothesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Add a new cloth item to Firestore
  Future<void> addCloth(Cloth cloth) async {
    try {
      await _db.collection('clothes').doc(cloth.id).set(cloth.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error adding cloth: $e');
      }
      rethrow;
    }
  }

  /// Update a cloth item in Firestore
  Future<void> updateCloth(Cloth cloth) async {
    try {
      await _db.collection('clothes').doc(cloth.id).update(cloth.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error updating cloth: $e');
      }
      rethrow;
    }
  }

  /// Update cloth quantity (used when requests are approved)
  Future<void> updateClothQuantity(String clothId, int newQuantity) async {
    try {
      await _db.collection('clothes').doc(clothId).update({
        'quantity': newQuantity,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating cloth quantity: $e');
      }
      rethrow;
    }
  }

  /// Update multiple cloth quantities at once, used for approving a user request
  Future<void> updateClothQuantities(Map<String, int> requestedItems) async {
    final batch = _db.batch();
    for (var entry in requestedItems.entries) {
      final clothId = entry.key;
      final requestedQuantity = entry.value;
      final clothRef = _db.collection('clothes').doc(clothId);
      batch.update(clothRef, {
        'quantity': FieldValue.increment(-requestedQuantity),
      });
    }
    try {
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating multiple cloth quantities: $e');
      }
      rethrow;
    }
  }

  /// Delete a cloth item
  Future<void> deleteCloth(String clothId) async {
    try {
      await _db.collection('clothes').doc(clothId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting cloth: $e');
      }
      rethrow;
    }
  }

  /// Get clothes by category for analytics
  Stream<List<Cloth>> getClothesByCategory(String category) {
    if (category == 'all') {
      return _db.collection('clothes').snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return Cloth.fromMap(doc.data(), doc.id);
              } catch (e) {
                if (kDebugMode) {
                  print('Error mapping document ${doc.id}: $e');
                }
                return null;
              }
            })
            .whereType<Cloth>()
            .toList();
      });
    } else {
      return _db
          .collection('clothes')
          .where('category', isEqualTo: category)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    return Cloth.fromMap(doc.data(), doc.id);
                  } catch (e) {
                    if (kDebugMode) {
                      print('Error mapping document ${doc.id}: $e');
                    }
                    return null;
                  }
                })
                .whereType<Cloth>()
                .toList();
          });
    }
  }

  /// Get clothes uploaded within a time range for analytics
  Stream<List<Cloth>> getClothesInTimeRange(
    DateTime startTime,
    DateTime endTime, {
    String? category,
  }) {
    Query<Map<String, dynamic>> query = _db.collection('clothes');
    // Add time range filter
    query = query
        .where(
          'uploadTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startTime),
        )
        .where('uploadTime', isLessThanOrEqualTo: Timestamp.fromDate(endTime));
    // Add category filter if specified
    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return Cloth.fromMap(doc.data(), doc.id);
            } catch (e) {
              if (kDebugMode) {
                print('Error mapping document ${doc.id}: $e');
              }
              return null;
            }
          })
          .whereType<Cloth>()
          .toList();
    });
  }

  Future<Map<String, Cloth>> getClothesByIds(List<String> ids) async {
    Map<String, Cloth> clothesMap = {};

    for (String id in ids) {
      try {
        DocumentSnapshot doc = await _db.collection('clothes').doc(id).get();
        if (doc.exists) {
          clothesMap[id] = Cloth.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching cloth with ID $id: $e');
        }
      }
    }

    return clothesMap;
  }
}

// Provider for the clothes service
final clothesServiceProvider = Provider<ClothesService>((ref) {
  return ClothesService();
});
