import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // AuthController app launch এ inject হবে
    Get.lazyPut<AuthController>(() => AuthController());

    // CartController app launch এ inject হবে
    Get.lazyPut<CartController>(() => CartController());
  }
}
