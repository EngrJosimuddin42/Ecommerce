import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';
import '../../services/custom_snackbar.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../views/auth/email_verify_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final authController = Get.put(AuthController());
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _obscurePassword = true;
  bool isLoading = false;
  String? selectedRole = 'user';
  String? enteredCode;

  String? emailError;
  String? passwordError;

  void _validateEmail(String value) {
    if (value.contains(RegExp(r'[A-Z]'))) {
      setState(() => emailError = "❌ Email must be lowercase");
    } else if (!RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$')
        .hasMatch(value)) {
      setState(() => emailError = "❌ Invalid email format");
    } else {
      setState(() => emailError = null);
    }
  }

  void _validatePassword(String value) {
    if (value.isEmpty) {
      setState(() => passwordError = "❌ Password is required");
    } else if (value.length < 6) {
      setState(() => passwordError = "🔒 Minimum 6 characters required");
    } else if (!RegExp(r'[0-9]').hasMatch(value)) {
      setState(() => passwordError = "🔢 Must contain a number");
    } else if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      setState(() => passwordError = "🅰️ Must contain a letter");
    } else {
      setState(() => passwordError = null);
    }
  }

  // Main signup
  void _signUp() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        nameController.text.trim().isEmpty) {
      CustomSnackbar.show(
        context,
        "⚠️ Fill all fields before signup!",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (selectedRole == 'admin') {
      String adminInviteCode = '';
      try {
        final doc = await _firestore.collection('config').doc('adminConfig').get();
        adminInviteCode = doc.exists ? doc['inviteCode'] ?? "ADMIN2025" : "ADMIN2025";
      } catch (e) {
        CustomSnackbar.show(context, "❌ Failed to fetch admin invite code: $e",
            backgroundColor: Colors.red);
        return;
      }

      // Show dialog to enter invite code
      await showDialog(
        context: context,
        builder: (context) {
          TextEditingController codeController = TextEditingController();
          return AlertDialog(
            title: const Text("Admin Invite Code"),
            content: TextField(
              controller: codeController,
              decoration: const InputDecoration(hintText: "Enter admin invite code"),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => enteredCode = codeController.text.trim());
                  Navigator.of(context).pop();
                },
                child: const Text("Submit"),
              ),
            ],
          );
        },
      );

      if (enteredCode != adminInviteCode) {
        CustomSnackbar.show(
          context,
          "❌ Invalid admin invite code!",
          backgroundColor: Colors.red,
        );
        return;
      }
    }

    _continueSignUp();
  }

  void _continueSignUp() async {
    _validateEmail(emailController.text);
    _validatePassword(passwordController.text);
    if (emailError != null || passwordError != null) return;

    setState(() => isLoading = true);

    try {
      // 🔹 Create Firebase user
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User user = userCredential.user!; // <-- UserCredential.user

      // 🔹 Determine role
      bool isSuperAdmin = false;
      String role = 'user';

      final adminSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      if (adminSnapshot.docs.isEmpty) {
        isSuperAdmin = true;
        role = 'admin';
      } else if (selectedRole == 'admin' && enteredCode != null) {
        role = 'admin';
      }

      // 🔹 Save user data
      await _firestore.collection('users').doc(user.uid).set({
        'name': nameController.text.trim(),
        'email': user.email,
        'role': role,
        'isSuperAdmin': isSuperAdmin,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔹 Send email verification
      await user.sendEmailVerification(
        ActionCodeSettings(
          url: 'https://ecommerce-4e22f.firebaseapp.com/__/auth/action',
          handleCodeInApp: true,
          iOSBundleId: 'com.josim.ecommerce.ecommerce',
          androidPackageName: 'com.josim.ecommerce.ecommerce',
          androidInstallApp: true,
          androidMinimumVersion: '21',
        ),
      );

      CustomSnackbar.show(context,
        "📩 Verification link sent! Check your inbox or spam.",
        backgroundColor: Colors.green,
      );

      // 🔹 Navigate to EmailVerifyScreen
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const EmailVerifyPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email already in use.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        default:
          message = e.message ?? 'An error occurred.';
      }
      CustomSnackbar.show(context, "❌ Signup failed: $message",
          backgroundColor: Colors.red);
    } catch (e) {
      CustomSnackbar.show(context, "❌ Signup failed: ${e.toString()}",
          backgroundColor: Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Create Your Account',
          style:
          TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Name
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            // Email
            TextField(
              controller: emailController,
              onChanged: _validateEmail,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                errorText: emailError,
              ),
            ),
            const SizedBox(height: 15),
            // Password
            TextField(
              controller: passwordController,
              onChanged: _validatePassword,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                errorText: passwordError,
              ),
            ),
            const SizedBox(height: 15),

            // Role selection with DropdownButton2
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 400,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    value: selectedRole,
                    hint: const Text("Select Role"),
                    items: ["User", "Admin"]
                        .map((role) => DropdownMenuItem<String>(
                      value: role.toLowerCase(),
                      child: Text(role),
                    ))
                        .toList(),
                    onChanged: (val) => setState(() => selectedRole = val),
                    dropdownStyleData: DropdownStyleData(
                      width: 190,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 4,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      offset: const Offset(200, 0),
                      elevation: 4,
                    ),
                    buttonStyleData: ButtonStyleData(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.white,
                      ),
                    ),
                    iconStyleData: const IconStyleData(
                      icon: Icon(Icons.arrow_drop_down, color: Colors.indigo),
                      iconSize: 30,
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),
            // Sign Up Button
            isLoading
                ? const CircularProgressIndicator(color: Colors.deepPurple)
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sign Up',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 15),
            // Login navigation
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Already have an account? Log In",
                style:
                TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
