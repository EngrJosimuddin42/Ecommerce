import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/cart_controller.dart';
import 'views/auth/login_page.dart';
import 'views/home/home_page.dart';
import 'views/admin/admin_page.dart';
import 'views/admin/super_admin_page.dart';
import 'views/auth/email_verify_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // ✅ Controller inject before runApp
  Get.put(AuthController(), permanent: true);
  Get.put(CartController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      // 🧠 AuthController এর firebaseUser Reactive stream দেখবে
      final user = authController.firebaseUser.value;

      Widget homePage;

      if (user == null) {
        homePage = const LoginPage();
      } else if (!user.emailVerified) {
        homePage = const EmailVerifyPage();
      } else {
        homePage = FutureBuilder<Map<String, dynamic>?>(
          future: _getUserRole(authController),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final data = snapshot.data;
            if (data == null) return const LoginPage();

            final role = data['role'];
            final isSuperAdmin = data['isSuperAdmin'] ?? false;

            if (role == 'admin') {
              if (isSuperAdmin) return const SuperAdminPage();
              return const AdminPage();
            } else {
              return const HomePage();
            }
          },
        );
      }

      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'E-commerce App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: homePage,
      );
    });
  }

  Future<Map<String, dynamic>?> _getUserRole(AuthController authController) async {
    try {
      final user = authController.firebaseUser.value;
      if (user == null) return null;
      final doc = await authController
          .firestore
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.data();
    } catch (e) {
      print("⚠️ Error getting user role: $e");
      return null;
    }
  }
}
