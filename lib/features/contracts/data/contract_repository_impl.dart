import 'dart:convert';
import '../../../core/database/app_database.dart';
import '../../../core/utils/formatters.dart';
import '../domain/contract_models.dart';

class ContractRepositoryImpl implements ContractRepository {
  ContractRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<TenantEntity>> getTenants() async => (await (await _db.database).query('tenants')).map(TenantEntity.fromMap).toList();

  @override
  @override
  Future<void> deleteTenant(String tid) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final contracts = await txn.query('contracts', where: 'tenant_id = ?', whereArgs: [tid]);
      if (contracts.isNotEmpty) throw StateError('لا يمكن حذف مستأجر لديه عقود مرتبطة');
      await txn.delete('tenants', where: 'id = ?', whereArgs: [tid]);
      await _db.addAudit(txn, 'حذف مستأجر: $tid');
    });
  }

  @override
  Future<void> deleteContract(String cid) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final c = await txn.query('contracts', where: 'id = ?', whereArgs: [cid]);
      if (c.isEmpty) return;
      if (c.first['status'] == 'Active') throw StateError('لا يمكن حذف عقد نشط');
      await txn.delete('dues', where: 'contract_id = ?', whereArgs: [cid]);
      await txn.delete('contracts', where: 'id = ?', whereArgs: [cid]);
      await _db.addAudit(txn, 'حذف عقد: $cid');
    });
  }

  @override
  Future<List<ContractTemplateEntity>> getTemplates() async => (await (await _db.database).query('contract_templates')).map(ContractTemplateEntity.fromMap).toList();
  @override
  Future<List<ContractEntity>> getContracts() async => (await (await _db.database).query('contracts', orderBy: 'created_date DESC')).map(ContractEntity.fromMap).toList();

  @override
  Future<void> upsertTenant(TenantEntity t) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final ex = await txn.query('tenants', where: 'id = ?', whereArgs: [t.id]);
      final row = {'id': t.id, 'name': t.name, 'type': t.type, 'phone': t.phone, 'alt_phone': t.altPhone, 'id_num': t.idNum, 'address': t.address, 'email': t.email, 'notes': t.notes, 'status': t.status};
      if (ex.isEmpty) { await txn.insert('tenants', row); await _db.addAudit(txn, 'إضافة مستأجر: ${t.name}'); }
      else { await txn.update('tenants', row, where: 'id = ?', whereArgs: [t.id]); await _db.addAudit(txn, 'تعديل مستأجر: ${t.name}'); }
    });
  }

  @override
  Future<void> createContract(ContractEntity c) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final conf = await txn.query('contracts', where: 'unit_id = ? AND status = ?', whereArgs: [c.unitId, 'Active']);
      if (conf.isNotEmpty) throw StateError('تعارض: يوجد عقد نشط على هذه الوحدة');
      await txn.insert('contracts', {'id': c.id, 'unit_id': c.unitId, 'tenant_id': c.tenantId, 'created_date': c.createdDate, 'start_date': c.startDate, 'end_date': c.endDate, 'rent': c.rent, 'currency': c.currency, 'frequency': c.frequency, 'custom_interval': c.customInterval, 'deposit': c.deposit, 'grace_days': c.graceDays, 'status': c.status, 'prev_contract_id': c.prevContractId, 'increase_pct': c.increasePct, 'witnesses_json': jsonEncode(c.witnesses.map((w) => w.toMap()).toList()), 'terms_json': jsonEncode(c.terms)});
      await txn.update('units', {'status': 'Rented'}, where: 'id = ?', whereArgs: [c.unitId]);
      await txn.insert('unit_status_history', {'unit_id': c.unitId, 'changed_at': AppFormatters.todayIso(), 'from_status': 'Available', 'to_status': 'Rented', 'reason': 'اعتماد العقد ${c.id}'});
      await txn.insert('dues', {'id': 'D-${DateTime.now().millisecondsSinceEpoch}', 'contract_id': c.id, 'tenant_id': c.tenantId, 'unit_id': c.unitId, 'due_type': 'إيجار', 'period_label': 'القسط 1 (تاريخ السريان)', 'due_date': c.startDate, 'amount': c.rent, 'paid': 0.0, 'currency': c.currency});
      await _db.addAudit(txn, 'اعتماد عقد ${c.id} (سريان ${c.startDate})');
    });
  }

  @override
  Future<void> addCustomTerm(String cid, String term) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final r = (await txn.query('contracts', where: 'id = ?', whereArgs: [cid])).first;
      final list = (jsonDecode(r['terms_json'] as String) as List).map((e) => e.toString()).toList()..add(term);
      await txn.update('contracts', {'terms_json': jsonEncode(list)}, where: 'id = ?', whereArgs: [cid]);
      await _db.addAudit(txn, 'إضافة شرط خاص للعقد $cid');
    });
  }

  @override
  Future<void> generateNextDue(String cid) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final c = ContractEntity.fromMap((await txn.query('contracts', where: 'id = ?', whereArgs: [cid])).first);
      final n = (await txn.query('dues', where: 'contract_id = ? AND due_type = ?', whereArgs: [cid, 'إيجار'])).length + 1;
      await txn.insert('dues', {'id': 'D-${DateTime.now().millisecondsSinceEpoch}', 'contract_id': c.id, 'tenant_id': c.tenantId, 'unit_id': c.unitId, 'due_type': 'إيجار', 'period_label': 'القسط $n', 'due_date': AppFormatters.todayIso(), 'amount': c.rent, 'paid': 0.0, 'currency': c.currency});
      await _db.addAudit(txn, 'توليد القسط $n للعقد $cid');
    });
  }

  @override
  Future<void> renewContract(ContractEntity oldC, String newId, String start, String end, double newRent, double pct) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update('contracts', {'status': 'Expired'}, where: 'id = ?', whereArgs: [oldC.id]);
      await txn.insert('contracts', {'id': newId, 'unit_id': oldC.unitId, 'tenant_id': oldC.tenantId, 'created_date': AppFormatters.todayIso(), 'start_date': start, 'end_date': end, 'rent': newRent, 'currency': oldC.currency, 'frequency': oldC.frequency, 'custom_interval': oldC.customInterval, 'deposit': oldC.deposit, 'grace_days': oldC.graceDays, 'status': 'Active', 'prev_contract_id': oldC.id, 'increase_pct': pct, 'witnesses_json': jsonEncode(oldC.witnesses.map((w) => w.toMap()).toList()), 'terms_json': jsonEncode(oldC.terms)});
      await txn.insert('dues', {'id': 'D-${DateTime.now().millisecondsSinceEpoch}', 'contract_id': newId, 'tenant_id': oldC.tenantId, 'unit_id': oldC.unitId, 'due_type': 'إيجار', 'period_label': 'القسط 1 (تجديد)', 'due_date': start, 'amount': newRent, 'paid': 0.0, 'currency': oldC.currency});
      await _db.addAudit(txn, 'تجديد ${oldC.id} بالعقد $newId (زيادة $pct%)');
    });
  }

  @override
  Future<void> terminateContract(String cid, String type, double amt, String notes) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final c = ContractEntity.fromMap((await txn.query('contracts', where: 'id = ?', whereArgs: [cid])).first);
      await txn.update('contracts', {'status': 'Terminated'}, where: 'id = ?', whereArgs: [cid]);
      await txn.update('units', {'status': 'Available'}, where: 'id = ?', whereArgs: [c.unitId]);
      await txn.insert('unit_status_history', {'unit_id': c.unitId, 'changed_at': AppFormatters.todayIso(), 'from_status': 'Rented', 'to_status': 'Available', 'reason': 'إنهاء العقد $cid'});
      if (amt > 0) await txn.insert('settlements', {'contract_id': cid, 'settlement_type': type, 'amount': amt, 'currency': c.currency, 'settlement_date': AppFormatters.todayIso(), 'notes': notes});
      await _db.addAudit(txn, 'إنهاء العقد $cid وتحرير الوحدة');
    });
  }


  @override
  Future<void> updateContract(ContractEntity c) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update('contracts', {
        'unit_id': c.unitId,
        'tenant_id': c.tenantId,
        'start_date': c.startDate,
        'end_date': c.endDate,
        'rent': c.rent,
        'currency': c.currency,
        'frequency': c.frequency,
        'deposit': c.deposit,
        'grace_days': c.graceDays,
        'increase_pct': c.increasePct,
        'witnesses_json': jsonEncode(c.witnesses.map((w) => w.toMap()).toList()),
        'terms_json': jsonEncode(c.terms)
      }, where: 'id = ?', whereArgs: [c.id]);
      await _db.addAudit(txn, 'تعديل عقد: ${c.id}');
    });
  }
}
