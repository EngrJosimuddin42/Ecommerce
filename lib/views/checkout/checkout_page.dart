import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/cart_controller.dart';
import '../../models/cart_item_model.dart';
import '../order/order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final cartController = Get.find<CartController>();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();

  bool isPlacingOrder = false;

  // ✅ All division branches in Bangladesh
  final List<String> branches = [
    'Dhaka',
    'Chattogram',
    'Khulna',
    'Rajshahi',
    'Barishal',
    'Sylhet',
    'Rangpur',
    'Mymensingh',
  ];
  String? selectedBranch;

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> placeOrder() async {
    if (cartController.cartItems.isEmpty) {
      Get.snackbar('Cart Empty', 'Your cart is empty!');
      return;
    }

    if (nameController.text.isEmpty ||
        addressController.text.isEmpty ||
        phoneController.text.isEmpty ||
        selectedBranch == null) {
      Get.snackbar('Error', 'Please fill all fields and select a branch.');
      return;
    }

    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(phoneController.text.trim())) {
      Get.snackbar('Error', 'Enter a valid phone number.');
      return;
    }

    setState(() => isPlacingOrder = true);

    try {
      final orderData = {
        'userId': cartController.auth.currentUser!.uid,
        'items': cartController.cartItems.map((e) => e.toMap()).toList(),
        'total': cartController.totalPrice,
        'shipping': {
          'name': nameController.text.trim(),
          'address': addressController.text.trim(),
          'phone': phoneController.text.trim(),
        },
        'branch': selectedBranch ?? 'Dhaka', // ✅ dynamic branch
        'status': 'Pending', // ✅ default status
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('orders').add(orderData);

      await cartController.clearCart();

      Get.off(() => const OrderSuccessPage());
    } catch (e) {
      Get.snackbar('Error', 'Failed to place order: $e');
    } finally {
      if (mounted) setState(() => isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Shipping Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ✅ Branch Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Division Branch',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                value: selectedBranch,
                items: branches
                    .map((b) =>
                    DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedBranch = value);
                },
              ),

              const SizedBox(height: 25),
              const Text('Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              ...cartController.cartItems.map(
                    (CartItem item) => ListTile(
                  title: Text(item.product.title),
                  trailing: Text(
                    '৳${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('৳${cartController.totalPrice.toStringAsFixed(2)}',
                      style:
                      const TextStyle(fontSize: 18, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: isPlacingOrder
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Place Order',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: isPlacingOrder ? null : placeOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
