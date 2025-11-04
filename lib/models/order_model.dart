import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final double total;
   String status;
  final Map<String, dynamic>? shipping; // name, phone, address ইত্যাদি
  final String? branch;
  final String? userEmail;
  final Timestamp? createdAt; // Firestore Timestamp, nullable

  OrderModel({
    required this.id,
    required this.userId,
    required this.total,
    required this.status,
    this.shipping,
    this.branch,
    this.userEmail,
    this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    // Guard against dynamic maps coming from Firestore
    final shipping = (map['shipping'] is Map) ? Map<String, dynamic>.from(map['shipping']) : null;
    final branch = map['branch']?.toString();
    final userEmail = map['userEmail']?.toString();

    // createdAt could be Timestamp or DateTime or int (ms) — handle gracefully
    Timestamp? ts;
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      ts = rawCreated;
    } else if (rawCreated is Map && rawCreated.containsKey('_seconds')) {
      // sometimes Firestore serializes timestamp as map with _seconds/_nanoseconds
      final seconds = rawCreated['_seconds'] as int? ?? 0;
      final nanoseconds = rawCreated['_nanoseconds'] as int? ?? 0;
      ts = Timestamp(seconds, nanoseconds);
    } else if (rawCreated is int) {
      // milliseconds since epoch
      ts = Timestamp.fromMillisecondsSinceEpoch(rawCreated);
    } else if (rawCreated is DateTime) {
      ts = Timestamp.fromDate(rawCreated);
    } else {
      ts = null;
    }

    return OrderModel(
      id: docId,
      userId: map['userId']?.toString() ?? '',
      total: (map['total'] ?? 0).toDouble(),
      status: map['status']?.toString() ?? 'Pending',
      shipping: shipping,
      branch: branch,
      userEmail: userEmail,
      createdAt: ts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'total': total,
      'status': status,
      if (shipping != null) 'shipping': shipping,
      if (branch != null) 'branch': branch,
      if (userEmail != null) 'userEmail': userEmail,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
