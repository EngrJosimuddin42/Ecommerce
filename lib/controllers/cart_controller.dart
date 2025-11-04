import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import 'package:ecommerce/services/custom_snackbar.dart';

class CartController extends GetxController {
  // Firebase instances
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // Reactive cart items
  var cartItems = <CartItem>[].obs;
  StreamSubscription<QuerySnapshot>? _cartSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToCart();
  }

  @override
  void onClose() {
    _cartSubscription?.cancel();
    super.onClose();
  }

  // Listen to realtime cart changes
  void _listenToCart() {
    final user = auth.currentUser;
    if (user == null) return;

    _cartSubscription = firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .snapshots()
        .listen((snapshot) {
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
          qty: data['qty'] ?? 1,
        );
      }).toList());
    });
  }

  // Add product to cart
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
      await docRef.update({'qty': FieldValue.increment(1)});
    } else {
      await docRef.set({
        'title': product.title,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'description': product.description,
        'category': product.category,
        'qty': 1,
      });
    }

    CustomSnackbar.show(Get.context!, '${product.title} added to cart!',
        backgroundColor: Colors.green);
  }

  // Remove product from cart
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

  // Decrease quantity
  Future<void> decreaseQty(ProductModel product) async {
    final user = auth.currentUser;
    if (user == null) return;

    final docRef = firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(product.id);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final qty = doc['qty'] ?? 1;
    if (qty > 1) {
      await docRef.update({'qty': FieldValue.increment(-1)});
    } else {
      await docRef.delete();
    }
  }

  // Total cart price
  double get totalPrice =>
      cartItems.fold(0, (sum, item) => sum + item.subtotal);

  // Clear entire cart
  Future<void> clearCart() async {
    final user = auth.currentUser;
    if (user == null) return;

    final batch = firestore.batch();
    final itemsRef =
    await firestore.collection('carts').doc(user.uid).collection('items').get();
    for (var doc in itemsRef.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
