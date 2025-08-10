// lib/models/request.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  final String id;
  final String userId;
  final String userEmail;
  final Map<String, int> items; // clothId -> quantity
  final String status; // 'pending', 'approved', 'declined'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminNote;

  Request({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.items,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.adminNote,
  });

  /// Factory constructor to create a Request object from a Firestore map.
  factory Request.fromMap(Map<String, dynamic> data, String documentId) {
    return Request(
      id: documentId,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      items: Map<String, int>.from(data['items'] ?? {}),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      adminNote: data['adminNote'],
    );
  }

  /// Convert Request object to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'items': items,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'adminNote': adminNote,
    };
  }

  /// Create a copy of the request with updated fields
  Request copyWith({
    String? id,
    String? userId,
    String? userEmail,
    Map<String, int>? items,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminNote,
  }) {
    return Request(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminNote: adminNote ?? this.adminNote,
    );
  }
}