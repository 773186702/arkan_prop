import 'dart:convert';

class PropertyEntity {
  const PropertyEntity({required this.id, required this.name, required this.code, required this.type, required this.address, required this.description, required this.status});
  final String id, name, code, type, address, description, status;
  factory PropertyEntity.fromMap(Map<String, dynamic> m) => PropertyEntity(id: m['id'] as String, name: m['name'] as String, code: m['code'] as String, type: m['type'] as String, address: m['address'] as String, description: m['description'] as String, status: m['status'] as String);
}

class UnitEntity {
  const UnitEntity({required this.id, required this.propertyId, required this.code, required this.type, required this.floor, required this.area, required this.rooms, required this.baths, required this.elecMeter, required this.waterMeter, required this.features, required this.status});
  final String id, propertyId, code, type, floor, area, elecMeter, waterMeter, status;
  final int rooms, baths;
  final List<String> features;
  factory UnitEntity.fromMap(Map<String, dynamic> m) => UnitEntity(
        id: m['id'] as String, propertyId: m['property_id'] as String, code: m['code'] as String, type: m['type'] as String,
        floor: m['floor'] as String, area: m['area'] as String, rooms: m['rooms'] as int, baths: m['baths'] as int,
        elecMeter: m['elec_meter'] as String, waterMeter: m['water_meter'] as String,
        features: (jsonDecode(m['features_json'] as String) as List).map((e) => e.toString()).toList(), status: m['status'] as String,
      );
}

class UnitStatusLog {
  const UnitStatusLog({required this.changedAt, required this.fromStatus, required this.toStatus, required this.reason});
  final String changedAt, fromStatus, toStatus, reason;
  factory UnitStatusLog.fromMap(Map<String, dynamic> m) => UnitStatusLog(changedAt: m['changed_at'] as String, fromStatus: m['from_status'] as String, toStatus: m['to_status'] as String, reason: m['reason'] as String);
}

abstract interface class PropertyRepository {
  Future<List<PropertyEntity>> getProperties();
  Future<List<UnitEntity>> getUnits();
  Future<List<UnitStatusLog>> getUnitStatusHistory(String unitId);
  Future<void> addProperty(PropertyEntity prop);
  Future<void> addUnit(UnitEntity unit);
  Future<void> updateUnitSpecs(UnitEntity unit);
  Future<void> changeUnitStatus(String unitId, String newStatus, String reason);
  Future<void> updateProperty(PropertyEntity prop);
  Future<void> updateUnit(UnitEntity unit);
  Future<void> deleteProperty(String pid);
  Future<void> deleteUnit(String uid);
}