import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_settings_controller.dart';
import '../../../pin/data/pin_repository_impl.dart';
import '../../../pin/domain/pin_repository.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PinRepository>(() => PinRepositoryImpl(Get.find<FlutterSecureStorage>()));
    Get.put(SplashController(Get.find<AppSettingsController>(), Get.find<PinRepository>()));
  }
}