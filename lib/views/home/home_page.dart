import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../models/product_model.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/alert_dialog_utils.dart';
import '../home/product_tile.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../cart/cart_page.dart';
import 'package:ecommerce/utils/constants.dart';
import 'package:ecommerce/views/order/orders_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String filterCategory = 'All';

  final List<String> defaultCategories = AppConstants.categories;
  List<String> categories = [];

  // 🔹 Price range
  double minPrice = 0;
  double maxPrice = 50000;
  RangeValues currentRange = const RangeValues(0, 50000);

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  // 🔹 Load all categories from Firestore
  Future<void> fetchCategories() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('products').get();

      final fetched = snapshot.docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['category'] ?? 'Others / Uncategorized').toString();
      })
          .toSet()
          .toList();

      final allCats = {...defaultCategories, ...fetched}.toList();
      allCats.sort();

      setState(() {
        categories = allCats.isNotEmpty ? allCats : defaultCategories;
      });
    } catch (e) {
      debugPrint("⚠️ Error loading categories: $e");
      setState(() {
        categories = defaultCategories;
      });
    }
  }

  // 🔹 Firestore Query with combined filters
  Stream<QuerySnapshot> _buildProductStream() {
    Query query = FirebaseFirestore.instance.collection('products');

    // Filter by category
    if (filterCategory != 'All') {
      query = query.where('category', isEqualTo: filterCategory);
    }

    // Filter by price range (ensure price is number in Firestore)
    query = query
        .where('price', isGreaterThanOrEqualTo: currentRange.start)
        .where('price', isLessThanOrEqualTo: currentRange.end);

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final userRole = authController.currentUser == null
        ? UserRole.user
        : UserRole.user;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Shop Now',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Get.to(() => const CartPage());
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white),
            onPressed: () {
              Get.to(() => OrdersListPage(role: userRole));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final shouldLogout = await AlertDialogUtils.showConfirm(
                context: context,
                title: "Confirm Logout",
                content: const Text("Are you sure you want to log out?"),
                confirmColor: Colors.red,
                confirmText: "Logout",
                cancelText: "Cancel",
              );
              if (shouldLogout == true) {
                await authController.logout();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Filter section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Filter by Category",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    value: filterCategory,
                    hint: const Text("Select Category"),
                    items: ['All', ...categories]
                        .map(
                          (cat) => DropdownMenuItem<String>(
                        value: cat,
                        child: Text(
                          cat,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          filterCategory = val;
                        });
                      }
                    },
                    buttonStyleData: ButtonStyleData(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.white,
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 550,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 4,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      offset: const Offset(0, 0),
                    ),
                    iconStyleData: const IconStyleData(
                      icon: Icon(Icons.arrow_drop_down, color: Colors.indigo),
                      iconSize: 30,
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  "Filter by Price Range",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                RangeSlider(
                  values: currentRange,
                  min: minPrice,
                  max: maxPrice,
                  divisions: 50,
                  labels: RangeLabels(
                    currentRange.start.round().toString(),
                    currentRange.end.round().toString(),
                  ),
                  activeColor: Colors.blue,
                  inactiveColor: Colors.grey.shade300,
                  onChanged: (values) {
                    setState(() {
                      currentRange = values;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Min: ৳${currentRange.start.round()}"),
                    Text("Max: ৳${currentRange.end.round()}"),
                  ],
                ),
              ],
            ),
          ),

          // 🔹 Product Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildProductStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final products = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ProductModel.fromMap(data, doc.id);
                  }).toList();

                  if (products.isEmpty) {
                    return const Center(
                      child: Text(
                        "No products available",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.70,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductTile(product: product);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
