import 'package:get/get.dart';

import 'controller.dart';

class SetWifiBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReactiveBleController>(() => ReactiveBleController());
  }
}
