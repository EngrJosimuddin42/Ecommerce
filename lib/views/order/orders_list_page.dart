import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../models/order_model.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/alert_dialog_utils.dart';
import '../../services/custom_snackbar.dart';
import '../../services/pdf_service.dart';


enum UserRole { user, admin, superAdmin }

class OrdersListPage extends StatefulWidget {
  final UserRole role;

  const OrdersListPage({super.key, required this.role});

  @override
  State<OrdersListPage> createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final authController = Get.find<AuthController>();

  // Filters / UI state
  String? branchFilter;
  String statusFilter = 'All';
  DateTimeRange? dateRange;
  String searchQuery = '';
  List<String> branches = [];
  bool _loadingBranches = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  // exportOrdersToPdf method
  Future<void> _exportOrdersToPdf() async {
    try {
      final snapshot = await _buildQuery().get();
      final orders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['shipping']?['name'] ?? '',
          'address': data['shipping']?['address'] ?? '',
          'phone': data['shipping']?['phone'] ?? '',
          'branch': data['branch'] ?? '',
          'status': data['status'] ?? '',
          'total': data['total'] ?? 0,
          'createdAt': data['createdAt'],
        };
      }).toList();

      if (orders.isEmpty) {
        CustomSnackbar.show(context, 'No orders available for export',backgroundColor: Colors.red);
        return;
      }


      // 🔹 Dynamic Title (role অনুযায়ী)
      final title = widget.role == UserRole.superAdmin
          ? 'Super Admin Orders Report'
          : widget.role == UserRole.admin
          ? 'Admin Orders Report'
          : 'My Orders Report';

      // 🔹 Export PDF using PdfService
      await PdfService.exportPdf(
        title: title,
        orders: orders,
      );
    } catch (e) {
      debugPrint('PDF Export Error: $e');
      if (mounted) {
        CustomSnackbar.show(context, 'PDF export failed: $e',backgroundColor: Colors.red);
      }
    }
  }

  // --- Load branch list  ---
  Future<void> _loadBranches() async {
    setState(() => _loadingBranches = true);
    try {
      branches = [
        'Dhaka', 'Chattogram', 'Khulna', 'Rajshahi', 'Barishal', 'Sylhet', 'Rangpur', 'Mymensingh'
      ];
    } catch (e) {
      debugPrint("Error loading branches: $e");
    }
    setState(() => _loadingBranches = false);
  }

  Query _buildQuery() {
    Query q = _firestore.collection('orders');

    // User sees only own orders
    if (widget.role == UserRole.user) {
      final userId = authController.currentUser?.uid;
      if (userId != null) q = q.where('userId', isEqualTo: userId);
    }
    // Admin/SuperAdmin হলে branch filter
    else {
      if (branchFilter != null && branchFilter!.isNotEmpty) {
        q = q.where('branch', isEqualTo: branchFilter);
      }
    }
    //  status filter
    if (statusFilter != 'All') {
      q = q.where('status', isEqualTo: statusFilter);
    }
    // date range filter
    if (dateRange != null) {
      final start = Timestamp.fromDate(DateTime(dateRange!.start.year, dateRange!.start.month, dateRange!.start.day));
      final end = Timestamp.fromDate(DateTime(dateRange!.end.year, dateRange!.end.month, dateRange!.end.day, 23, 59, 59));
      q = q.where('createdAt', isGreaterThanOrEqualTo: start).where('createdAt', isLessThanOrEqualTo: end);
    }
    // order by date
    return q.orderBy('createdAt', descending: true);
  }
  // Local client-side search
  List<OrderModel> _applyClientSearch(List<OrderModel> list) {
    if (searchQuery.trim().isEmpty) return list;
    final sq = searchQuery.toLowerCase();

    // Local client-side search
    if (widget.role == UserRole.user) {
      return list.where((o) => o.id.toLowerCase().contains(sq)).toList();
    }
    // admin/superAdmin: search by id, phone, name, email
    else {
      return list.where((o) {
        final idMatch = o.id.toLowerCase().contains(sq);
        final phone = (o.shipping?['phone'] ?? '').toString().toLowerCase();
        final name = (o.shipping?['name'] ?? '').toString().toLowerCase();
        final email = (o.userEmail ?? '').toString().toLowerCase();
        return idMatch || phone.contains(sq) || name.contains(sq) || email.contains(sq);
      }).toList();
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: dateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );
    if (picked != null) setState(() => dateRange = picked);
  }

  void _clearFilters() {
    setState(() {
      branchFilter = null;
      statusFilter = 'All';
      dateRange = null;
      searchQuery = '';
    });
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _updateStatus(OrderModel order) async {
    String selectedStatus = order.status;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title:const Text('Update Status'),
        content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setStateDialog(() => selectedStatus = v ?? selectedStatus),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () => Navigator.pop(context, selectedStatus), child: const Text('Update')),
                    ],
                  ),
                ],
              );
            }),
      ),
    );

    if (result != null && result != order.status) {
      try {
        await _firestore.collection('orders').doc(order.id).update({'status': result});
        CustomSnackbar.show(context, 'Order status updated successfully!', backgroundColor: Colors.green);
        setState(() {});
      } catch (e) {
        CustomSnackbar.show(context, 'Failed to update status: $e', backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    final confirmed = await AlertDialogUtils.showConfirm(
      context: context,
      title: 'Delete Order',
      content: const Text('Are you sure you want to delete this order?'),
      confirmColor: Colors.red,
    );

    if (confirmed == true) {
      await _firestore.collection('orders').doc(orderId).delete();
      CustomSnackbar.show(context, 'Order deleted successfully!', backgroundColor: Colors.green);
    }
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final confirmed = await AlertDialogUtils.showConfirm(
      context: context,
      title: 'Cancel Order',
      content: const Text('Are you sure you want to cancel this order?'),
      confirmColor: Colors.red,
    );

    if (confirmed == true) {
      await _firestore.collection('orders').doc(order.id).update({'status': 'Cancelled'});
      CustomSnackbar.show(context, 'Order cancelled successfully!', backgroundColor: Colors.redAccent);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _buildQuery();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Text(widget.role == UserRole.user ? 'My Orders' : widget.role == UserRole.admin ? 'All Orders' : 'All Orders'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadBranches();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            tooltip: 'Clear filters',
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // ----- Filters UI -----
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // ---- Branch filter
                    if (widget.role != UserRole.user)
                      SizedBox(
                        width: 180,
                        child: _loadingBranches
                            ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                            : DropdownButtonFormField<String>(
                          value: branchFilter,
                          decoration: InputDecoration(
                            labelText: 'Branch',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Branches')),
                            ...branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          ],
                          onChanged: (val) => setState(() => branchFilter = val),
                        ),
                      ),
                    // ---- Status filter
                    if (widget.role == UserRole.admin || widget.role == UserRole.superAdmin) ...[
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<String>(
                          value: statusFilter,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (val) => setState(() => statusFilter = val ?? 'All'),
                        ),
                      ),
                      // --- Date Range Button ---
                      SizedBox(
                        width: 200,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _pickDateRange,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.date_range),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  dateRange == null
                                      ? 'Any Date'
                                      : '${dateRange!.start.month}/${dateRange!.start.day}/${dateRange!.start.year} - ${dateRange!.end.month}/${dateRange!.end.day}/${dateRange!.end.year}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: widget.role == UserRole.user
                        ? 'Search by order ID'
                        : 'Search by order id, phone or name',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  ),
                  onChanged: (v) {
                    // ✅ user হলে শুধু order ID search হবে
                    if (widget.role == UserRole.user) {
                      setState(() => searchQuery = v.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim());
                    } else {
                      setState(() => searchQuery = v.trim());
                    }
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 0),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: q.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var orders = snapshot.data?.docs.map((d) {
                  final map = d.data() as Map<String, dynamic>;
                  return OrderModel.fromMap(map, d.id);
                }).toList() ??
                    [];

                orders = _applyClientSearch(orders);

                if (orders.isEmpty) return const Center(child: Text('No orders match filters/search'));

                return RefreshIndicator(
                  onRefresh: () async {
                    await _loadBranches();
                    setState(() {});
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final created = order.createdAt != null
                          ? DateTime.fromMillisecondsSinceEpoch(order.createdAt!.millisecondsSinceEpoch)
                          : null;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Row(
                            children: [
                              Expanded(child: Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _statusColor(order.status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(order.status, style: TextStyle(color: _statusColor(order.status), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text('Total: ৳${order.total.toStringAsFixed(2)}'),
                              if (order.shipping?['name'] != null && order.shipping!['name']!.isNotEmpty)
                                Text('Customer: ${order.shipping!['name']}'),
                              if (order.shipping?['phone'] != null && order.shipping!['phone']!.isNotEmpty)
                                Text('Phone: ${order.shipping!['phone']}'),
                              if (order.branch != null && order.branch!.isNotEmpty) Text('Branch: ${order.branch}'),
                              if (created != null)
                                Text('Date: ${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}'),
                            ],
                          ),
                          trailing: widget.role == UserRole.user
                              ? IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.indigo),
                            onPressed: () => _showUserOrderDialog(order),
                          )
                              : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.green),
                                onPressed: () => _updateStatus(order),
                              ),
                              if (widget.role == UserRole.superAdmin)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteOrder(order.id),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

        // 🔹 Floating button for PDF export
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.blue.shade700,
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: const Text("Export PDF", style: TextStyle(color: Colors.white)),
          onPressed: _exportOrdersToPdf)
    );
  }

  void _showUserOrderDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Order #${order.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${order.status}'),
            Text('Total: ৳${order.total.toStringAsFixed(2)}'),
            if (order.shipping?['name'] != null && order.shipping!['name']!.isNotEmpty)
              Text('Customer: ${order.shipping!['name']}'),
            if (order.shipping?['phone'] != null && order.shipping!['phone']!.isNotEmpty)
              Text('Phone: ${order.shipping!['phone']}'),
            if (order.branch != null && order.branch!.isNotEmpty) Text('Branch: ${order.branch}'),
            if (order.createdAt != null)
              Text('Date: ${DateTime.fromMillisecondsSinceEpoch(order.createdAt!.millisecondsSinceEpoch).toLocal()}'),
          ],
        ),
        actions: [
          if (order.status.toLowerCase() != 'shipped' &&
              order.status.toLowerCase() != 'delivered' &&
              order.status.toLowerCase() != 'cancelled')
            TextButton.icon(
              icon: const Icon(Icons.cancel, color: Colors.red),
              label: const Text('Cancel Order'),
              onPressed: () async {
                Navigator.pop(context);
                await _cancelOrder(order);
              },
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
