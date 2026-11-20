import '../../../core/database/app_database.dart';
import '../../../core/utils/formatters.dart';
import '../domain/finance_models.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  FinanceRepositoryImpl(this._db);
  final AppDatabase _db;

  @override Future<List<ServiceEntity>> getServices() async => (await (await _db.database).query('services')).map(ServiceEntity.fromMap).toList();
  @override Future<List<DueEntity>> getDues() async => (await (await _db.database).query('dues', orderBy: 'due_date ASC')).map(DueEntity.fromMap).toList();
  @override Future<List<FinancialAccountEntity>> getAccounts() async => (await (await _db.database).query('financial_accounts')).map(FinancialAccountEntity.fromMap).toList();
  @override Future<List<ExpenseEntity>> getExpenses() async => (await (await _db.database).query('expenses', orderBy: 'expense_date DESC')).map(ExpenseEntity.fromMap).toList();
  @override Future<List<Map<String, dynamic>>> getSettlements() async => (await _db.database).query('settlements', orderBy: 'id DESC');
  @override Future<List<Map<String, dynamic>>> getAuditLogs() async => (await _db.database).query('audit_logs', orderBy: 'id DESC');

  @override
  Future<List<PaymentEntity>> getPayments() async {
    final db = await _db.database;
    final rows = await db.query('payments', orderBy: 'payment_date DESC');
    final allocs = await db.query('payment_allocations');
    final sums = <String, double>{};
    for (final a in allocs) { sums[a['payment_id'] as String] = (sums[a['payment_id'] as String] ?? 0) + (a['amount'] as num).toDouble(); }
    return rows.map((r) => PaymentEntity.fromMap(r, sums[r['id']] ?? 0)).toList();
  }

  @override
  Future<void> addAccount(FinancialAccountEntity a) async {
    final db = await _db.database;
    await db.insert('financial_accounts', {
      'id': a.id,
      'name': a.name,
      'type': a.type,
      'provider': a.provider,
      'account_ref': a.accountRef,
      'currency': a.currency,
      'opening_balance': a.openingBalance,
      'status': a.status,
    });
  }

  @override
  Future<void> updateAccount(FinancialAccountEntity a) async {
    final db = await _db.database;
    await db.update('financial_accounts', {
      'name': a.name,
      'type': a.type,
      'provider': a.provider,
      'account_ref': a.accountRef,
      'currency': a.currency,
      'opening_balance': a.openingBalance,
      'status': a.status,
    }, where: 'id = ?', whereArgs: [a.id]);
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    final db = await _db.database;
    final pays = await db.query('payments', where: 'account_id = ?', whereArgs: [accountId]);
    final exps = await db.query('expenses', where: 'account_id = ?', whereArgs: [accountId]);
    if (pays.isNotEmpty || exps.isNotEmpty) {
      throw StateError('لا يمكن حذف الحساب لوجود حركات مالية مسجلة عليه');
    }
    await db.delete('financial_accounts', where: 'id = ?', whereArgs: [accountId]);
  }

  @override Future<void> addService(ServiceEntity s) async => (await _db.database).insert('services', {'id': s.id, 'unit_id': s.unitId, 'name': s.name, 'billing_type': s.billingType, 'unit_label': s.unitLabel, 'unit_rate': s.unitRate, 'fixed_amount': s.fixedAmount, 'currency': s.currency, 'prev_reading': s.prevReading});

  @override
  Future<void> updateService(ServiceEntity s) async {
    final db = await _db.database;
    await db.update('services', {
      'name': s.name,
      'billing_type': s.billingType,
      'unit_label': s.unitLabel,
      'unit_rate': s.unitRate,
      'fixed_amount': s.fixedAmount,
      'currency': s.currency,
      'prev_reading': s.prevReading,
    }, where: 'id = ?', whereArgs: [s.id]);
  }

  @override
  Future<void> deleteService(String serviceId) async {
    final db = await _db.database;
    await db.delete('services', where: 'id = ?', whereArgs: [serviceId]);
  }

  @override
  Future<void> issueFixedServiceDue(String sid) async {
    final db = await _db.database;
    await db.transaction((t) async {
      final s = ServiceEntity.fromMap((await t.query('services', where: 'id = ?', whereArgs: [sid])).first);
      final cs = await t.query('contracts', where: 'unit_id = ? AND status = ?', whereArgs: [s.unitId, 'Active']);
      if (cs.isEmpty) throw StateError('لا يوجد عقد سارٍ للوحدة');
      final c = cs.first;
      await t.insert('dues', {'id': 'D-${DateTime.now().millisecondsSinceEpoch}', 'contract_id': c['id'], 'tenant_id': c['tenant_id'], 'unit_id': s.unitId, 'due_type': 'خدمة: ${s.name}', 'period_label': 'رسم ثابت ${AppFormatters.nowTs()}', 'due_date': AppFormatters.todayIso(), 'amount': s.fixedAmount, 'paid': 0.0, 'currency': s.currency});
      await _db.addAudit(t, 'إصدار خدمة ثابتة ${s.name}');
    });
  }

  @override
  Future<void> recordMeterReading(String sid, double curr, String note) async {
    final db = await _db.database;
    await db.transaction((t) async {
      final s = ServiceEntity.fromMap((await t.query('services', where: 'id = ?', whereArgs: [sid])).first);
      if (curr < s.prevReading && note.isEmpty) throw StateError('القراءة أقل من السابقة؛ أدخل سبب التصحيح');
      final cs = await t.query('contracts', where: 'unit_id = ? AND status = ?', whereArgs: [s.unitId, 'Active']);
      if (cs.isEmpty) throw StateError('لا يوجد عقد سارٍ للوحدة');
      final c = cs.first;
      final cons = curr >= s.prevReading ? curr - s.prevReading : curr;
      final cost = cons * s.unitRate;
      await t.update('services', {'prev_reading': curr}, where: 'id = ?', whereArgs: [sid]);
      await t.insert('dues', {'id': 'D-${DateTime.now().millisecondsSinceEpoch}', 'contract_id': c['id'], 'tenant_id': c['tenant_id'], 'unit_id': s.unitId, 'due_type': 'خدمة: ${s.name}', 'period_label': 'استهلاك $cons (${AppFormatters.nowTs()})', 'due_date': AppFormatters.todayIso(), 'amount': cost, 'paid': 0.0, 'currency': s.currency});
      await _db.addAudit(t, 'قراءة عداد ${s.name}: $cost ${s.currency}');
    });
  }

  @override
  Future<void> recordPayment(String tid, double amt, String cur, String method, String accId, String ref, String mode, List<PaymentAllocationItem> allocs) async {
    final db = await _db.database;
    await db.transaction((t) async {
      if (allocs.fold<double>(0, (s, e) => s + e.amount) > amt) throw StateError('التخصيص يتجاوز مبلغ الدفعة');
      final pid = 'PAY-${DateTime.now().millisecondsSinceEpoch % 100000}';
      await t.insert('payments', {'id': pid, 'tenant_id': tid, 'payment_date': AppFormatters.todayIso(), 'amount': amt, 'currency': cur, 'method': method, 'account_id': accId, 'ref_number': ref.isEmpty ? '-' : ref, 'notes': '', 'reversed': 0});
      for (final al in allocs) {
        if (al.amount <= 0) continue;
        final d = DueEntity.fromMap((await t.query('dues', where: 'id = ?', whereArgs: [al.dueId])).first);
        if (d.currency != cur || al.amount > d.remaining + 0.001) throw StateError('تخصيص غير صالح على ${d.id}');
        await t.insert('payment_allocations', {'payment_id': pid, 'due_id': al.dueId, 'amount': al.amount, 'mode': mode});
        await t.update('dues', {'paid': d.paid + al.amount}, where: 'id = ?', whereArgs: [al.dueId]);
      }
      await _db.addAudit(t, 'تسجيل دفعة $pid ($amt $cur)');
    });
  }

  @override
  Future<void> reversePayment(String pid) async {
    final db = await _db.database;
    await db.transaction((t) async {
      await t.update('payments', {'reversed': 1}, where: 'id = ?', whereArgs: [pid]);
      for (final al in await t.query('payment_allocations', where: 'payment_id = ?', whereArgs: [pid])) {
        final dRows = await t.query('dues', where: 'id = ?', whereArgs: [al['due_id']]);
        if (dRows.isNotEmpty) {
          final next = ((dRows.first['paid'] as num).toDouble() - (al['amount'] as num).toDouble()).clamp(0.0, double.infinity);
          await t.update('dues', {'paid': next}, where: 'id = ?', whereArgs: [al['due_id']]);
        }
      }
      await _db.addAudit(t, 'عكس الدفعة $pid دون حذف السجل');
    });
  }

  @override
  Future<void> updatePayment({
    required String paymentId,
    required String paymentDate,
    required String method,
    required String accountId,
    required String refNumber,
    required String notes,
  }) async {
    final db = await _db.database;
    await db.transaction((t) async {
      await t.update(
        'payments',
        {
          'payment_date': paymentDate,
          'method': method,
          'account_id': accountId,
          'ref_number': refNumber,
          'notes': notes,
        },
        where: 'id = ?',
        whereArgs: [paymentId],
      );
      await _db.addAudit(t, 'تعديل بيانات الدفعة $paymentId');
    });
  }

  @override
  Future<void> deletePayment(String paymentId) async {
    final db = await _db.database;
    await db.transaction((t) async {
      final pRows = await t.query('payments', where: 'id = ?', whereArgs: [paymentId]);
      if (pRows.isNotEmpty && (pRows.first['reversed'] as int) == 0) {
        for (final al in await t.query('payment_allocations', where: 'payment_id = ?', whereArgs: [paymentId])) {
          final dRows = await t.query('dues', where: 'id = ?', whereArgs: [al['due_id']]);
          if (dRows.isNotEmpty) {
            final next = ((dRows.first['paid'] as num).toDouble() - (al['amount'] as num).toDouble()).clamp(0.0, double.infinity);
            await t.update('dues', {'paid': next}, where: 'id = ?', whereArgs: [al['due_id']]);
          }
        }
      }
      await t.delete('payment_allocations', where: 'payment_id = ?', whereArgs: [paymentId]);
      await t.delete('payments', where: 'id = ?', whereArgs: [paymentId]);
      await _db.addAudit(t, 'حذف دفعة: $paymentId');
    });
  }

  @override
  Future<void> addExpense(ExpenseEntity e) async {
    final db = await _db.database;
    await db.transaction((t) async {
      await t.insert('expenses', {'id': e.id, 'expense_date': e.date, 'category': e.category, 'amount': e.amount, 'currency': e.currency, 'account_id': e.accountId, 'target_label': e.targetLabel, 'bearer': e.bearer, 'notes': e.notes});
      await _db.addAudit(t, 'مصروف ${e.category}: ${e.amount} ${e.currency}');
    });
  }
  @override
  Future<void> updateExpense(ExpenseEntity e) async {
    final db = await _db.database;
    await db.transaction((t) async {
      await t.update('expenses', {
        'expense_date': e.date,
        'category': e.category,
        'amount': e.amount,
        'currency': e.currency,
        'account_id': e.accountId,
        'target_label': e.targetLabel,
        'bearer': e.bearer,
        'notes': e.notes
      }, where: 'id = ?', whereArgs: [e.id]);
      await _db.addAudit(t, 'تعديل مصروف ${e.id}: ${e.amount} ${e.currency}');
    });
  }


  @override
  Future<void> deleteExpense(String expenseId) async {
    final db = await _db.database;
    await db.transaction((t) async {
      await t.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
      await _db.addAudit(t, 'حذف مصروف: $expenseId');
    });
  }

  @override
  Future<void> reconcile(String accId, double diff) async {
    final db = await _db.database;
    await db.transaction((t) => _db.addAudit(t, 'مطابقة حساب $accId (فرق: $diff)'));
  }
}