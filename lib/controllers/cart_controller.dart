import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/custom_snackbar.dart';

class CartController extends GetxController {
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  var cartItems = <CartItem>[].obs;
  StreamSubscription<QuerySnapshot>? _cartSubscription;

  /// ✅ এই flag টি cart update temporarily বন্ধ করতে ব্যবহৃত হবে
  bool _pauseListening = false;

  /// 🔹 Listening বন্ধ করা
  void pauseListening() {
    _pauseListening = true;
  }

  /// 🔹 Listening পুনরায় চালু করা
  void resumeListening() {
    _pauseListening = false;
    _listenToCart(); // refresh
  }

  @override
  void onInit() {
    super.onInit();
    _listenToCart();

    auth.userChanges().listen((_) {
      _listenToCart();
    });
  }

  @override
  void onClose() {
    _cartSubscription?.cancel();
    super.onClose();
  }

  /// 🔹 Firestore cart listener
  void _listenToCart() {
    _cartSubscription?.cancel();

    final user = auth.currentUser;
    if (user == null) {
      cartItems.clear();
      return;
    }

    _cartSubscription = firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .snapshots()
        .listen((snapshot) {
      if (_pauseListening) return; // ✅ listening বন্ধ থাকলে skip করবে

      cartItems.assignAll(snapshot.docs.map((doc) {
        final data = doc.data();
        return CartItem(
          product: ProductModel(
            id: doc.id,
            title: data['title'] ?? '',
            price: (data['price'] ?? 0).toDouble(),
            imageUrl: data['imageUrl'] ?? '',
            description: data['description'] ?? '',
            category: data['category'] ?? '',
          ),
          quantity: data['quantity'] ?? 1,
        );
      }).toList());
    });
  }

  /// 🔹 Add product
  Future<void> addToCart(ProductModel product) async {
    final user = auth.currentUser;
    if (user == null) {
      CustomSnackbar.show(Get.context!, 'Please login first!',
          backgroundColor: Colors.red);
      return;
    }

    final docRef = firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(product.id);

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.update({'quantity': FieldValue.increment(1)});
    } else {
      await docRef.set({
        'title': product.title,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'description': product.description,
        'category': product.category,
        'quantity': 1,
      });
    }
  }

  /// 🔹 Remove item
  Future<void> removeFromCart(ProductModel product) async {
    final user = auth.currentUser;
    if (user == null) return;

    await firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(product.id)
        .delete();
  }

  /// 🔹 Decrease quantity
  Future<void> decreaseQuantity(ProductModel product) async {
    final user = auth.currentUser;
    if (user == null) return;

    final docRef = firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(product.id);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final quantity = doc['quantity'] ?? 1;
    if (quantity > 1) {
      await docRef.update({'quantity': FieldValue.increment(-1)});
    } else {
      await docRef.delete();
    }
  }

  /// 🔹 Total cart value
  double get totalPrice =>
      cartItems.fold(0, (sum, item) => sum + item.subtotal);

  /// 🔹 Clear cart
  Future<void> clearCart() async {
    final user = auth.currentUser;
    if (user == null) return;

    final batch = firestore.batch();
    final items = await firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .get();
    for (var doc in items.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
