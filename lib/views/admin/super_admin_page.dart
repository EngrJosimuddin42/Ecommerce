import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // 🔹 For readable date format
import '../../controllers/auth_controller.dart';
import '../../services/custom_snackbar.dart';
import 'admin_page.dart';
import '../../utils/alert_dialog_utils.dart';
import 'package:ecommerce/views/order/orders_list_page.dart';

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super.key});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final authController = Get.find<AuthController>();

  String adminInviteCode = "ADMIN2025"; // Default invite code

  @override
  void initState() {
    super.initState();
    _loadInviteCode();
  }

  Future<void> _loadInviteCode() async {
    final doc = await _firestore.collection('config').doc('adminConfig').get();
    if (doc.exists && doc.data()!.containsKey('inviteCode')) {
      setState(() {
        adminInviteCode = doc['inviteCode'];
      });
    }
  }

  Future<void> _updateInviteCode() async {
    TextEditingController codeController =
    TextEditingController(text: adminInviteCode);

    await Get.defaultDialog(
      title: "Update Admin Invite Code",
      content: TextField(
        controller: codeController,
        decoration: const InputDecoration(
          hintText: "Enter new invite code",
          border: OutlineInputBorder(),
        ),
      ),
      textConfirm: "Update",
      textCancel: "Cancel",
      onConfirm: () async {
        String newCode = codeController.text.trim();
        if (newCode.isEmpty) return;

        await _firestore
            .collection('config')
            .doc('adminConfig')
            .set({'inviteCode': newCode});

        setState(() => adminInviteCode = newCode);

        Get.back();
        CustomSnackbar.show(
          context,
          "✅ Invite code updated successfully!",
          backgroundColor: Colors.green,
        );
      },
    );
  }

  Future<void> _toggleUserStatus(String uid, bool currentStatus) async {
    await _firestore.collection('users').doc(uid).update({
      'active': !currentStatus,
    });

    CustomSnackbar.show(
      context,
      currentStatus
          ? "User disabled successfully!"
          : "User re-enabled successfully!",
      backgroundColor: currentStatus ? Colors.orange : Colors.green,
    );
  }

  Future<void> _deleteUser(String uid) async {
    bool confirmed = false;
    await Get.defaultDialog(
      title: "Delete User",
      middleText: "Are you sure you want to delete this user?",
      textConfirm: "Yes",
      textCancel: "No",
      onConfirm: () {
        confirmed = true;
        Get.back();
      },
      onCancel: () => Get.back(),
    );
    if (confirmed) {
      await _firestore.collection('users').doc(uid).delete();
      CustomSnackbar.show(
        context,
        "User deleted successfully!",
        backgroundColor: Colors.green,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text(
          "Super Admin Panel",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white),
            tooltip: 'View Orders',
            onPressed: () {
              Get.to(() => OrdersListPage(
                role: UserRole.superAdmin,
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              final shouldLogout = await AlertDialogUtils.showConfirm(
                context: context,
                title: "Confirm Logout",
                content: const Text("Are you sure you want to log out?"),
                confirmColor: Colors.red,
                cancelColor: Colors.grey,
                confirmText: "Logout",
                cancelText: "Cancel",
              );
              if (shouldLogout == true) {
                await authController.logout();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invite Code Card
            Card(
              elevation: 3,
              shadowColor: Colors.blueAccent.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.key, color: Colors.blue),
                ),
                title: const Text(
                  "Current Admin Invite Code",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    adminInviteCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: _updateInviteCode,
                  tooltip: 'Edit Invite Code',
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "All Users (Admin & Regular)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!.docs;
                  if (users.isEmpty) {
                    return const Center(
                      child: Text(
                        "No users found",
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.separated(
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userDoc = users[index];
                      final data = userDoc.data() as Map<String, dynamic>;

                      final isActive =
                      data.containsKey('active') ? data['active'] : true;
                      final role = data['role'] ?? 'user';
                      final isVerified = data['emailVerified'] ?? false;
                      final createdAt = data['createdAt'] != null
                          ? (data['createdAt'] as Timestamp).toDate()
                          : null;
                      final lastLogin = data['lastLogin'] != null
                          ? (data['lastLogin'] as Timestamp).toDate()
                          : null;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: role == 'admin'
                                ? Colors.blue.shade100
                                : Colors.green.shade100,
                            child: Icon(
                              role == 'admin'
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              color: role == 'admin' ? Colors.blue : Colors.green,
                            ),
                          ),
                          title: Text(
                            data['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['email'] ?? '',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              Text(
                                'Role: ${role.toUpperCase()}',
                                style: TextStyle(
                                  color:
                                  role == 'admin' ? Colors.blue : Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text('Email Verified: ${isVerified ? "Yes" : "No"}'),
                              if (createdAt != null)
                                Text(
                                    'Joined: ${DateFormat('dd-MM-yyyy, hh:mm a').format(createdAt)}'),
                              if (lastLogin != null)
                                Text(
                                    'Last Login: ${DateFormat('dd-MM-yyyy, hh:mm a').format(lastLogin)}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Active toggle
                              IconButton(
                                icon: Icon(
                                  isActive
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: isActive ? Colors.orange : Colors.green,
                                ),
                                tooltip: isActive ? 'Disable User' : 'Enable User',
                                onPressed: () =>
                                    _toggleUserStatus(userDoc.id, isActive),
                              ),
                              // Role Update / Promotion
                              if (!data['isSuperAdmin'])
                                IconButton(
                                  icon: Icon(
                                    role == 'admin'
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: role == 'admin' ? Colors.red : Colors.blue,
                                  ),
                                  tooltip: role == 'admin'
                                      ? 'Demote to User'
                                      : 'Promote to Admin',
                                  onPressed: () async {
                                    String newRole =
                                    role == 'admin' ? 'user' : 'admin';
                                    await _firestore
                                        .collection('users')
                                        .doc(userDoc.id)
                                        .update({'role': newRole});

                                    CustomSnackbar.show(
                                      context,
                                      role == 'admin'
                                          ? "Admin demoted to User"
                                          : "User promoted to Admin",
                                      backgroundColor:
                                      role == 'admin' ? Colors.orange : Colors.green,
                                    );
                                  },
                                ),
                              // Delete user
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                tooltip: 'Delete User',
                                onPressed: () => _deleteUser(userDoc.id),
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        onPressed: () {
          Get.to(() =>
          const AdminPage(isSuperAdmin: true, fromSuperAdmin: true));
        },
        label: const Text(
          "Open Admin Panel",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.store, color: Colors.white),
      ),
    );
  }
}
