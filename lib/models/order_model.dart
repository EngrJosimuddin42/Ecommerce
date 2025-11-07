import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final double total;
  String status;
  final Map<String, dynamic>? shipping;
  final String? branch;
  final String? userEmail;
  final String? paymentMethod;
  final List<Map<String, dynamic>>? items;
  final Timestamp? createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.total,
    required this.status,
    this.shipping,
    this.branch,
    this.userEmail,
    this.paymentMethod,
    this.items,
    this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    final shipping = (map['shipping'] is Map)
        ? Map<String, dynamic>.from(map['shipping'])
        : null;

    final items = (map['items'] is List)
        ? List<Map<String, dynamic>>.from(map['items'])
        : null;

    final branch = map['branch']?.toString();
    final userEmail = map['userEmail']?.toString();
    final paymentMethod = map['paymentMethod']?.toString();

    // Handle createdAt
    Timestamp? ts;
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      ts = rawCreated;
    } else if (rawCreated is Map && rawCreated.containsKey('_seconds')) {
      ts = Timestamp(
        rawCreated['_seconds'] as int? ?? 0,
        rawCreated['_nanoseconds'] as int? ?? 0,
      );
    } else if (rawCreated is int) {
      ts = Timestamp.fromMillisecondsSinceEpoch(rawCreated);
    } else if (rawCreated is DateTime) {
      ts = Timestamp.fromDate(rawCreated);
    }

    return OrderModel(
      id: docId,
      userId: map['userId']?.toString() ?? '',
      total: (map['total'] ?? 0).toDouble(),
      status: map['status']?.toString() ?? 'Pending',
      shipping: shipping,
      branch: branch,
      userEmail: userEmail,
      paymentMethod: paymentMethod,
      items: items,
      createdAt: ts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'total': total,
      'status': status,
      if (shipping != null) 'shipping': shipping,
      if (branch != null) 'branch': branch,
      if (userEmail != null) 'userEmail': userEmail,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (items != null) 'items': items,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
