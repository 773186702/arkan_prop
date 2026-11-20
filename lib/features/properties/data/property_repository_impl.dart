import 'dart:convert';
import '../../../core/database/app_database.dart';
import '../../../core/utils/formatters.dart';
import '../domain/property_models.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  PropertyRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<PropertyEntity>> getProperties() async => (await (await _db.database).query('properties')).map(PropertyEntity.fromMap).toList();
  @override
  Future<List<UnitEntity>> getUnits() async => (await (await _db.database).query('units')).map(UnitEntity.fromMap).toList();
  @override
  Future<List<UnitStatusLog>> getUnitStatusHistory(String unitId) async =>
      (await (await _db.database).query('unit_status_history', where: 'unit_id = ?', whereArgs: [unitId], orderBy: 'id DESC')).map(UnitStatusLog.fromMap).toList();

  @override
  Future<void> addProperty(PropertyEntity p) async {
    final db = await _db.database;
    await db.transaction((t) async {
      await t.insert('properties', {'id': p.id, 'name': p.name, 'code': p.code, 'type': p.type, 'address': p.address, 'description': p.description, 'status': p.status});
      await _db.addAudit(t, 'إضافة عقار: ${p.name}');
    });
  }

  @override
  Future<void> addUnit(UnitEntity u) async {
    final db = await _db.database;
    await db.transaction((t) async {
      await t.insert('units', {'id': u.id, 'property_id': u.propertyId, 'code': u.code, 'type': u.type, 'floor': u.floor, 'area': u.area, 'rooms': u.rooms, 'baths': u.baths, 'elec_meter': u.elecMeter, 'water_meter': u.waterMeter, 'features_json': jsonEncode(u.features), 'status': u.status});
      await t.insert('unit_status_history', {'unit_id': u.id, 'changed_at': AppFormatters.todayIso(), 'from_status': '-', 'to_status': u.status, 'reason': 'إنشاء الوحدة'});
      await _db.addAudit(t, 'إضافة وحدة ${u.code}');
    });
  }

  @override
  Future<void> updateUnitSpecs(UnitEntity u) async {
    final db = await _db.database;
    await db.transaction((t) async {
      await t.update('units', {'floor': u.floor, 'area': u.area, 'rooms': u.rooms, 'baths': u.baths, 'elec_meter': u.elecMeter, 'water_meter': u.waterMeter, 'features_json': jsonEncode(u.features)}, where: 'id = ?', whereArgs: [u.id]);
      await _db.addAudit(t, 'تحديث مواصفات الوحدة ${u.code}');
    });
  }
  @override
  Future<void> updateProperty(PropertyEntity p) async {
    final db = await _db.database;
    await db.transaction((t) async {
      await t.update('properties', {'name': p.name, 'code': p.code, 'type': p.type, 'address': p.address, 'description': p.description, 'status': p.status}, where: 'id = ?', whereArgs: [p.id]);
      await _db.addAudit(t, 'تحديث عقار: ${p.name}');
    });
  }

  @override
  Future<void> updateUnit(UnitEntity u) async {
    final db = await _db.database;
    await db.transaction((t) async {
      await t.update('units', {'property_id': u.propertyId, 'code': u.code, 'type': u.type, 'floor': u.floor, 'area': u.area, 'rooms': u.rooms, 'baths': u.baths, 'elec_meter': u.elecMeter, 'water_meter': u.waterMeter, 'features_json': jsonEncode(u.features), 'status': u.status}, where: 'id = ?', whereArgs: [u.id]);
      await _db.addAudit(t, 'تحديث وحدة: ${u.code}');
    });
  }


  @override
  Future<void> deleteProperty(String pid) async {
    final db = await _db.database;
    await db.transaction((t) async {
      final units = await t.query('units', where: 'property_id = ?', whereArgs: [pid]);
      if (units.isNotEmpty) throw StateError('لا يمكن حذف عقار يحتوي على وحدات');
      await t.delete('properties', where: 'id = ?', whereArgs: [pid]);
      await _db.addAudit(t, 'حذف عقار: $pid');
    });
  }

  @override
  Future<void> deleteUnit(String uid) async {
    final db = await _db.database;
    await db.transaction((t) async {
      final contract = await t.query('contracts', where: 'unit_id = ? AND status = ?', whereArgs: [uid, 'Active']);
      if (contract.isNotEmpty) throw StateError('لا يمكن حذف وحدة مؤجرة بعقد نشط');
      await t.delete('units', where: 'id = ?', whereArgs: [uid]);
      await t.delete('unit_status_history', where: 'unit_id = ?', whereArgs: [uid]);
      await _db.addAudit(t, 'حذف وحدة: $uid');
    });
  }

  @override
  Future<void> changeUnitStatus(String unitId, String newStatus, String reason) async {
    final db = await _db.database;
    await db.transaction((t) async {
      final act = await t.query('contracts', where: 'unit_id = ? AND status = ?', whereArgs: [unitId, 'Active']);
      if (act.isNotEmpty) throw StateError('الوحدة مرتبطة بعقد نشط (Rented)');
      final row = (await t.query('units', where: 'id = ?', whereArgs: [unitId])).first;
      await t.update('units', {'status': newStatus}, where: 'id = ?', whereArgs: [unitId]);
      await t.insert('unit_status_history', {'unit_id': unitId, 'changed_at': AppFormatters.todayIso(), 'from_status': row['status'], 'to_status': newStatus, 'reason': reason});
      await _db.addAudit(t, 'تغيير حالة ${row['code']} إلى $newStatus ($reason)');
    });
  }
}