import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../../data/pin_repository_impl.dart';
import '../../domain/pin_repository.dart';
import '../controllers/pin_controller.dart';

class PinBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PinRepository>(() => PinRepositoryImpl(Get.find<FlutterSecureStorage>()));
    Get.put(PinController(Get.find<PinRepository>()));
  }
}