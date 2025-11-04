import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../models/order_model.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/alert_dialog_utils.dart';
import '../../services/custom_snackbar.dart';
import '../../services/firebase_service.dart';

enum UserRole { user, admin, superAdmin }

class OrdersListPage extends StatefulWidget {
  final UserRole role;

  const OrdersListPage({super.key, required this.role});

  @override
  State<OrdersListPage> createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersListPage> {
  final FirebaseService _fs = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final authController = Get.find<AuthController>();

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

  Future<void> _loadBranches() async {
    setState(() => _loadingBranches = true);
    try {
      // Static list — তুমি চাইলে Firestore collection থেকে dynamic করো
      branches = [
        'Dhaka',
        'Chattogram',
        'Khulna',
        'Rajshahi',
        'Barishal',
        'Sylhet',
        'Rangpur',
        'Mymensingh',
      ];
    } catch (e) {
      debugPrint("Error loading branches: $e");
    }
    setState(() => _loadingBranches = false);
  }

  Query _buildQuery() {
    Query q = _firestore.collection('orders');

    if (widget.role == UserRole.user) {
      final userId = authController.currentUser?.uid;
      if (userId != null) q = q.where('userId', isEqualTo: userId);
    } else {
      if (branchFilter != null && branchFilter!.isNotEmpty) q = q.where('branch', isEqualTo: branchFilter);
    }

    if (statusFilter != 'All') q = q.where('status', isEqualTo: statusFilter);

    if (dateRange != null) {
      final start = Timestamp.fromDate(DateTime(dateRange!.start.year, dateRange!.start.month, dateRange!.start.day));
      final end = Timestamp.fromDate(DateTime(dateRange!.end.year, dateRange!.end.month, dateRange!.end.day, 23, 59, 59));
      q = q.where('createdAt', isGreaterThanOrEqualTo: start).where('createdAt', isLessThanOrEqualTo: end);
    }

    // যদি কিছু ডকুমেন্টে createdAt না থাকে, orderBy করলে error আসতে পারে.
    // নিশ্চিত করো সব order ডকুমেন্টে createdAt আছে। (checkout page-এ FieldValue.serverTimestamp() ব্যবহার করা আছে কিনা চেক করো)
    q = q.orderBy('createdAt', descending: true);
    return q;
  }

  List<OrderModel> _applyClientSearch(List<OrderModel> list) {
    if (searchQuery.trim().isEmpty) return list;
    final sq = searchQuery.toLowerCase();
    if (widget.role == UserRole.user) {
      return list.where((o) => o.id.toLowerCase().contains(sq)).toList();
    } else {
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

  Future<void> _updateStatus(OrderModel order) async {
    // preselect current status in dialog
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) {
        String local = order.status;
        return AlertDialog(
          title: const Text('Update Status'),
          content: StatefulBuilder(builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: local,
                  items: ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setStateDialog(() => local = v ?? local),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, local), child: const Text('Update')),
                  ],
                ),
              ],
            );
          }),
        );
      },
    );

    if (newStatus == null) {
      debugPrint('Update cancelled by user.');
      return;
    }

    if (newStatus == order.status) {
      CustomSnackbar.show(context, 'Status not changed', backgroundColor: Colors.orange);
      return;
    }

    try {
      debugPrint('Calling FirebaseService.updateOrderStatus(${order.id}, $newStatus)');
      await _fs.updateOrderStatus(order.id, newStatus);

      // Force small UI refresh (StreamBuilder should pick up the change from backend automatically,
      // but setState ensures local UI updates immediately).
      setState(() {});

      CustomSnackbar.show(context, 'Order status updated!', backgroundColor: Colors.green);

      // debug check: read document from firestore to confirm
      final doc = await _firestore.collection('orders').doc(order.id).get();
      debugPrint('Post-update doc snapshot: ${doc.data()}');
    } catch (e, st) {
      debugPrint('Failed to update order status: $e\n$st');
      CustomSnackbar.show(context, 'Failed to update: $e', backgroundColor: Colors.red);
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
      try {
        await _fs.deleteOrder(orderId);
        CustomSnackbar.show(context, 'Order deleted successfully!', backgroundColor: Colors.green);
        setState(() {});
      } catch (e) {
        CustomSnackbar.show(context, 'Failed to delete: $e', backgroundColor: Colors.red);
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final q = _buildQuery();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Text(widget.role == UserRole.user ? 'My Orders' : 'All Orders'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () { _loadBranches(); setState(() {}); }),
          IconButton(icon: const Icon(Icons.clear_all, color: Colors.white), tooltip: 'Clear filters', onPressed: () { setState(() { branchFilter = null; statusFilter = 'All'; dateRange = null; searchQuery = ''; }); }),
        ],
      ),
      body: Column(
        children: [
          // Filters UI (same as before)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (widget.role != UserRole.user)
                  SizedBox(
                    width: 180,
                    child: _loadingBranches
                        ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                        : DropdownButtonFormField<String>(
                      value: branchFilter,
                      decoration: InputDecoration(labelText: 'Branch', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                      items: <DropdownMenuItem<String>>[
                        const DropdownMenuItem(value: null, child: Text('All Branches')),
                        ...branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      ],
                      onChanged: (val) => setState(() => branchFilter = val),
                    ),
                  ),
                if (widget.role == UserRole.admin || widget.role == UserRole.superAdmin)
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      value: statusFilter,
                      decoration: InputDecoration(labelText: 'Status', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                      items: ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => statusFilter = val ?? 'All'),
                    ),
                  ),
                if (widget.role == UserRole.admin || widget.role == UserRole.superAdmin)
                  SizedBox(
                    width: 200,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: _pickDateRange,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.date_range),
                        const SizedBox(width: 8),
                        Flexible(child: Text(dateRange == null ? 'Any Date' : '${dateRange!.start.month}/${dateRange!.start.day}/${dateRange!.start.year} - ${dateRange!.end.month}/${dateRange!.end.day}/${dateRange!.end.year}', overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(hintText: widget.role == UserRole.user ? 'Search by order ID' : 'Search by order id, phone or name', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12)),
                onChanged: (v) => setState(() => searchQuery = v.trim()),
              ),
            ]),
          ),
          const Divider(height: 0),

          // StreamBuilder for realtime orders
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: q.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('No orders found'));

                final orders = docs.map((d) => OrderModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
                final filtered = _applyClientSearch(orders);

                if (filtered.isEmpty) return const Center(child: Text('No orders match the search/filter'));

                return RefreshIndicator(
                  onRefresh: () async { await _loadBranches(); setState(() {}); },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      final created = order.createdAt != null ? DateTime.fromMillisecondsSinceEpoch(order.createdAt!.millisecondsSinceEpoch) : null;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Row(children: [
                            Expanded(child: Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: _statusColor(order.status).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                              child: Text(order.status, style: TextStyle(color: _statusColor(order.status), fontWeight: FontWeight.bold)),
                            ),
                          ]),
                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const SizedBox(height: 6),
                            Text('Total: ৳${order.total.toStringAsFixed(2)}'),
                            if (order.shipping != null && (order.shipping!['name'] ?? '').toString().isNotEmpty) Text('Customer: ${order.shipping!['name']}'),
                            if (order.shipping != null && (order.shipping!['phone'] ?? '').toString().isNotEmpty) Text('Phone: ${order.shipping!['phone']}'),
                            if (order.branch != null && order.branch!.isNotEmpty) Text('Branch: ${order.branch}'),
                            if (created != null) Text('Date: ${created.year}-${created.month.toString().padLeft(2,'0')}-${created.day.toString().padLeft(2,'0')}'),
                          ]),
                          trailing: widget.role == UserRole.user
                              ? IconButton(icon: const Icon(Icons.visibility, color: Colors.indigo), onPressed: () { /* view dialog */ })
                              : Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.green), onPressed: () => _updateStatus(order)),
                            if (widget.role == UserRole.superAdmin)
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteOrder(order.id)),
                          ]),
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
    );
  }
}
