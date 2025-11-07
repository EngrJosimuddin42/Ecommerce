import 'package:ecommerce/models/product_model.dart';

class CartItem {
  ProductModel product;
  int quantity;

  CartItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'title': product.title,
      'price': product.price,
      'imageUrl': product.imageUrl,
      'description': product.description,
      'category': product.category,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}
