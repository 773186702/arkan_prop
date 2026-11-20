import 'package:get/get.dart';
import '../../../contracts/presentation/bindings/contracts_binding.dart';
import '../../../finance/presentation/bindings/finance_binding.dart';
import '../../../properties/presentation/bindings/properties_binding.dart';
import '../../../reports/presentation/bindings/reports_binding.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    PropertiesBinding().dependencies();
    ContractsBinding().dependencies();
    FinanceBinding().dependencies();
    ReportsBinding().dependencies();
    Get.put(HomeController());
  }
}