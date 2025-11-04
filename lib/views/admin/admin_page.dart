import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../controllers/auth_controller.dart';
import 'package:ecommerce/services/custom_snackbar.dart';
import '../../utils/alert_dialog_utils.dart';
import 'package:ecommerce/utils/constants.dart';
import '../../models/product_model.dart';
import '../product/product_details_page.dart';
import '../widgets/specification_section.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:ecommerce/views/order/orders_list_page.dart';
import 'package:ecommerce/services/firebase_service.dart'; // FirebaseService class এর জন্য


class AdminPage extends StatefulWidget {
  final bool isSuperAdmin;
  final bool fromSuperAdmin;
  const AdminPage({super.key, this.isSuperAdmin = false, this.fromSuperAdmin = false});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // Controllers & Firestore
  final GlobalKey<FormState> _addFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _editFormKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController editNameController = TextEditingController();
  final TextEditingController editPriceController = TextEditingController();
  final TextEditingController editImageController = TextEditingController();
  final TextEditingController editDescriptionController = TextEditingController();

  final TextEditingController brandController = TextEditingController();
  final TextEditingController materialController = TextEditingController();
  final TextEditingController warrantyController = TextEditingController();
  final TextEditingController availabilityController = TextEditingController();
  final TextEditingController shipsFromController = TextEditingController();

  final TextEditingController editBrandController = TextEditingController();
  final TextEditingController editMaterialController = TextEditingController();
  final TextEditingController editWarrantyController = TextEditingController();
  final TextEditingController editAvailabilityController = TextEditingController();
  final TextEditingController editShipsFromController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final authController = Get.find<AuthController>();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseService _fs = FirebaseService();
  bool _isLoading = false;
  final List<String> categories = AppConstants.categories;
  String selectedCategory = 'Others / Uncategorized';
  String filterCategory = 'All';

  // ---------- Add Product ----------
  Future<void> _addProduct() async {
    if (!_addFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('products').add({
        'name': nameController.text,
        'price': double.tryParse(priceController.text) ?? 0.0,
        'image': imageController.text,
        'description': descriptionController.text,
        'category': selectedCategory,
        'specifications': {
          'brand': brandController.text,
          'material': materialController.text,
          'warranty': warrantyController.text,
          'availability': availabilityController.text,
          'shipsFrom': shipsFromController.text,
        },
        'rating': 0.0,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      CustomSnackbar.show(context, "Product added successfully!", backgroundColor: Colors.green);

      // Clear fields
      nameController.clear();
      priceController.clear();
      imageController.clear();
      descriptionController.clear();
      brandController.clear();
      materialController.clear();
      warrantyController.clear();
      availabilityController.clear();
      shipsFromController.clear();
      selectedCategory = 'Others / Uncategorized';
      setState(() {});
    } catch (e) {
      CustomSnackbar.show(context, e.toString(), backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------- Pick & Upload Image ----------
  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      final File imageFile = File(pickedFile.path); // ✅ works on emulator

      // Use your FirebaseService upload function
      final imageUrl = await _fs.uploadImage(imageFile);

      if (imageUrl != null) {
        imageController.text = imageUrl;
        CustomSnackbar.show(context, "Image uploaded successfully!", backgroundColor: Colors.green);
        setState(() {});
      } else {
        CustomSnackbar.show(context, "Image upload failed!", backgroundColor: Colors.red);
      }

    } catch (e) {
      CustomSnackbar.show(context, "Image upload failed: $e", backgroundColor: Colors.red);
    }
  }

  // ---------- Edit Product ----------
  Future<void> _editProduct(String id, Map<String, dynamic> data) async {
    editNameController.text = data['name'] ?? '';
    editPriceController.text = data['price']?.toString() ?? '';
    editImageController.text = data['image'] ?? '';
    editDescriptionController.text = data['description'] ?? '';

    final specs = Map<String, dynamic>.from(data['specifications'] ?? {});
    editBrandController.text = specs['brand'] ?? '';
    editMaterialController.text = specs['material'] ?? '';
    editWarrantyController.text = specs['warranty'] ?? '';
    editAvailabilityController.text = specs['availability'] ?? '';
    editShipsFromController.text = specs['shipsFrom'] ?? '';

    String localCategory = data['category'] ?? 'Others / Uncategorized';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Product'),
        content: SingleChildScrollView(
          child: Form(
            key: _editFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(editNameController, 'Product Name', 'Enter product name'),
                _buildTextField(editPriceController, 'Price', 'Enter price', isNumber: true),
                _buildTextField(editImageController, 'Image URL', 'Enter image URL'),
                _buildTextField(editDescriptionController, 'Description', 'Enter description', maxLines: 2),
                StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return DropdownButtonFormField<String>(
                      value: localCategory,
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) {
                        if (val != null) setStateDialog(() => localCategory = val);
                      },
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SpecificationSection(
                  brandController: editBrandController,
                  materialController: editMaterialController,
                  warrantyController: editWarrantyController,
                  availabilityController: editAvailabilityController,
                  shipsFromController: editShipsFromController,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () { _clearEditFields(); Navigator.pop(context); }, child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              if (!_editFormKey.currentState!.validate()) return;
              await _firestore.collection('products').doc(id).update({
                'name': editNameController.text,
                'price': double.tryParse(editPriceController.text) ?? 0.0,
                'image': editImageController.text,
                'description': editDescriptionController.text,
                'category': localCategory,
                'specifications': {
                  'brand': editBrandController.text,
                  'material': editMaterialController.text,
                  'warranty': editWarrantyController.text,
                  'availability': editAvailabilityController.text,
                  'shipsFrom': editShipsFromController.text,
                },
              });
              _clearEditFields();
              Navigator.pop(context);
              CustomSnackbar.show(context, 'Product updated successfully!', backgroundColor: Colors.green);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _clearEditFields() {
    editNameController.clear();
    editPriceController.clear();
    editImageController.clear();
    editDescriptionController.clear();
    editBrandController.clear();
    editMaterialController.clear();
    editWarrantyController.clear();
    editAvailabilityController.clear();
    editShipsFromController.clear();
  }

  Future<void> _deleteProduct(String id) async {
    final confirmed = await AlertDialogUtils.showConfirm(
      context: context,
      title: 'Delete Product',
      content: const Text('Are you sure you want to delete this product?'),
      confirmColor: Colors.red,
    );
    if (confirmed == true) {
      await _firestore.collection('products').doc(id).delete();
      CustomSnackbar.show(context, 'Product deleted successfully!', backgroundColor: Colors.green);
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, String errorText,
      {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (v) => v!.isEmpty ? errorText : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: widget.fromSuperAdmin,
          leading: widget.fromSuperAdmin ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()) : null,
          title: const Text('Admin Panel', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
          elevation: 5,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.photo_library, color: Colors.white), onPressed: _pickAndUploadImage),
            if (!widget.fromSuperAdmin) ...[
              IconButton(
                icon: const Icon(Icons.list_alt, color: Colors.white),
                onPressed: () { Get.to(() => OrdersListPage(role: widget.isSuperAdmin ? UserRole.superAdmin : UserRole.admin)); },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  final shouldLogout = await AlertDialogUtils.showConfirm(
                    context: context,
                    title: "Confirm Logout",
                    content: const Text("Are you sure you want to log out?"),
                    confirmColor: Colors.red,
                    cancelColor: Colors.black,
                    confirmText: "Logout",
                    cancelText: "Cancel",
                  );
                  if (shouldLogout == true) { await authController.logout(); }
                },
              ),
            ],
          ],
        ),
        body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              // ===== Add Product Form =====
              Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _addFormKey,
                    child: Column(
                      children: [
                        _buildTextField(nameController, 'Product Name', 'Enter product name'),
                        const SizedBox(height: 10),
                        _buildTextField(priceController, 'Price', 'Enter price', isNumber: true),
                        const SizedBox(height: 10),
                        _buildTextField(imageController, 'Image URL', 'Enter image URL'),
                        const SizedBox(height: 10),
                        _buildTextField(descriptionController, 'Description', 'Enter description', maxLines: 2),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                          onChanged: (val) { if (val != null) selectedCategory = val; setState(() {}); },
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SpecificationSection(
                          brandController: brandController,
                          materialController: materialController,
                          warrantyController: warrantyController,
                          availabilityController: availabilityController,
                          shipsFromController: shipsFromController,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading ? null : _addProduct,
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                                : const Text('Add Product', style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ===== Filter & Product List =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filter by Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
                  const SizedBox(height: 8),
                  DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      isExpanded: true,
                      value: filterCategory,
                      hint: const Text("Select Category"),
                      items: ['All', ...categories].map((cat) => DropdownMenuItem<String>(value: cat, child: Text(cat, style: const TextStyle(fontSize: 15)))).toList(),
                      onChanged: (val) { if (val != null) filterCategory = val; setState(() {}); },
                      buttonStyleData: ButtonStyleData(height: 52, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400), color: Colors.white), elevation: 1),
                      dropdownStyleData: DropdownStyleData(maxHeight: 300, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white, boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 2))]), padding: const EdgeInsets.symmetric(vertical: 6), offset: const Offset(0, 0)),
                      iconStyleData: const IconStyleData(icon: Icon(Icons.arrow_drop_down, color: Colors.indigo), iconSize: 30),
                      menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 0),
            const SizedBox(height: 6),
            SizedBox(
                height: screenHeight * 0.5,
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('products').orderBy('createdAt', descending: true).snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          final products = snapshot.data!.docs.where((doc) {
                            if (filterCategory == 'All') return true;
                            final data = doc.data() as Map<String, dynamic>;
                            return (data['category'] ?? 'Others / Uncategorized') == filterCategory;
                          }).toList();

                          if (products.isEmpty) return const Center(child: Text('No products found'));

                          return ListView.builder(
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                final data = product.data() as Map<String, dynamic>;
                                return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 3,
                                    child: ListTile(
                                        onTap: () { final productModel = ProductModel.fromMap(data, product.id); Get.to(() => ProductDetailPage(product: productModel, isAdmin: true)); },
                                        contentPadding: const EdgeInsets.all(12),
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            data['image'] ?? '',
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 60, color: Colors.grey),
                                          ),
                                        ),
                                        title: Text(data['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                            const SizedBox(height: 4),
                                        Text('\$${data['price']?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                        const SizedBox(height: 4),
                                        Row(
                                            children: [
                                            ...List.generate(5, (i) {
                                          final rating = data['rating'] ?? 0.0;
                                          if (rating >= i + 1) return const Icon(Icons.star, size: 16, color: Colors.amber);
                                          else if (rating > i)
                                            return const Icon(Icons.star_half,
                                                size: 16, color: Colors.amber);
                                          else
                                            return const Icon(Icons.star_border,
                                                size: 16, color: Colors.amber);
                                            }),
                                              const SizedBox(width: 4),
                                              Text(
                                                '(${data['reviewCount'] ?? 0})',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ],
                                        ),
                                            ],
                                        ),
                                      trailing: Wrap(
                                        spacing: 6,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blueAccent),
                                            onPressed: () =>
                                                _editProduct(product.id, data),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.redAccent),
                                            onPressed: () =>
                                                _deleteProduct(product.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                );
                              },
                          );
                        },
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

