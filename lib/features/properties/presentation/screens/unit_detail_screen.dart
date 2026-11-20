import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_dropdown_helpers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../routes/app_routes.dart';
import '../../../contracts/presentation/controllers/contracts_controller.dart';
import '../../../finance/domain/finance_models.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';
import '../../domain/property_models.dart';
import '../controllers/properties_controller.dart';

class UnitDetailScreen extends StatefulWidget {
  const UnitDetailScreen({super.key});
  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> {
  final controller = Get.find<PropertiesController>();
  final contractsCtrl = Get.find<ContractsController>();
  final financeCtrl = Get.find<FinanceController>();
  late final String unitId;

  @override
  void initState() {
    super.initState();
    unitId = Get.arguments as String;
    controller.loadUnitHistory(unitId);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final u = controller.unitById(unitId);
      if (u == null) return const Scaffold();
      final activeC = contractsCtrl.activeContractForUnit(u.id);
      final services = financeCtrl.servicesForUnit(u.id);

      return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text('${'unit_label'.trParams({'code': u.code})} (${u.type})'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'edit_all_specs'.tr,
                onPressed: () => _editUnitFullSheet(u),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'delete_unit_title'.tr,
                onPressed: () => _deleteUnit(u),
              ),
            ],
            bottom: TabBar(tabs: [
              Tab(text: 'tab_specs'.tr),
              Tab(text: 'tab_services'.tr),
              Tab(text: 'tab_history'.tr),
            ]),
          ),
          body: TabBarView(children: [
            ListView(padding: const EdgeInsets.all(14), children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('unit_status_label'.trParams({'status': AppDropdownHelpers.unitStatusLabel(u.status)}), style: const TextStyle(fontWeight: FontWeight.w800)),
                          FilledButton.tonal(
                            onPressed: () => _statusDlg(u),
                            child: Text('change_status_btn'.tr),
                          ),
                        ],
                      ),
                      if (activeC != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OutlinedButton(
                            onPressed: () => Get.toNamed(AppRoutes.contractDetail, arguments: activeC.id),
                            child: Text('open_active_contract'.trParams({'id': activeC.id})),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('specs_card_title'.tr, style: const TextStyle(fontWeight: FontWeight.w800)),
                          TextButton.icon(
                            onPressed: () => _editUnitFullSheet(u),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: Text('edit_all_specs'.tr),
                          ),
                        ],
                      ),
                      Text('${'unit_type_label'.tr}: ${u.type} • ${'floor'.tr}: ${u.floor} • ${'area'.tr}: ${u.area}'),
                      Text('${'rooms'.tr}: ${u.rooms} • ${'baths'.tr}: ${u.baths}'),
                      Text('${'elec_meter'.tr}: ${u.elecMeter} • ${'water_meter'.tr}: ${u.waterMeter}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: u.features.map((f) => Chip(label: Text(f))).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
            ListView(padding: const EdgeInsets.all(14), children: [
              FilledButton.icon(
                onPressed: () => _addSvc(u.id),
                icon: const Icon(Icons.bolt_rounded),
                label: Text('add_service_btn'.tr),
              ),
              const SizedBox(height: 10),
              if (services.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('no_services_yet'.tr),
                  ),
                ),
              ...services.map((s) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(label: Text(s.billingType == 'Fixed' ? 'fixed_fee'.tr : 'consumption'.tr)),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'edit_service_btn'.tr,
                                    onPressed: () => _editSvc(s),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    tooltip: 'delete_service_btn'.tr,
                                    onPressed: () => _deleteSvc(s),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(s.billingType == 'Fixed'
                              ? '${'price_amount'.tr}: ${s.fixedAmount} ${s.currency}'
                              : '${'prev_reading_label'.tr}: ${s.prevReading} • ${'price_amount'.tr}: ${s.unitRate} ${s.currency}'),
                          const SizedBox(height: 8),
                          s.billingType == 'Usage-Based'
                              ? FilledButton.tonal(
                                  onPressed: () => _readDlg(s),
                                  child: Text('enter_meter_reading'.tr),
                                )
                              : FilledButton.tonal(
                                  onPressed: () async {
                                    final e = await financeCtrl.issueFixedServiceDue(s.id);
                                    if (e != null) {
                                      UIHelper.showError(e);
                                    } else {
                                      UIHelper.showSuccess('success'.tr);
                                    }
                                  },
                                  child: Text('issue_due'.tr),
                                ),
                        ],
                      ),
                    ),
                  )),
            ]),
            ListView(
              padding: const EdgeInsets.all(14),
              children: controller.selectedStatusLogs.map((l) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${l.fromStatus} ← ${l.toStatus}'),
                  subtitle: Text('${l.changedAt} • ${l.reason}'),
                ),
              )).toList(),
            ),
          ]),
        ),
      );
    });
  }

  void _editUnitFullSheet(UnitEntity u) {
    final codeC = TextEditingController(text: u.code);
    final floorC = TextEditingController(text: u.floor);
    final areaC = TextEditingController(text: u.area);
    final roomsC = TextEditingController(text: u.rooms.toString());
    final bathsC = TextEditingController(text: u.baths.toString());
    final elecC = TextEditingController(text: u.elecMeter);
    final waterC = TextEditingController(text: u.waterMeter);
    final ftC = TextEditingController(text: u.features.join('، '));
    // Normalize stored type to canonical key
    final type = AppDropdownHelpers.normalizeUnitType(u.type).obs;
    final status = u.status.obs;

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
              Text('edit_all_specs'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
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
              TextField(controller: ftC, decoration: InputDecoration(labelText: 'features_label'.tr)),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                initialValue: AppDropdownHelpers.normalizeUnitStatus(status.value),
                decoration: InputDecoration(labelText: 'unit_status_label'.trParams({'status': ''})),
                items: AppDropdownHelpers.unitStatusKeys
                    .map((k) => DropdownMenuItem(value: k, child: Text(AppDropdownHelpers.unitStatusLabel(k))))
                    .toList(),
                onChanged: (v) => status.value = v ?? status.value,
              )),
              const SizedBox(height: 16),
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
                  final confirm = await UIHelper.showConfirmDialog(
                    title: 'confirm'.tr,
                    message: 'confirm_edit_unit'.trParams({'code': u.code}),
                    confirmText: 'save'.tr,
                  );
                  if (confirm) {
                    try {
                      final updated = UnitEntity(
                        id: u.id,
                        propertyId: u.propertyId,
                        code: codeC.text.trim(),
                        type: type.value,
                        floor: floorC.text.trim(),
                        area: areaC.text.trim(),
                        rooms: roomsVal,
                        baths: bathsVal,
                        elecMeter: elecC.text.trim(),
                        waterMeter: waterC.text.trim(),
                        features: ftC.text.split(RegExp(r'[,،]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                        status: status.value,
                      );
                      await controller.updateUnit(updated);
                      Get.back();
                      UIHelper.showSuccess('unit_updated_success'.tr);
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

  void _deleteUnit(UnitEntity u) async {
    final confirm = await UIHelper.showConfirmDialog(
      title: 'delete_unit_title'.tr,
      message: 'delete_unit_msg'.trParams({'code': u.code}),
      isDanger: true,
      confirmText: 'delete'.tr,
    );
    if (confirm) {
      final err = await controller.deleteUnit(u.id);
      if (err != null) {
        UIHelper.showError(err);
      } else {
        Get.back();
        UIHelper.showSuccess('unit_deleted_success'.tr);
      }
    }
  }

  void _statusDlg(UnitEntity u) {
    final next = (u.status == 'Rented' ? 'Available' : u.status).obs;
    final rC = TextEditingController();
    Get.defaultDialog(
      title: '${'change_status_btn'.tr} (${u.code})',
      content: Column(children: [
        Obx(() => DropdownButtonFormField<String>(
              initialValue: AppDropdownHelpers.normalizeUnitStatus(next.value),
              items: ['Available', 'Pending', 'Blocked', 'Maintenance']
                  .map((e) => DropdownMenuItem(value: e, child: Text(AppDropdownHelpers.unitStatusLabel(e))))
                  .toList(),
              onChanged: (v) => next.value = v ?? 'Available',
            )),
        const SizedBox(height: 8),
        TextField(controller: rC, decoration: InputDecoration(labelText: 'change_reason_label'.tr)),
      ]),
      textConfirm: 'save'.tr,
      textCancel: 'cancel'.tr,
      onConfirm: () async {
        if (rC.text.trim().isEmpty) {
          UIHelper.showWarning('change_reason_label'.tr);
          return;
        }
        final e = await controller.changeStatus(u.id, next.value, rC.text.trim());
        Get.back();
        if (e != null) {
          UIHelper.showError(e);
        } else {
          UIHelper.showSuccess('unit_updated_success'.tr);
        }
      },
    );
  }

  void _addSvc(String uid) {
    final nC = TextEditingController(), vC = TextEditingController(text: '10000');
    final bt = 'Fixed'.obs, cur = 'YER'.obs;
    Get.bottomSheet(Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('add_service_btn'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(controller: nC, decoration: InputDecoration(labelText: '${'service_name'.tr} *')),
        const SizedBox(height: 8),
        Obx(() => DropdownButtonFormField<String>(
              initialValue: bt.value,
              items: [DropdownMenuItem(value: 'Fixed', child: Text('fixed_fee'.tr)), DropdownMenuItem(value: 'Usage-Based', child: Text('consumption'.tr))],
              onChanged: (v) => bt.value = v ?? 'Fixed',
            )),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: vC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'price_amount'.tr))),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => DropdownButtonFormField<String>(
                  initialValue: cur.value,
                  items: const ['YER', 'SAR', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => cur.value = v ?? 'YER',
                )),
          ),
        ]),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            if (nC.text.trim().isEmpty) {
              UIHelper.showWarning('service_name'.tr);
              return;
            }
            try {
              await financeCtrl.addService(uid, nC.text.trim(), bt.value, double.tryParse(vC.text) ?? 0, cur.value);
              Get.back();
              UIHelper.showSuccess('success'.tr);
            } catch (e) {
              UIHelper.showError('${'error'.tr}: $e');
            }
          },
          child: Text('save'.tr),
        ),
      ]),
    ));
  }

  void _editSvc(ServiceEntity s) {
    final nC = TextEditingController(text: s.name);
    final vC = TextEditingController(text: (s.billingType == 'Fixed' ? s.fixedAmount : s.unitRate).toString());
    final bt = s.billingType.obs;
    final cur = s.currency.obs;

    Get.bottomSheet(Container(
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
            Text('edit_service_btn'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(controller: nC, decoration: InputDecoration(labelText: '${'service_name'.tr} *')),
            const SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<String>(
                  initialValue: bt.value,
                  items: [
                    DropdownMenuItem(value: 'Fixed', child: Text('fixed_fee'.tr)),
                    DropdownMenuItem(value: 'Usage-Based', child: Text('consumption'.tr)),
                  ],
                  onChanged: (v) => bt.value = v ?? 'Fixed',
                )),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: vC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'price_amount'.tr),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      initialValue: cur.value,
                      items: const ['YER', 'SAR', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => cur.value = v ?? 'YER',
                    )),
              ),
            ]),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () async {
                if (nC.text.trim().isEmpty) {
                  UIHelper.showWarning('service_name'.tr);
                  return;
                }
                final val = double.tryParse(vC.text.trim()) ?? 0;
                final updated = ServiceEntity(
                  id: s.id,
                  unitId: s.unitId,
                  name: nC.text.trim(),
                  billingType: bt.value,
                  unitLabel: bt.value == 'Fixed' ? 'دوري' : (s.unitLabel.isNotEmpty ? s.unitLabel : 'وحدة'),
                  unitRate: bt.value == 'Usage-Based' ? val : 0,
                  fixedAmount: bt.value == 'Fixed' ? val : 0,
                  currency: cur.value,
                  prevReading: s.prevReading,
                );
                final err = await financeCtrl.updateService(updated);
                Get.back();
                if (err != null) {
                  UIHelper.showError(err);
                } else {
                  UIHelper.showSuccess('success'.tr);
                }
              },
              child: Text('save'.tr),
            ),
          ],
        ),
      ),
    ));
  }

  void _deleteSvc(ServiceEntity s) async {
    final confirm = await UIHelper.showConfirmDialog(
      title: 'delete_service_btn'.tr,
      message: 'delete_service_confirm'.tr,
      isDanger: true,
      confirmText: 'delete'.tr,
    );
    if (confirm) {
      final err = await financeCtrl.deleteService(s.id);
      if (err != null) {
        UIHelper.showError(err);
      } else {
        UIHelper.showSuccess('success'.tr);
      }
    }
  }

  void _readDlg(ServiceEntity s) {
    final u = controller.unitById(s.unitId);
    final activeC = contractsCtrl.activeContractForUnit(s.unitId);
    final tenant = activeC != null ? contractsCtrl.tenantById(activeC.tenantId) : null;

    final rC = TextEditingController();
    final cC = TextEditingController();
    final calculatedCost = 0.0.obs;
    final consumptionUnits = 0.0.obs;

    void updateCalculation() {
      final curr = double.tryParse(rC.text.trim()) ?? s.prevReading;
      final diff = curr >= s.prevReading ? curr - s.prevReading : 0.0;
      consumptionUnits.value = diff;
      calculatedCost.value = diff * s.unitRate;
    }

    Get.bottomSheet(
      Builder(
        builder: (context) => Container(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${s.name} (${'enter_meter_reading'.tr})',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Chip(
                      label: Text(u?.code ?? '-'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'tenant_label'.trParams({'name': tenant?.name ?? 'بدون عقد نشط'}),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'prev_reading_label'.tr}: ${s.prevReading} ${s.unitLabel} • سعر الوحدة: ${s.unitRate} ${s.currency}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: rC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${'curr_reading_label'.tr} *',
                    hintText: '${s.prevReading}',
                  ),
                  onChanged: (_) => updateCalculation(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cC,
                  decoration: InputDecoration(labelText: 'change_reason_label'.tr),
                ),
                const SizedBox(height: 10),
                Obx(() => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('consumption_units'.tr, style: const TextStyle(fontSize: 12)),
                              Text(
                                '${consumptionUnits.value} ${s.unitLabel}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('total_cost'.tr, style: const TextStyle(fontSize: 12)),
                              Text(
                                '${AppFormatters.money(calculatedCost.value)} ${s.currency}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () async {
                    final curr = double.tryParse(rC.text.trim());
                    if (curr == null) {
                      UIHelper.showWarning('curr_reading_label'.tr);
                      return;
                    }
                    final err = await financeCtrl.recordMeterReading(s.id, curr, cC.text.trim());
                    Get.back();
                    if (err != null) {
                      UIHelper.showError(err);
                    } else {
                      UIHelper.showSuccess('success'.tr);
                    }
                  },
                  child: Text('confirm'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
