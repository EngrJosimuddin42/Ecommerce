class ProductModel {
  String id;
  String title;
  String description;
  double price;
  String category;
  String imageUrl;
  double rating;       // 0.0 - 5.0
  int reviewCount;     // কতজন review দিয়েছেন
  Map<String, dynamic>? specifications; // Specifications like brand, warranty, etc.

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.specifications,
  });

  /// Factory constructor to create ProductModel from Firestore map
  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      title: map['title'] ?? map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? 'Uncategorized',
      imageUrl: map['imageUrl'] ?? map['image'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      specifications: Map<String, dynamic>.from(map['specifications'] ?? {}),
    );
  }

  /// Convert ProductModel to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'specifications': specifications ?? {},
    };
  }
}
