import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_dropdown_helpers.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../routes/app_routes.dart';
import '../controllers/properties_controller.dart';

class PropertiesScreen extends GetView<PropertiesController> {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Column(children: [
          TextField(
            onChanged: (v) => controller.searchQuery.value = v,
            decoration: InputDecoration(
              hintText: 'search_prop_hint'.tr,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _addProp(context),
                icon: const Icon(Icons.add_business_outlined, size: 18),
                label: Text('add_property'.tr),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                  foregroundColor: scheme.secondary,
                ),
                onPressed: () => _addUnit(context),
                icon: const Icon(Icons.meeting_room_outlined, size: 18),
                label: Text('add_unit'.tr),
              ),
            ),
          ]),
        ]),
      ),
      Expanded(
        child: Obx(() {
          final list = controller.filteredProperties;
          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final prop = list[i];
              final uList = controller.unitsForProperty(prop.id);
              final rented = uList.where((u) => u.status == 'Rented').length;
              final avail = uList.where((u) => u.status == 'Available').length;
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Get.toNamed(AppRoutes.propertyDetail, arguments: prop.id),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(prop.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                        Chip(label: Text('units_count_chip'.trParams({'count': '${uList.length}'})), visualDensity: VisualDensity.compact),
                      ]),
                      Text('${prop.code} • ${prop.type} • ${prop.address}', style: Theme.of(context).textTheme.bodySmall),
                      const Divider(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Row(children: [
                          _badge('rented_badge'.trParams({'count': '$rented'}), scheme.primary),
                          const SizedBox(width: 6),
                          _badge('available_badge'.trParams({'count': '$avail'}), AppColors.success),
                        ]),
                        Text('details_arrow'.tr, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                    ]),
                  ),
                ),
              );
            },
          );
        }),
      ),
    ]);
  }

  Widget _badge(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
        child: Text(t, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  void _addProp(BuildContext context) {
    final nameC = TextEditingController(), codeC = TextEditingController(text: 'ARK-0${controller.properties.length + 1}'), addrC = TextEditingController(), descC = TextEditingController();
    // Use canonical key so dropdown always matches items
    final type = AppDropdownHelpers.propTypeKeys.first.obs;
    Get.bottomSheet(Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('add_property_title'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        TextField(controller: nameC, decoration: InputDecoration(labelText: '${'prop_name'.tr} *')),
        const SizedBox(height: 8),
        Row(children: [
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
        ]),
        const SizedBox(height: 8),
        TextField(controller: addrC, decoration: InputDecoration(labelText: 'prop_addr'.tr)),
        const SizedBox(height: 8),
        TextField(controller: descC, decoration: InputDecoration(labelText: 'prop_desc'.tr)),
        const SizedBox(height: 12),
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
            try {
              await controller.createProperty(nameC.text.trim(), codeC.text.trim(), type.value, addrC.text.trim(), descC.text.trim());
              Get.back();
              UIHelper.showSuccess('prop_added_success'.tr);
            } catch (e) {
              UIHelper.showError('${'error'.tr}: $e');
            }
          },
          child: Text('save'.tr),
        ),
      ])),
    ));
  }

  void _addUnit(BuildContext context) {
    if (controller.properties.isEmpty) {
      UIHelper.showWarning('add_property'.tr);
      return;
    }
    final pid = controller.properties.first.id.obs;
    final type = AppDropdownHelpers.unitTypeKeys.first.obs;
    final codeC = TextEditingController(), floorC = TextEditingController(text: '1'), areaC = TextEditingController(text: '120 m²'), roomsC = TextEditingController(text: '3'), bathsC = TextEditingController(text: '2'), elecC = TextEditingController(), waterC = TextEditingController(), featC = TextEditingController();
    Get.bottomSheet(Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('add_unit'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Obx(() => DropdownButtonFormField<String>(
              value: pid.value,
              decoration: InputDecoration(labelText: 'prop_name'.tr),
              items: controller.properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
              onChanged: (v) => pid.value = v ?? pid.value,
            )),
        const SizedBox(height: 8),
        Row(children: [
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
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: floorC, decoration: InputDecoration(labelText: 'floor'.tr))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: areaC, decoration: InputDecoration(labelText: 'area'.tr))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: roomsC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'rooms'.tr))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: bathsC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'baths'.tr))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: elecC, decoration: InputDecoration(labelText: 'elec_meter'.tr))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: waterC, decoration: InputDecoration(labelText: 'water_meter'.tr))),
        ]),
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
              propertyId: pid.value,
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
      ])),
    ));
  }
}
