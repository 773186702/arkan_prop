import 'package:get/get.dart';
import '../../../../core/database/app_database.dart';
import '../../data/finance_repository_impl.dart';
import '../../domain/finance_models.dart';
import '../controllers/finance_controller.dart';

class FinanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FinanceRepository>(() => FinanceRepositoryImpl(AppDatabase.instance), fenix: true);
    Get.lazyPut(() => FinanceController(Get.find<FinanceRepository>()), fenix: true);
  }
}