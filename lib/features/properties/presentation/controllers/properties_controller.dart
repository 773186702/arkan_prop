import 'package:get/get.dart';
import '../../domain/property_models.dart';

class PropertiesController extends GetxController {
  PropertiesController(this._repo);
  final PropertyRepository _repo;
  final properties = <PropertyEntity>[].obs;
  final units = <UnitEntity>[].obs;
  final searchQuery = ''.obs;
  final selectedStatusLogs = <UnitStatusLog>[].obs;

  @override
  void onInit() { super.onInit(); loadAll(); }

  Future<void> loadAll() async {
    properties.assignAll(await _repo.getProperties());
    units.assignAll(await _repo.getUnits());
  }

  List<PropertyEntity> get filteredProperties {
    final q = searchQuery.value.trim().toLowerCase();
    return q.isEmpty ? properties : properties.where((p) => p.name.toLowerCase().contains(q) || p.address.toLowerCase().contains(q)).toList();
  }

  List<UnitEntity> unitsForProperty(String pid) => units.where((u) => u.propertyId == pid).toList();
  PropertyEntity? propertyById(String id) => properties.firstWhereOrNull((p) => p.id == id);
  UnitEntity? unitById(String id) => units.firstWhereOrNull((u) => u.id == id);
  Future<void> loadUnitHistory(String uid) async => selectedStatusLogs.assignAll(await _repo.getUnitStatusHistory(uid));

  Future<void> createProperty(String name, String code, String type, String addr, String desc) async {
    await _repo.addProperty(PropertyEntity(id: 'P${DateTime.now().millisecondsSinceEpoch}', name: name, code: code, type: type, address: addr, description: desc, status: 'نشط'));
    await loadAll();
  }

  Future<String?> createUnit({required String propertyId, required String code, required String type, required String floor, required String area, required int rooms, required int baths, required String elecMeter, required String waterMeter, required List<String> features}) async {
    if (units.any((u) => u.propertyId == propertyId && u.code == code)) return 'رمز الوحدة مكرر داخل نفس العقار';
    await _repo.addUnit(UnitEntity(id: 'U${DateTime.now().millisecondsSinceEpoch}', propertyId: propertyId, code: code, type: type, floor: floor, area: area, rooms: rooms, baths: baths, elecMeter: elecMeter, waterMeter: waterMeter, features: features, status: 'Available'));
    await loadAll();
    return null;
  }

  Future<void> updateSpecs(UnitEntity u) async { await _repo.updateUnitSpecs(u); await loadAll(); }

  Future<String?> deleteProperty(String pid) async {
    try { await _repo.deleteProperty(pid); await loadAll(); return null; }
    catch (e) { return e.toString(); }
  }

  Future<String?> deleteUnit(String uid) async {
    try { await _repo.deleteUnit(uid); await loadAll(); return null; }
    catch (e) { return e.toString(); }
  }
  Future<void> updateProperty(PropertyEntity p) async {
    await _repo.updateProperty(p);
    await loadAll();
  }

  Future<void> updateUnit(UnitEntity u) async {
    await _repo.updateUnit(u);
    await loadAll();
  }


  Future<String?> changeStatus(String unitId, String newStatus, String reason) async {
    try {
      await _repo.changeUnitStatus(unitId, newStatus, reason);
      await loadAll();
      await loadUnitHistory(unitId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

}