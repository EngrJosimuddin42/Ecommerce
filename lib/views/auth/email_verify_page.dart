import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/views/home/home_page.dart';
import 'login_page.dart';
import '../admin/admin_page.dart';
import '../admin/super_admin_page.dart';
import '../../services/custom_snackbar.dart';

class EmailVerifyPage extends StatefulWidget {
  const EmailVerifyPage({super.key});

  @override
  State<EmailVerifyPage> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyPage> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // 🔹 Listen for user state changes (auto redirect if verified)
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null && user.emailVerified) {
        _navigateBasedOnRole(user.uid);
      }
    });
  }

  // 🔹 Role-based navigation
  Future<void> _navigateBasedOnRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      final role = data?['role'] ?? 'user';
      final isSuperAdmin = data?['isSuperAdmin'] ?? false;

      if (role == 'admin') {
        if (isSuperAdmin) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const SuperAdminPage()));
        } else {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const AdminPage()));
        }
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      CustomSnackbar.show(context, "⚠️ Failed to fetch user role: $e",
          backgroundColor: Colors.red);
    }
  }

  // 🔹 Navigate to login
  void _navigateToLogin() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  // 🔹 Check email verification
  Future<void> checkVerification() async {
    setState(() => isLoading = true);

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        CustomSnackbar.show(context, "⚠️ No logged in user found.",
            backgroundColor: Colors.red);
        return;
      }

      await user.reload(); // refresh user state

      if (user.emailVerified) {
        _navigateBasedOnRole(user.uid); // role-based redirect
      } else {
        CustomSnackbar.show(
            context,
            "📩 Email not verified yet.\nPlease check your inbox or spam folder.",
            backgroundColor: Colors.red);
      }
    } catch (e) {
      CustomSnackbar.show(
          context, "⚠️ Error checking verification: $e",
          backgroundColor: Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🔹 Resend verification email
  Future<void> resendEmail() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        CustomSnackbar.show(context, "⚠️ No logged in user found.",
            backgroundColor: Colors.red);
        return;
      }

      await user.sendEmailVerification();
      CustomSnackbar.show(
        context,
        "✅ Verification email sent again! Check your inbox or spam .",
        backgroundColor: Colors.green,
      );
    } catch (e) {
      CustomSnackbar.show(
          context, "⚠️ Failed to send verification email: $e",
          backgroundColor: Colors.red);
    }
  }

  // 🔹 Handle back button press
  Future<bool> _onWillPop() async {
    _navigateToLogin();
    return false; // prevent default pop
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Verify Your Email"),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateToLogin,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_unread,
                      size: 80, color: Colors.deepPurple),
                  const SizedBox(height: 20),
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.deepPurple.shade100)),
                      child: const Text(
                          "💡 If you registered before, please check your inbox or spam folder and verify your email.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w600,
                              fontSize: 13))),
                  const SizedBox(height: 20),
                  const Text(
                      "Please verify your email address to continue.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15)),
                  const SizedBox(height: 25),
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.deepPurple)
                      : ElevatedButton.icon(
                      onPressed: checkVerification,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.verified_user,
                          color: Colors.white),
                      label: const Text("I've Verified",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white))),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: resendEmail,
                    child: const Text("Resend Verification Email",
                        style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
