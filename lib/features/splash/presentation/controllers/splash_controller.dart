import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_settings_controller.dart';
import '../../../../routes/app_routes.dart';
import '../../../pin/domain/pin_repository.dart';
import '../../../pin/presentation/controllers/pin_controller.dart';

class SplashController extends GetxController {
  SplashController(this._settings, this._pinRepo);
  final AppSettingsController _settings;
  final PinRepository _pinRepo;

  @override
  void onReady() {
    super.onReady();
    _init();
  }

  Future<void> _init() async {
    await _settings.load();
    await AppDatabase.instance.database;
    if (!await _pinRepo.hasPin()) {
      await _pinRepo.savePin(AppConstants.defaultPin);
    }
    await Future<void>.delayed(const Duration(milliseconds: 800));
    Get.offAllNamed(AppRoutes.pin, arguments: PinMode.verify);
  }
}