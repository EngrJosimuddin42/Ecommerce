import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 🔹 Stream of products
  Stream<List<ProductModel>> productsStream() {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList());
  }

  // 🔹 Add a new order
  Future<void> addOrder(Map<String, dynamic> orderData) async {
    await _db.collection('orders').add(orderData);
  }

  // 🔹 Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});
  }

  // 🔹 Delete an order
  Future<void> deleteOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).delete();
  }

  // 🔹 Fetch all orders (optional, for admin)
  Future<List<OrderModel>> getOrders() async {
    final snapshot = await _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // 🔹 Upload Image to Firebase Storage
  Future<String?> uploadImage(File imageFile) async {
    try {
      // 🔹 Check if file exists
      if (!await imageFile.exists()) {
        print("⚠️ Image file not found: ${imageFile.path}");
        return null;
      }

      // 🔹 Get file extension dynamically (jpg, png, etc.)
      final extension = imageFile.path.split('.').last.toLowerCase();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // 🔹 Reference in Firebase Storage
      final ref = _storage.ref().child("product_images/$fileName.$extension");

      // 🔹 Upload file
      final uploadTask = await ref.putFile(imageFile);

      // 🔹 Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print("✅ Uploaded image URL: $downloadUrl");

      return downloadUrl;
    } on FirebaseException catch (e) {
      print("❌ Firebase upload error: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("❌ Unknown error uploading image: $e");
      return null;
    }
  }
}
