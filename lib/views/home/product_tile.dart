import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../product/product_details_page.dart';

class ProductTile extends StatelessWidget {
  final ProductModel product;

  const ProductTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product image with loading indicator
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null,
                        color: Colors.blueAccent,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                ),
              ),
            ),

            // Product title
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Product price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
              child: Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.green, fontSize: 14),
              ),
            ),

            // Rating & Review
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Row(
                children: [
                  // Star rating
                  Row(
                    children: List.generate(5, (index) {
                      if (index < product.rating.round()) {
                        return const Icon(Icons.star, color: Colors.orange, size: 16);
                      } else {
                        return const Icon(Icons.star_border, color: Colors.orange, size: 16);
                      }
                    }),
                  ),
                  const SizedBox(width: 6),
                  // Review count
                  Text(
                    '(${product.reviewCount})',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
