import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/product_model.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import 'package:ecommerce/services/custom_snackbar.dart';
import 'package:ecommerce/controllers/cart_controller.dart';
import 'package:ecommerce/views/checkout/checkout_page.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductModel product;
  final bool isAdmin;

  const ProductDetailPage({super.key, required this.product, this.isAdmin = false});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  double selectedRating = 0;
  final TextEditingController commentController = TextEditingController();
  bool isSubmitting = false;
  bool showReviews = false;

  final authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitReview() async {
    if (selectedRating == 0 || commentController.text.trim().isEmpty) {
      CustomSnackbar.show(context, 'Please select rating & write comment', backgroundColor: Colors.orange);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final productRef = _firestore.collection('products').doc(widget.product.id);
      final user = authController.currentUser;
      if (user == null) throw Exception("User not logged in");

      final reviewRef = productRef.collection('reviews').doc();

      await reviewRef.set({
        'userId': user.uid,
        'username': user.displayName ?? user.email?.split('@').first ?? 'Anonymous',
        'rating': selectedRating,
        'comment': commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      commentController.clear();
      setState(() => selectedRating = 0);
      CustomSnackbar.show(context, 'Review submitted successfully!', backgroundColor: Colors.green);

      final reviewsSnapshot = await productRef.collection('reviews').get();
      final reviewCount = reviewsSnapshot.docs.length;
      double avgRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        avgRating += (doc.data()['rating'] ?? 0);
      }
      avgRating = reviewCount > 0 ? avgRating / reviewCount : 0;

      await productRef.update({'rating': avgRating, 'reviewCount': reviewCount});
    } catch (e) {
      CustomSnackbar.show(context, e.toString(),
        backgroundColor: Colors.red);

    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> deleteReview(String reviewId, String reviewUserId) async {
    final user = authController.currentUser;
    if (user == null) throw Exception("User not logged in");

    if (user.uid == reviewUserId || widget.isAdmin) {
      await _firestore
          .collection('products')
          .doc(widget.product.id)
          .collection('reviews')
          .doc(reviewId)
          .delete();
      CustomSnackbar.show(context, 'Review deleted successfully!', backgroundColor: Colors.green);
    } else
      CustomSnackbar.show(context, 'You can not delete this review', backgroundColor: Colors.red);
  }

  List<Widget> buildStars(double rating) {
    return List.generate(5, (index) {
      if (rating >= index + 1) return const Icon(Icons.star, color: Colors.amber, size: 22);
      if (rating > index && rating < index + 1) return const Icon(Icons.star_half, color: Colors.amber, size: 22);
      return const Icon(Icons.star_border, color: Colors.amber, size: 22);
    });
  }

  Widget buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final specs = widget.product.specifications;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text("Product Details"),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'productImage_${widget.product.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.product.imageUrl,
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 120, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(widget.product.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.category, size: 20, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text(widget.product.category, style: const TextStyle(fontSize: 15, color: Colors.blueGrey)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ...buildStars(widget.product.rating),
                  const SizedBox(width: 8),
                  Text("${widget.product.rating.toStringAsFixed(1)} (${widget.product.reviewCount} reviews)",
                      style: const TextStyle(color: Colors.black54, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('\$${widget.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
              ),
              const SizedBox(height: 25),
              const Text("Product Description", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(widget.product.description.isNotEmpty
                      ? widget.product.description
                      : "No detailed description available.",
                      style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                      textAlign: TextAlign.justify),
                ),
              ),
              const SizedBox(height: 25),

              const Text("Submit Your Review", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                maxRating: 5,
                allowHalfRating: true,
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) => setState(() => selectedRating = rating),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Write your review here",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Submit Review", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Reviews", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(showReviews ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.blueAccent),
                    onPressed: () => setState(() => showReviews = !showReviews),
                  ),
                ],
              ),
              if (showReviews)
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('products')
                      .doc(widget.product.id)
                      .collection('reviews')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final reviews = snapshot.data!.docs;
                    if (reviews.isEmpty) return const Text('No reviews yet.');
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        final data = review.data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(data['username'] ?? 'Anonymous'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(5, (i) {
                                    return Icon(
                                      i < (data['rating'] ?? 0) ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 18,
                                    );
                                  }),
                                ),
                                Text(data['comment'] ?? ''),
                              ],
                            ),
                            trailing: (data['userId'] == authController.currentUser?.uid || widget.isAdmin)
                                ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteReview(review.id, data['userId']),
                            )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 25),

              const Text("Specifications", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSpecRow("Brand", specs?['brand'] ?? "Unknown"),
                    buildSpecRow("Material", specs?['material'] ?? "High quality plastic"),
                    buildSpecRow("Warranty", specs?['warranty'] ?? "1 Year"),
                    buildSpecRow("Availability", specs?['availability'] ?? "In Stock"),
                    buildSpecRow("Ships From", specs?['shipsFrom'] ?? "Bangladesh"),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                      label: const Text("Add to Cart", style: TextStyle(fontSize: 16, color: Colors.white)),
                      onPressed: () {
                        try {
                          final cartController = Get.find<CartController>();
                          cartController.addToCart(widget.product);
                        } catch (e) {
                          CustomSnackbar.show(context, "CartController not found!", backgroundColor: Colors.red);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.shopping_bag, color: Colors.white),
                      label: const Text("Buy Now", style: TextStyle(fontSize: 16, color: Colors.white)),
                      onPressed: () {
                        try {
                          final cartController = Get.find<CartController>();

                          // ✅ Check if product already in cart
                          final exists = cartController.cartItems.any((item) => item.product.id == widget.product.id);
                          if (!exists) {
                            cartController.addToCart(widget.product);
                          }

                          // Navigate to checkout
                          Get.to(() => const CheckoutPage());
                        } catch (e) {
                          CustomSnackbar.show(context, "CartController not found!", backgroundColor: Colors.red);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.blueAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.blueAccent, size: 18),
                  label: const Text("Back to Products", style: TextStyle(fontSize: 16, color: Colors.blueAccent)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
