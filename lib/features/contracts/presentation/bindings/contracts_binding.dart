import 'package:get/get.dart';
import '../../../../core/database/app_database.dart';
import '../../data/contract_repository_impl.dart';
import '../../domain/contract_models.dart';
import '../controllers/contracts_controller.dart';

class ContractsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ContractRepository>(() => ContractRepositoryImpl(AppDatabase.instance), fenix: true);
    Get.lazyPut(() => ContractsController(Get.find<ContractRepository>()), fenix: true);
  }
}