import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import 'package:flutter/material.dart';

class ProductController extends GetxController {
  final FirebaseService _fs = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxList<ProductModel> products = <ProductModel>[].obs;
  RxList<ProductModel> filteredProducts = <ProductModel>[].obs;

  RxString selectedCategory = 'All'.obs;
  Rx<RangeValues> priceRange = const RangeValues(0, 50000).obs;

  @override
  void onInit() {
    super.onInit();
    _loadProducts();
  }

  /// 🔹 Load data using FirebaseService (with Firestore fallback)
  void _loadProducts() {
    try {
      _fs.productsStream().listen((list) {
        products.assignAll(list);
        applyFilters();
      }, onError: (_) async {
        print('⚠️ FirebaseService failed, using Firestore fallback...');
        _firestore.collection('products').snapshots().listen((snapshot) {
          final list = snapshot.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return ProductModel.fromMap(data, d.id);
          }).toList();
          products.assignAll(list);
          applyFilters();
        });
      });
    } catch (e) {
      print('❌ FirebaseService unavailable, fallback to Firestore');
      _firestore.collection('products').snapshots().listen((snapshot) {
        final list = snapshot.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return ProductModel.fromMap(data, d.id);
        }).toList();
        products.assignAll(list);
        applyFilters();
      });
    }
  }

  /// 🔹 Apply category + price range filter
  void applyFilters() {
    final minPrice = priceRange.value.start;
    final maxPrice = priceRange.value.end;

    var temp = products.where((p) {
      final price = (p.price ?? 0).toDouble();
      final categoryMatch =
          selectedCategory.value == 'All' || p.category == selectedCategory.value;
      final priceMatch = price >= minPrice && price <= maxPrice;
      return categoryMatch && priceMatch;
    }).toList();

    filteredProducts.assignAll(temp);
  }

  /// 🔹 Change category
  void changeCategory(String category) {
    selectedCategory.value = category;
    applyFilters();
  }

  /// 🔹 Change price range
  void changePriceRange(RangeValues range) {
    priceRange.value = range;
    applyFilters();
  }

  /// 🔹 Get all categories
  List<String> get allCategories => ['All', ...AppConstants.categories];
}
