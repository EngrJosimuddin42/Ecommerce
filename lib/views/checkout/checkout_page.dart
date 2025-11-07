import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cart_controller.dart';
import '../payment/payment_page.dart';
import '../../services/custom_snackbar.dart';
import 'dart:math';

String generateRandomString(int length) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final rand = Random.secure();
  return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
}

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
  String? selectedBranch;

  final List<String> branches = [
    'Dhaka', 'Chattogram', 'Khulna', 'Rajshahi',
    'Barishal', 'Sylhet', 'Rangpur', 'Mymensingh',
  ];

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> placeOrder() async {
    final cartItems = cartController.cartItems;

    if (cartItems.isEmpty) {
      CustomSnackbar.show(context, '⚠ Your cart is empty! Please add an item first.', backgroundColor: Colors.red);
      return;
    }

    if (nameController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        selectedBranch == null) {
      CustomSnackbar.show(context, '⚠ Please fill all fields', backgroundColor: Colors.red);
      return;
    }

    if (!RegExp(r'^(01[3-9]\d{8})$').hasMatch(phoneController.text.trim())) {
      CustomSnackbar.show(context, '⚠ Invalid phone number!', backgroundColor: Colors.red);
      return;
    }

    setState(() => isPlacingOrder = true);

    // 🔹 Generate production-safe orderId (timestamp + random 7 chars)
    final String orderId = generateRandomString(20);
    final List cartItemsCopy = List.from(cartItems);

    // 🔹 Navigate to PaymentPage
    Get.to(() => PaymentPage(
      orderId: orderId,
      totalAmount: cartController.totalPrice,
      shippingInfo: {
        'name': nameController.text.trim(),
        'address': addressController.text.trim(),
        'phone': phoneController.text.trim(),
      },
      branch: selectedBranch ?? 'Dhaka',
      cartItems: cartItemsCopy.cast(),
    ));

    setState(() => isPlacingOrder = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'),centerTitle: true, backgroundColor: Colors.green),
      body: Obx(() {
        final cartItems = cartController.cartItems;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Shipping Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildInputField(nameController, 'Full Name', Icons.person),
                const SizedBox(height: 12),
                _buildInputField(addressController, 'Address', Icons.home),
                const SizedBox(height: 12),
                _buildInputField(phoneController, 'Phone Number', Icons.phone, keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Branch',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  value: selectedBranch,
                  items: branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (value) => setState(() => selectedBranch = value),
                ),
                const SizedBox(height: 25),
                const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (cartItems.isEmpty) const Center(child: Text('No items in cart', style: TextStyle(color: Colors.grey))),
                ...cartItems.map((item) => ListTile(
                  title: Text(item.product.title),
                  subtitle: Text('${item.quantity} × ৳${item.product.price.toStringAsFixed(2)}'),
                  trailing: Text('৳${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('৳${cartController.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: isPlacingOrder
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(isPlacingOrder ? 'Processing...' : 'Proceed to Payment'),
                    onPressed: isPlacingOrder ? null : placeOrder,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
