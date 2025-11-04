import 'package:ecommerce/models/product_model.dart';

class CartItem {
  ProductModel product;
  int qty;

  CartItem({required this.product, required this.qty});

  double get subtotal => product.price * qty;

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'title': product.title,
      'price': product.price,
      'imageUrl': product.imageUrl,
      'description': product.description,
      'category': product.category,
      'qty': qty,
      'subtotal': subtotal,
    };
  }
}
