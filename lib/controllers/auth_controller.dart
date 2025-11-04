import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../views/home/home_page.dart';
import '../views/admin/admin_page.dart';
import '../views/admin/super_admin_page.dart';
import '../views/auth/login_page.dart';
import '../views/auth/email_verify_page.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;
  Rxn<User> firebaseUser = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    print("🔹 AuthController initialized. Listening to auth state changes.");
  }

  User? get currentUser => _auth.currentUser;

  /// 🔹 SIGN UP
  Future<void> signUp(String email, String password,
      {String? inviteCode, String? name}) async {
    try {
      print("🔹 Starting signup for $email");

      final adminSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      bool isSuperAdmin = false;
      String role = 'user';

      if (adminSnapshot.docs.isEmpty) {
        isSuperAdmin = true;
        role = 'admin';
        print("🔹 No existing admin → this user will be Super Admin");
      } else {
        final configDoc = await _firestore.collection('config').doc('adminConfig').get();
        final validCode = configDoc.exists ? configDoc['inviteCode'] : "ADMIN2025";

        if (inviteCode != null && inviteCode == validCode) {
          role = 'admin';
        } else {
          role = 'user';
        }
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) throw Exception("User creation failed");

      await _firestore.collection('users').doc(user.uid).set({
        'name': name ?? email.split('@')[0],
        'email': email,
        'role': role,
        'isSuperAdmin': isSuperAdmin,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

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

      Get.snackbar('✅ Success', 'Account created! Check your email for verification link.');
      Get.offAll(() => const EmailVerifyPage());
    } catch (e) {
      print("❌ Error: $e");
      Get.snackbar('Signup Error', e.toString());
    }
  }

  /// 🔹 LOGIN
  Future<void> login(String email, String password) async {
    try {
      UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) throw Exception("User not found");

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception("User data not found");

      final data = userDoc.data() as Map<String, dynamic>;
      String role = data['role'] ?? 'user';
      bool isSuperAdmin = data['isSuperAdmin'] ?? false;
      bool isActive = data.containsKey('active') ? (data['active'] == true) : true;

      if (!user.emailVerified) {
        Get.snackbar('Email Verification', 'Please verify your email.');
        Get.offAll(() => const EmailVerifyPage());
        return;
      }

      // ✅ Block login if admin is inactive
      if (role == 'admin' && !isActive) {
        await _auth.signOut();
        Get.snackbar(
          'Access Denied',
          'Your admin account is disabled. Contact Super Admin.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
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
    } catch (e) {
      print("❌ Login Error: $e");
      Get.snackbar('Login Error', e.toString());
    }
  }

  /// 🔹 LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    Get.offAll(() => const LoginPage());
  }

  /// 🔹 Check if Super Admin
  Future<bool> isCurrentUserSuperAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>;
    return data['isSuperAdmin'] ?? false;
  }
}
