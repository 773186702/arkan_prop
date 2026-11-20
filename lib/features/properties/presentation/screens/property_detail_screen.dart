import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_dropdown_helpers.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../routes/app_routes.dart';
import '../../../contracts/presentation/controllers/contracts_controller.dart';
import '../../domain/property_models.dart';
import '../controllers/properties_controller.dart';

class PropertyDetailScreen extends GetView<PropertiesController> {
  const PropertyDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final propId = Get.arguments as String;
    final contractsCtrl = Get.find<ContractsController>();
    return Obx(() { 
      final prop = controller.propertyById(propId);
      if (prop == null) return const Scaffold();
      final units = controller.unitsForProperty(propId);
      return Scaffold(
        appBar: AppBar(
          title: Text(prop.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'edit_property_title'.tr,
              onPressed: () => _editProperty(prop, context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'delete_prop_title'.tr,
              onPressed: () => _deleteProperty(prop),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(label: Text(prop.type)),
                        Text(prop.code, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(prop.address),
                    if (prop.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(prop.description, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'prop_units_header'.trParams({'count': '${units.length}'}),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                TextButton.icon(
                  onPressed: () => _addUnitToProperty(context, prop.id),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('add_unit'.tr),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (units.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('no_units_in_prop'.tr),
                ),
              ),
            ...units.map((u) {
              final ac = contractsCtrl.activeContractForUnit(u.id);
              final t = ac != null ? contractsCtrl.tenantById(ac.tenantId) : null;
              final color = u.status == 'Available'
                  ? AppColors.success
                  : (u.status == 'Rented' ? AppColors.emerald : AppColors.warning);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text('${u.code} • ${u.type} (${u.area})', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(t != null ? '${'tenant_label'.trParams({'name': t.name})} | ${'floor'.tr}: ${u.floor}' : '${'no_active_contract'.tr} | ${'floor'.tr}: ${u.floor}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      AppDropdownHelpers.unitStatusLabel(u.status),
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ),
                  onTap: () => Get.toNamed(AppRoutes.unitDetail, arguments: u.id),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  void _editProperty(PropertyEntity p, BuildContext context) {
    final nameC = TextEditingController(text: p.name);
    final addrC = TextEditingController(text: p.address);
    final descC = TextEditingController(text: p.description);
    final codeC = TextEditingController(text: p.code);
    // Normalize stored value to canonical key
    final type = AppDropdownHelpers.normalizePropType(p.type).obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('edit_property_title'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(controller: nameC, decoration: InputDecoration(labelText: '${'prop_name'.tr} *')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: codeC, decoration: InputDecoration(labelText: 'prop_code'.tr))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() => DropdownButtonFormField<String>(
                      value: type.value,
                      decoration: InputDecoration(labelText: 'prop_type'.tr),
                      items: AppDropdownHelpers.propTypeKeys
                          .map((k) => DropdownMenuItem(value: k, child: Text(AppDropdownHelpers.propTypeLabel(k))))
                          .toList(),
                      onChanged: (v) => type.value = v ?? type.value,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: addrC, decoration: InputDecoration(labelText: 'prop_addr'.tr)),
              const SizedBox(height: 8),
              TextField(controller: descC, decoration: InputDecoration(labelText: 'prop_desc'.tr)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (nameC.text.trim().isEmpty) {
                    UIHelper.showWarning('enter_valid_name'.tr, title: 'prop_name'.tr);
                    return;
                  }
                  if (codeC.text.trim().isEmpty) {
                    UIHelper.showWarning('enter_valid_code'.tr, title: 'prop_code'.tr);
                    return;
                  }
                  final confirm = await UIHelper.showConfirmDialog(
                    title: 'confirm'.tr,
                    message: 'confirm_edit_prop'.trParams({'name': p.name}),
                    confirmText: 'save'.tr,
                  );
                  if (confirm) {
                    try {
                      final updated = PropertyEntity(
                        id: p.id,
                        name: nameC.text.trim(),
                        code: codeC.text.trim(),
                        type: type.value,
                        address: addrC.text.trim(),
                        description: descC.text.trim(),
                        status: p.status,
                      );
                      await controller.updateProperty(updated);
                      Get.back();
                      UIHelper.showSuccess('prop_updated_success'.tr);
                    } catch (e) {
                      UIHelper.showError('${'error'.tr}: $e');
                    }
                  }
                },
                child: Text('save'.tr),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _deleteProperty(PropertyEntity p) async {
    final confirm = await UIHelper.showConfirmDialog(
      title: 'delete_prop_title'.tr,
      message: 'delete_prop_msg'.trParams({'name': p.name}),
      isDanger: true,
      confirmText: 'delete'.tr,
    );
    if (confirm) {
      final err = await controller.deleteProperty(p.id);
      if (err != null) {
        UIHelper.showError(err);
      } else {
        Get.back();
        UIHelper.showSuccess('prop_deleted_success'.tr);
      }
    }
  }

  void _addUnitToProperty(BuildContext context, String propertyId) {
    final codeC = TextEditingController();
    final floorC = TextEditingController(text: '1');
    final areaC = TextEditingController(text: '120 m²');
    final roomsC = TextEditingController(text: '3');
    final bathsC = TextEditingController(text: '2');
    final elecC = TextEditingController();
    final waterC = TextEditingController();
    final featC = TextEditingController();
    // Use canonical key so it always matches items list
    final type = AppDropdownHelpers.unitTypeKeys.first.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('add_unit'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: codeC, decoration: InputDecoration(labelText: '${'unit_code_label'.tr} *'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() => DropdownButtonFormField<String>(
                      value: type.value,
                      decoration: InputDecoration(labelText: 'unit_type_label'.tr),
                      items: AppDropdownHelpers.unitTypeKeys
                          .map((k) => DropdownMenuItem(value: k, child: Text(AppDropdownHelpers.unitTypeLabel(k))))
                          .toList(),
                      onChanged: (v) => type.value = v ?? type.value,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: floorC, decoration: InputDecoration(labelText: 'floor'.tr))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: areaC, decoration: InputDecoration(labelText: 'area'.tr))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: roomsC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'rooms'.tr))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: bathsC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'baths'.tr))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: elecC, decoration: InputDecoration(labelText: 'elec_meter'.tr))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: waterC, decoration: InputDecoration(labelText: 'water_meter'.tr))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: featC, decoration: InputDecoration(labelText: 'features_label'.tr)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  if (codeC.text.trim().isEmpty) {
                    UIHelper.showWarning('enter_valid_code'.tr, title: 'unit_code_label'.tr);
                    return;
                  }
                  final roomsVal = int.tryParse(roomsC.text.trim());
                  if (roomsVal == null || roomsVal < 0) {
                    UIHelper.showWarning('يرجى إدخال عدد غرف صحيح', title: 'rooms'.tr);
                    return;
                  }
                  final bathsVal = int.tryParse(bathsC.text.trim());
                  if (bathsVal == null || bathsVal < 0) {
                    UIHelper.showWarning('يرجى إدخال عدد حمامات صحيح', title: 'baths'.tr);
                    return;
                  }
                  final err = await controller.createUnit(
                    propertyId: propertyId,
                    code: codeC.text.trim(),
                    type: type.value,
                    floor: floorC.text.trim().isEmpty ? '1' : floorC.text.trim(),
                    area: areaC.text.trim(),
                    rooms: roomsVal,
                    baths: bathsVal,
                    elecMeter: elecC.text.isEmpty ? '-' : elecC.text,
                    waterMeter: waterC.text.isEmpty ? '-' : waterC.text,
                    features: featC.text.split(RegExp(r'[,،]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  );
                  if (err != null) {
                    UIHelper.showError(err);
                  } else {
                    Get.back();
                    UIHelper.showSuccess('unit_added_success'.tr);
                  }
                },
                child: Text('save'.tr),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
