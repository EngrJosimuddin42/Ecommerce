import 'package:get/get.dart';
import '../views/auth/login_page.dart';
import '../views/auth/signup_page.dart';
import '../views/home/home_page.dart';
import '../views/cart/cart_page.dart';
import '../views/checkout/checkout_page.dart';
import '../views/order/order_success_page.dart';
import '../views/admin/admin_page.dart';

class Routes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  static const String admin = '/admin';

  static List<GetPage> pages = [
    GetPage(
      name: login,
      page: () => const LoginPage(),
    ),
    GetPage(
      name: signup,
      page: () => const SignupPage(),
    ),
    GetPage(
      name: home,
      page: () => const HomePage(),
    ),
    GetPage(
      name: cart,
      page: () => const CartPage(),
    ),
    GetPage(
      name: checkout,
      page: () => const CheckoutPage(),
    ),
    GetPage(
      name: orderSuccess,
      page: () => const OrderSuccessPage(),
    ),
    GetPage(
      name: admin,
      page: () => const AdminPage(),
    ),
  ];
}
