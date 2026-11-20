import 'package:get/get.dart';
import '../../../../core/utils/local_notification_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';
import '../../../properties/presentation/controllers/properties_controller.dart';
import '../../domain/contract_models.dart';

class ContractsController extends GetxController {
  ContractsController(this._repo);
  final ContractRepository _repo;
  final subTab = 0.obs;
  final tenantSearch = ''.obs;
  final tenants = <TenantEntity>[].obs;
  final templates = <ContractTemplateEntity>[].obs;
  final contracts = <ContractEntity>[].obs;

  @override
  void onInit() { super.onInit(); loadAll(); }

  Future<void> loadAll() async {
    tenants.assignAll(await _repo.getTenants());
    templates.assignAll(await _repo.getTemplates());
    contracts.assignAll(await _repo.getContracts());
    await scheduleContractNotifications();
  }

  Future<void> scheduleContractNotifications() async {
    try {
      await LocalNotificationService.syncAndScheduleContracts(contracts, tenants);
    } catch (_) {}
  }

  TenantEntity? tenantById(String id) => tenants.firstWhereOrNull((t) => t.id == id);
  ContractEntity? contractById(String id) => contracts.firstWhereOrNull((c) => c.id == id);
  ContractEntity? activeContractForUnit(String uid) => contracts.firstWhereOrNull((c) => c.unitId == uid && c.status == 'Active');
  ContractEntity? activeContractForTenant(String tid) => contracts.firstWhereOrNull((c) => c.tenantId == tid && c.status == 'Active');

  List<TenantEntity> get filteredTenants {
    final q = tenantSearch.value.trim().toLowerCase();
    return q.isEmpty ? tenants : tenants.where((t) => t.name.toLowerCase().contains(q) || t.phone.contains(q) || t.idNum.contains(q)).toList();
  }

  Future<void> saveTenant(TenantEntity t) async { await _repo.upsertTenant(t); await loadAll(); }
  Future<void> deleteTenant(String tid) async {
    try {
      await _repo.deleteTenant(tid);
      await loadAll();
    } catch (e) {
      Get.snackbar('خطأ', e.toString());
    }
  }

  Future<String?> createContract({required String unitId, required String tenantId, required String startDate, required String endDate, required double rent, required String currency, required String frequency, required double deposit, required String templateId, required List<ContractWitness> witnesses}) async {
    if (endDate.compareTo(startDate) <= 0) return 'تاريخ الانتهاء يجب أن يلي السريان';
    try {
      final tpl = templates.firstWhere((e) => e.id == templateId);
      final id = 'C-${DateTime.now().year}-${contracts.length + 1}';
      await _repo.createContract(ContractEntity(id: id, unitId: unitId, tenantId: tenantId, createdDate: AppFormatters.todayIso(), startDate: startDate, endDate: endDate, rent: rent, currency: currency, frequency: frequency, customInterval: '', deposit: deposit, graceDays: 5, status: 'Active', prevContractId: null, increasePct: 0, witnesses: witnesses, terms: List<String>.from(tpl.terms)));
      await loadAll();
      await Get.find<PropertiesController>().loadAll();
      await Get.find<FinanceController>().loadAll();
      return null;
    } catch (e) { return e.toString(); }
  }

  Future<void> addCustomTerm(String cid, String term) async { await _repo.addCustomTerm(cid, term); await loadAll(); }
  Future<void> generateNextDue(String cid) async { await _repo.generateNextDue(cid); await Get.find<FinanceController>().loadAll(); }

  Future<void> renew(ContractEntity oldC, String start, String end, double rent, double pct) async {
    await _repo.renewContract(oldC, 'C-${DateTime.now().year}-${contracts.length + 1}', start, end, rent, pct);
    await loadAll();
    await Get.find<FinanceController>().loadAll();
  }

  Future<void> terminate(String cid, String type, double amt, String notes) async {
    await _repo.terminateContract(cid, type, amt, notes);
    await loadAll();
    await Get.find<PropertiesController>().loadAll();
    await Get.find<FinanceController>().loadAll();
  }
  Future<void> updateContract(ContractEntity c) async {
    await _repo.updateContract(c);
    await loadAll();
    await Get.find<PropertiesController>().loadAll();
    await Get.find<FinanceController>().loadAll();
  }

}