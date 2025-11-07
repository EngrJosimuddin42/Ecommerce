import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../order/order_success_page.dart';
import '../../services/custom_snackbar.dart';
import '../../controllers/cart_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/cart_item_model.dart';

class PaymentPage extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final Map<String, String>? shippingInfo;
  final String? branch;
  final List<CartItem>? cartItems;

  const PaymentPage({
    super.key,
    required this.orderId,
    required this.totalAmount,
    this.shippingInfo,
    this.branch,
    this.cartItems,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isProcessing = false;
  final cartController = Get.find<CartController>();

  // 🔹 User info
  String cusName = '';
  String cusEmail = '';
  String cusPhone = '';
  String cusAddress = '';
  String cusCountry = 'Bangladesh';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          cusName = data['name'] ?? 'Customer';
          cusEmail = data['email'] ?? 'customer@example.com';
          cusPhone = data['phone'] ?? '01700000000';
          cusAddress = data['address'] ?? 'Dhaka';
          cusCountry = data['country'] ?? 'Bangladesh';
        });
      }
    }
  }

  // ================= Order Save After Success =================
  Future<void> _saveOrder(String paymentMethod) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).set({
        'userId': cartController.auth.currentUser!.uid,
        'items': widget.cartItems?.map((e) => e.toMap()).toList() ?? [],
        'total': widget.totalAmount,
        'shipping': widget.shippingInfo ?? {},
        'branch': widget.branch ?? 'Dhaka',
        'status': 'Pending',
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await cartController.clearCart();

      CustomSnackbar.show(context, 'Order placed successfully!', backgroundColor: Colors.green);
      Get.off(() => const OrderSuccessPage());
    } catch (e) {
      CustomSnackbar.show(context, '⚠ Failed to save order: $e', backgroundColor: Colors.red);
    }
  }

  // ================= SSLCommerz =================
  Future<void> _handleSSLCommerzPayment() async {
    setState(() => isProcessing = true);

    try {
      final response = await http.post(
        Uri.parse("https://sandbox.sslcommerz.com/gwprocess/v4/api.php"),
        body: {
          //Store Credentials
          "store_id": "YOUR_PRODUCTION_STORE_ID",
          "store_passwd": "YOUR_PRODUCTION_PASSWORD",

          //Transaction Data
          "total_amount": widget.totalAmount.toString(),
          "currency": "BDT",
          "tran_id": widget.orderId,
          "success_url": "https://yourdomain.com/payment-success",
          "fail_url": "https://yourdomain.com/payment-fail",
          "cancel_url": "https://yourdomain.com/payment-cancel",
          "emi_option": "0",

          //Customer Information
          "cus_name": cusName,
          "cus_email": cusEmail,
          "cus_phone": cusPhone,
          "cus_add1": cusAddress,
          "cus_country": cusCountry,

          //Product / Order Information
          "shipping_method": "NO",
          "product_name": "Order #${widget.orderId}",
          "product_category": "Ecommerce",
          "product_profile": "general",
        },
      );

      final data = jsonDecode(response.body);
      if (data["GatewayPageURL"] != null) {
        final url = Uri.parse(data["GatewayPageURL"]);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          CustomSnackbar.show(context, 'Please complete payment and return', backgroundColor: Colors.blue);

          // ✅ Save order after redirect (status Pending)
          await _saveOrder("SSLCommerz");
        } else {
          CustomSnackbar.show(context, '⚠ Cannot open payment URL', backgroundColor: Colors.red);
        }
      } else {
        CustomSnackbar.show(context, '⚠ SSLCommerz init failed', backgroundColor: Colors.red);
      }
    } catch (e) {
      CustomSnackbar.show(context, '⚠ Payment error: $e', backgroundColor: Colors.red);
    } finally {
      setState(() => isProcessing = false);
    }
  }

  // ================= Mobile Banking =================
  Future<void> _handleMobileBankingPayment(String provider) async {
    setState(() => isProcessing = true);
    try {
      final url = Uri.parse(
        "https://www.yourdomain.com/$provider/pay?"
            "amount=${widget.totalAmount}"
            "&order=${widget.orderId}"
            "&name=${Uri.encodeComponent(cusName)}"
            "&email=${Uri.encodeComponent(cusEmail)}"
            "&phone=${Uri.encodeComponent(cusPhone)}"
            "&address=${Uri.encodeComponent(cusAddress)}"
            "&country=${Uri.encodeComponent(cusCountry)}",
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        CustomSnackbar.show(context, 'Please complete payment and return', backgroundColor: Colors.blue);

        // ✅ Save order after redirect
        await _saveOrder(provider.toUpperCase());
      } else {
        CustomSnackbar.show(context, '⚠ Cannot open $provider payment URL', backgroundColor: Colors.red);
      }
    } catch (e) {
      CustomSnackbar.show(context, '⚠ $provider Payment failed: $e', backgroundColor: Colors.red);
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _handleBkashPayment() => _handleMobileBankingPayment("bKash");
  void _handleNagadPayment() => _handleMobileBankingPayment("Nagad");
  void _handleRocketPayment() => _handleMobileBankingPayment("Rocket");

  // ================= Cash on Delivery =================
  void _handleCashOnDelivery() async {
    setState(() => isProcessing = true);
    await _saveOrder('Cash on Delivery');
    setState(() => isProcessing = false);
  }

  // ================= UI Button Builder =================
  Widget _buildPaymentButton(String title, VoidCallback onTap, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: isProcessing ? null : onTap,
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        tileColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Payment Method")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order ID: ${widget.orderId}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              "Total Amount: ৳${widget.totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            isProcessing
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
              child: ListView(
                children: [
                  _buildPaymentButton("SSLCommerz / Card", _handleSSLCommerzPayment, Colors.blue, Icons.credit_card),
                  _buildPaymentButton("bKash", _handleBkashPayment, Colors.red, Icons.mobile_friendly),
                  _buildPaymentButton("Nagad", _handleNagadPayment, Colors.orange, Icons.mobile_friendly),
                  _buildPaymentButton("Rocket", _handleRocketPayment, Colors.green, Icons.mobile_friendly),
                  _buildPaymentButton("Cash on Delivery", _handleCashOnDelivery, Colors.purple, Icons.money),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
