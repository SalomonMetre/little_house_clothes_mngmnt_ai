// lib/models/cloth.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Cloth {
  final String id;
  final String category;
  final String name;
  final String imageUrl;
  final int quantity;
  final String uploadedBy;
  final DateTime uploadTime;
  final String? description; // Added this field

  Cloth({
    required this.id,
    required this.category,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.uploadedBy,
    required this.uploadTime,
    this.description, // Added this field
  });

  /// Factory constructor to create a Cloth object from a Firestore map.
  factory Cloth.fromMap(Map<String, dynamic> data, String documentId) {
    return Cloth(
      id: documentId,
      category: data['category'] ?? 'Uncategorized',
      name: data['name'] ?? 'No Name',
      imageUrl: data['imageUrl'] ?? '',
      quantity: data['quantity'] ?? 0,
      uploadedBy: data['uploadedBy'] ?? 'Unknown',
      uploadTime: (data['uploadTime'] as Timestamp).toDate(),
      description: data['description'], // Added this field
    );
  }

  /// Convert Cloth object to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'name': name,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'uploadedBy': uploadedBy,
      'uploadTime': Timestamp.fromDate(uploadTime),
      'description': description,
    };
  }
}