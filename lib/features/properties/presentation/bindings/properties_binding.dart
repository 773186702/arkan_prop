import 'package:get/get.dart';
import '../../../../core/database/app_database.dart';
import '../../data/property_repository_impl.dart';
import '../../domain/property_models.dart';
import '../controllers/properties_controller.dart';

class PropertiesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PropertyRepository>(() => PropertyRepositoryImpl(AppDatabase.instance), fenix: true);
    Get.lazyPut(() => PropertiesController(Get.find<PropertyRepository>()), fenix: true);
  }
}