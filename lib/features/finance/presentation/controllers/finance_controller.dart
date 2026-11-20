import 'package:get/get.dart';
import '../../../../core/utils/local_notification_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../contracts/presentation/controllers/contracts_controller.dart';
import '../../domain/finance_models.dart';

class CurrencySummary {
  const CurrencySummary({required this.currency, required this.collected, required this.pending, required this.expenses, required this.net, required this.rate});
  final String currency; final double collected, pending, expenses, net; final int rate;
}

class FinanceController extends GetxController {
  FinanceController(this._repo);
  final FinanceRepository _repo;
  final subTab = 0.obs;
  final services = <ServiceEntity>[].obs;
  final dues = <DueEntity>[].obs;
  final accounts = <FinancialAccountEntity>[].obs;
  final payments = <PaymentEntity>[].obs;
  final expenses = <ExpenseEntity>[].obs;
  final settlements = <Map<String, dynamic>>[].obs;
  final auditLogs = <Map<String, dynamic>>[].obs;

  @override
  void onInit() { super.onInit(); loadAll(); }

  Future<void> loadAll() async {
    services.assignAll(await _repo.getServices());
    dues.assignAll(await _repo.getDues());
    accounts.assignAll(await _repo.getAccounts());

    // ضمان وجود الصناديق النقدية المستقلة لكل عملة (يمني، سعودي، دولار)
    final hasYerCash = accounts.any((a) => a.currency == 'YER' && a.type == 'Cash');
    final hasSarCash = accounts.any((a) => a.currency == 'SAR' && a.type == 'Cash');
    final hasUsdCash = accounts.any((a) => a.currency == 'USD' && a.type == 'Cash');

    if (!hasYerCash) {
      await _repo.addAccount(const FinancialAccountEntity(
        id: 'FA_YER_CASH',
        name: 'صندوق الريال اليمني (نقداً)',
        type: 'Cash',
        provider: 'خزنة المكتب',
        accountRef: 'BOX-YER',
        currency: 'YER',
        openingBalance: 0,
        status: 'نشط',
      ));
    }
    if (!hasSarCash) {
      await _repo.addAccount(const FinancialAccountEntity(
        id: 'FA_SAR_CASH',
        name: 'صندوق الريال السعودي (نقداً)',
        type: 'Cash',
        provider: 'خزنة المكتب',
        accountRef: 'BOX-SAR',
        currency: 'SAR',
        openingBalance: 0,
        status: 'نشط',
      ));
    }
    if (!hasUsdCash) {
      await _repo.addAccount(const FinancialAccountEntity(
        id: 'FA_USD_CASH',
        name: 'صندوق الدولار الأمريكي (نقداً)',
        type: 'Cash',
        provider: 'خزنة المكتب',
        accountRef: 'BOX-USD',
        currency: 'USD',
        openingBalance: 0,
        status: 'نشط',
      ));
    }

    if (!hasYerCash || !hasSarCash || !hasUsdCash) {
      accounts.assignAll(await _repo.getAccounts());
    }

    payments.assignAll(await _repo.getPayments());
    expenses.assignAll(await _repo.getExpenses());
    settlements.assignAll(await _repo.getSettlements());
    auditLogs.assignAll(await _repo.getAuditLogs());
    
    await scheduleDueNotifications();
  }

  Future<void> scheduleDueNotifications() async {
    try {
      final cCtrl = Get.isRegistered<ContractsController>() ? Get.find<ContractsController>() : null;
      await LocalNotificationService.syncAndScheduleDues(dues, cCtrl?.tenants ?? []);
    } catch (_) {}
  }

  List<ServiceEntity> servicesForUnit(String uid) => services.where((s) => s.unitId == uid).toList();
  List<DueEntity> get overdueDues => dues.where((d) => d.remaining > 0 && AppFormatters.daysLate(d.dueDate) > 0).toList();

  double accountBalance(FinancialAccountEntity a) => a.openingBalance +
      payments.where((p) => !p.reversed && p.accountId == a.id).fold<double>(0, (s, p) => s + p.amount) -
      expenses.where((e) => e.accountId == a.id).fold<double>(0, (s, e) => s + e.amount);

  double tenantAdvanceCredit(String tid, String cur) => payments
      .where((p) => !p.reversed && p.tenantId == tid && p.currency == cur)
      .fold<double>(0, (s, p) => s + (p.amount - p.allocatedTotal).clamp(0, p.amount));

  CurrencySummary summaryForCurrency(String cur) {
    final col = payments.where((p) => !p.reversed && p.currency == cur).fold<double>(0, (s, p) => s + p.amount);
    final tot = dues.where((d) => d.currency == cur).fold<double>(0, (s, d) => s + d.amount);
    final pen = dues.where((d) => d.currency == cur).fold<double>(0, (s, d) => s + d.remaining);
    final exp = expenses.where((e) => e.currency == cur).fold<double>(0, (s, e) => s + e.amount);
    return CurrencySummary(currency: cur, collected: col, pending: pen, expenses: exp, net: col - exp, rate: tot > 0 ? (((tot - pen) / tot) * 100).round() : 100);
  }

  List<PaymentAllocationItem> computeAutoPlan(String tid, String cur, double amt) {
    var rem = amt;
    final list = dues.where((d) => d.tenantId == tid && d.currency == cur && d.remaining > 0).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final plan = <PaymentAllocationItem>[];
    for (final d in list) { if (rem <= 0) break; final take = rem < d.remaining ? rem : d.remaining; plan.add(PaymentAllocationItem(dueId: d.id, amount: take)); rem -= take; }
    return plan;
  }

  Future<void> addService(String uid, String name, String bt, double val, String cur) async {
    await _repo.addService(ServiceEntity(id: 'SV${DateTime.now().millisecondsSinceEpoch}', unitId: uid, name: name, billingType: bt, unitLabel: bt == 'Fixed' ? 'دوري' : 'وحدة', unitRate: bt == 'Usage-Based' ? val : 0, fixedAmount: bt == 'Fixed' ? val : 0, currency: cur, prevReading: 0));
    await loadAll();
  }

  Future<String?> updateService(ServiceEntity s) async {
    try {
      await _repo.updateService(s);
      await loadAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteService(String serviceId) async {
    try {
      await _repo.deleteService(serviceId);
      await loadAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> issueFixedServiceDue(String sid) async { try { await _repo.issueFixedServiceDue(sid); await loadAll(); return null; } catch (e) { return e.toString(); } }
  Future<String?> recordMeterReading(String sid, double curr, String note) async { try { await _repo.recordMeterReading(sid, curr, note); await loadAll(); return null; } catch (e) { return e.toString(); } }
  Future<String?> savePayment(String tid, double amt, String cur, String method, String accId, String ref, String mode, List<PaymentAllocationItem> allocs) async {
    try { await _repo.recordPayment(tid, amt, cur, method, accId, ref, mode, allocs); await loadAll(); return null; } catch (e) { return e.toString(); }
  }
  Future<void> reversePayment(String pid) async {
    await _repo.reversePayment(pid);
    await loadAll();
  }

  Future<String?> updatePayment({
    required String paymentId,
    required String paymentDate,
    required String method,
    required String accountId,
    required String refNumber,
    required String notes,
  }) async {
    try {
      await _repo.updatePayment(
        paymentId: paymentId,
        paymentDate: paymentDate,
        method: method,
        accountId: accountId,
        refNumber: refNumber,
        notes: notes,
      );
      await loadAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deletePayment(String pid) async {
    try {
      await _repo.deletePayment(pid);
      await loadAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> addExpense(String cat, double amt, String cur, String accId, String tgt, String bearer, String notes) async {
    await _repo.addExpense(ExpenseEntity(id: 'EX-${DateTime.now().millisecondsSinceEpoch % 10000}', date: AppFormatters.todayIso(), category: cat, amount: amt, currency: cur, accountId: accId, targetLabel: tgt, bearer: bearer, notes: notes));
    await loadAll();
  }

  Future<void> reconcileAccount(String accId, double diff) async { await _repo.reconcile(accId, diff); await loadAll(); }

  Future<String?> updateExpense(ExpenseEntity e) async {
    try {
      await _repo.updateExpense(e);
      await loadAll();
      return null;
    } catch (err) {
      return err.toString();
    }
  }

  Future<String?> addAccount(FinancialAccountEntity a) async {
    try {
      await _repo.addAccount(a);
      await loadAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateAccount(FinancialAccountEntity a) async {
    try {
      await _repo.updateAccount(a);
      await loadAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteAccount(String accountId) async {
    try {
      await _repo.deleteAccount(accountId);
      await loadAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteExpense(String expenseId) async {
    try {
      await _repo.deleteExpense(expenseId);
      await loadAll();
      return null;
    } catch (err) {
      return err.toString();
    }
  }

}