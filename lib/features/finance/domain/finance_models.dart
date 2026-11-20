class ServiceEntity {
  const ServiceEntity({required this.id, required this.unitId, required this.name, required this.billingType, required this.unitLabel, required this.unitRate, required this.fixedAmount, required this.currency, required this.prevReading});
  final String id, unitId, name, billingType, unitLabel, currency;
  final double unitRate, fixedAmount, prevReading;
  factory ServiceEntity.fromMap(Map<String, dynamic> m) => ServiceEntity(id: m['id'] as String, unitId: m['unit_id'] as String, name: m['name'] as String, billingType: m['billing_type'] as String, unitLabel: m['unit_label'] as String, unitRate: (m['unit_rate'] as num).toDouble(), fixedAmount: (m['fixed_amount'] as num).toDouble(), currency: m['currency'] as String, prevReading: (m['prev_reading'] as num).toDouble());
}

class DueEntity {
  const DueEntity({required this.id, required this.contractId, required this.tenantId, required this.unitId, required this.dueType, required this.periodLabel, required this.dueDate, required this.amount, required this.paid, required this.currency});
  final String id, contractId, tenantId, unitId, dueType, periodLabel, dueDate, currency;
  final double amount, paid;
  double get remaining => (amount - paid) > 0 ? (amount - paid) : 0;
  String get status {
    if (remaining <= 0) return 'مسدد';
    if (paid > 0) return 'مسدد جزئياً';
    final now = DateTime.now();
    final d = DateTime.tryParse(dueDate);
    if (d != null && d.isBefore(now)) return 'متأخر';
    return 'مستحق';
  }
  factory DueEntity.fromMap(Map<String, dynamic> m) => DueEntity(id: m['id'] as String, contractId: m['contract_id'] as String, tenantId: m['tenant_id'] as String, unitId: m['unit_id'] as String, dueType: m['due_type'] as String, periodLabel: m['period_label'] as String, dueDate: m['due_date'] as String, amount: (m['amount'] as num).toDouble(), paid: (m['paid'] as num).toDouble(), currency: m['currency'] as String);
}

class FinancialAccountEntity {
  const FinancialAccountEntity({required this.id, required this.name, required this.type, required this.provider, required this.accountRef, required this.currency, required this.openingBalance, required this.status});
  final String id, name, type, provider, accountRef, currency, status;
  final double openingBalance;
  factory FinancialAccountEntity.fromMap(Map<String, dynamic> m) => FinancialAccountEntity(id: m['id'] as String, name: m['name'] as String, type: m['type'] as String, provider: m['provider'] as String, accountRef: m['account_ref'] as String, currency: m['currency'] as String, openingBalance: (m['opening_balance'] as num).toDouble(), status: m['status'] as String);
}

class PaymentAllocationItem {
  const PaymentAllocationItem({required this.dueId, required this.amount});
  final String dueId; final double amount;
}

class PaymentEntity {
  const PaymentEntity({required this.id, required this.tenantId, required this.paymentDate, required this.amount, required this.currency, required this.method, required this.accountId, required this.refNumber, required this.notes, required this.reversed, required this.allocatedTotal});
  final String id, tenantId, paymentDate, currency, method, accountId, refNumber, notes;
  final double amount, allocatedTotal;
  final bool reversed;
  factory PaymentEntity.fromMap(Map<String, dynamic> m, double alloc) => PaymentEntity(id: m['id'] as String, tenantId: m['tenant_id'] as String, paymentDate: m['payment_date'] as String, amount: (m['amount'] as num).toDouble(), currency: m['currency'] as String, method: m['method'] as String, accountId: m['account_id'] as String, refNumber: m['ref_number'] as String, notes: m['notes'] as String, reversed: (m['reversed'] as int) == 1, allocatedTotal: alloc);
}

class ExpenseEntity {
  const ExpenseEntity({required this.id, required this.date, required this.category, required this.amount, required this.currency, required this.accountId, required this.targetLabel, required this.bearer, required this.notes});
  final String id, date, category, currency, accountId, targetLabel, bearer, notes;
  final double amount;
  factory ExpenseEntity.fromMap(Map<String, dynamic> m) => ExpenseEntity(id: m['id'] as String, date: m['expense_date'] as String, category: m['category'] as String, amount: (m['amount'] as num).toDouble(), currency: m['currency'] as String, accountId: m['account_id'] as String, targetLabel: m['target_label'] as String, bearer: m['bearer'] as String, notes: m['notes'] as String);
}

abstract interface class FinanceRepository {
  Future<List<ServiceEntity>> getServices();
  Future<List<DueEntity>> getDues();
  Future<List<FinancialAccountEntity>> getAccounts();
  Future<List<PaymentEntity>> getPayments();
  Future<List<ExpenseEntity>> getExpenses();
  Future<List<Map<String, dynamic>>> getSettlements();
  Future<List<Map<String, dynamic>>> getAuditLogs();
  Future<void> addAccount(FinancialAccountEntity a);
  Future<void> updateAccount(FinancialAccountEntity a);
  Future<void> deleteAccount(String accountId);
  Future<void> addService(ServiceEntity s);
  Future<void> updateService(ServiceEntity s);
  Future<void> deleteService(String serviceId);
  Future<void> issueFixedServiceDue(String sid);
  Future<void> recordMeterReading(String sid, double curr, String note);
  Future<void> recordPayment(String tid, double amt, String cur, String method, String accId, String ref, String mode, List<PaymentAllocationItem> allocs);
  Future<void> reversePayment(String pid);
  Future<void> updatePayment({required String paymentId, required String paymentDate, required String method, required String accountId, required String refNumber, required String notes});
  Future<void> deletePayment(String paymentId);
  Future<void> addExpense(ExpenseEntity e);
  Future<void> updateExpense(ExpenseEntity e);
  Future<void> deleteExpense(String expenseId);
  Future<void> reconcile(String accId, double diff);
}