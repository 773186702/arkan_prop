import 'package:get/get.dart';
import '../../../../core/utils/local_notification_service.dart';
import '../../../contracts/presentation/controllers/contracts_controller.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';

class HomeController extends GetxController {
  final currentIndex = 0.obs;
  void setTab(int idx) => currentIndex.value = idx;

  @override
  void onReady() {
    super.onReady();
    _triggerAlerts();
  }

  Future<void> _triggerAlerts() async {
    try {
      final cCtrl = Get.find<ContractsController>();
      final fCtrl = Get.find<FinanceController>();
      await LocalNotificationService.checkAndDispatchAllAlerts(
        contracts: cCtrl.contracts,
        dues: fCtrl.dues,
        tenants: cCtrl.tenants,
      );
    } catch (_) {}
  }
}
