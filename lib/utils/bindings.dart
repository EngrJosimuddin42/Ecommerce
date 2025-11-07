import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // AuthController app launch এ inject হবে
    Get.put<AuthController>(AuthController(), permanent: true);

    // CartController app launch এ inject হবে এবং সব সময় জীবিত থাকবে 🧩
    Get.put<CartController>(CartController(), permanent: true);
  }
}
