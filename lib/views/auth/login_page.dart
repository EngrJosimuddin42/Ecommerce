import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../admin/admin_page.dart';
import '../admin/super_admin_page.dart';
import '../home/home_page.dart';
import 'signup_page.dart';
import '../../services/custom_snackbar.dart';
import '../../views/auth/email_verify_page.dart';
import '../../services/user_service.dart';
import 'package:ecommerce/services/password_reset_dialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final uid = userCredential.user?.uid;
       await updateLastLogin(uid!);

      final User? user = userCredential.user;

      if (user == null) {
        CustomSnackbar.show(context,
          "⚠️ User not found.",
          backgroundColor: Colors.red,
        );
        return;
      }

      if (!user.emailVerified) {
        CustomSnackbar.show(
          context,
          "📧 Please verify your email before logging in.",
          backgroundColor: Colors.orange,
        );
        Get.offAll(() => const EmailVerifyPage());
        return;
      }

      final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        CustomSnackbar.show(
          context,
          "⚠️ User data not found in database.",
          backgroundColor: Colors.red,
        );
        return;
      }

      final data = doc.data()!;
      final role = data['role'] ?? 'user';
      final isSuperAdmin = data['isSuperAdmin'] ?? false;
      final isActive = data['active'] ?? true;

      // 🔹 Admin active check
      if (role == 'admin' && !isActive) {
        await FirebaseAuth.instance.signOut();
        CustomSnackbar.show(
          context,
          "⚠️ Your admin account is disabled. Contact Super Admin.",
          backgroundColor: Colors.orange,
        );
        return;
      }

      // 🔹 Navigation
      if (role == 'admin') {
        if (isSuperAdmin) {
          Get.offAll(() => const SuperAdminPage());
        } else {
          Get.offAll(() => const AdminPage());
        }
      } else {
        Get.offAll(() => const HomePage());
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = "⚠️ This email is not registered. Please create an account.";
          break;
        case 'wrong-password':
          message = "⚠️ Wrong password.";
          break;
        case 'invalid-email':
          message = "⚠️ Invalid email format.";
          break;
        case 'too-many-requests':
          message = "🚫 Too many failed attempts. Try again later.";
          break;
        default:
          message = "⚠️ This email is not registered. Please create an account.}";
      }
      CustomSnackbar.show(context, message, backgroundColor: Colors.red);
    } catch (e) {
      CustomSnackbar.show(
        context,
        "⚠️ Something went wrong: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple[100],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.lock, size: 60, color: Colors.deepPurple),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login to your account',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                      value!.isEmpty ? 'Enter your email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'Enter your password' : null,
                    ),
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          PasswordResetDialog.show(context);
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don’t have an account? "),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignupPage()),
                            );
                          },
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
