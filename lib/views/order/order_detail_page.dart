import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/pdf_service.dart';
import '../../services/custom_snackbar.dart';
class OrderDetailPage extends StatelessWidget {
  final OrderModel order;
  const OrderDetailPage({super.key, required this.order});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  Future<void> _exportOrderDetailsPdf(BuildContext context) async {
    try {
      await PdfService.exportOrderDetailsPdf(order: order.toMap());
      CustomSnackbar.show(context, 'PDF exported successfully!',backgroundColor: Colors.green);
    } catch (e) {
      debugPrint('PDF Export Error: $e');
      CustomSnackbar.show(context, 'PDF export failed: $e',backgroundColor: Colors.red);
    }
  }
  @override
  Widget build(BuildContext context) {
    final created = order.createdAt != null
        ? DateTime.fromMillisecondsSinceEpoch(order.createdAt!.millisecondsSinceEpoch)
        : null;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
        title: Text('Order Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔹 ORDER ID INFO CARD
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order#',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Divider(),
                Text('${order.id ?? '-'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 🔹 STATUS CARD
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(order.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          color: _statusColor(order.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 CUSTOMER INFO CARD
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer Information',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text('👤 Name: ${order.shipping?['name'] ?? ''}'),
                    Text('📞 Phone: ${order.shipping?['phone'] ?? ''}'),
                    Text('🏠 Address: ${order.shipping?['address'] ?? ''}'),
                    if (order.branch != null && order.branch!.isNotEmpty)
                      Text('🏢 Branch: ${order.branch}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 PAYMENT CARD
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Details',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text('💳 Payment Method: ${order.paymentMethod ?? 'N/A'}'),
                    if (created != null)
                      Text('🕒 Date: ${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 ITEMS CARD (optional)
            if (order.items != null && order.items!.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Items',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const Divider(),
                      ...order.items!.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(item['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Text('৳${item['price']} × ${item['quantity']}'),
                              Text('= ৳${item['subtotal']}'),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),

            // 🔹 TOTAL CARD
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.blue.shade50,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text(
                      '৳${order.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: const Text("Export PDF", style: TextStyle(color: Colors.white)),
        onPressed: () async => await _exportOrderDetailsPdf(context),
      ),
    );
  }
}
