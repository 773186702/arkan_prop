import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_dropdown_helpers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../routes/app_routes.dart';
import '../../../properties/presentation/controllers/properties_controller.dart';
import '../../domain/contract_models.dart';
import '../controllers/contracts_controller.dart';
import 'tenant_notify_sheet.dart';

class ContractsScreen extends GetView<ContractsController> {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pCtrl = Get.find<PropertiesController>();
    return Obx(() {
      final tab = controller.subTab.value;
      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: [
              ButtonSegment(
                value: 0,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('tab_contracts'.trParams({'count': '${controller.contracts.length}'})),
                ),
              ),
              ButtonSegment(
                value: 1,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('tab_tenants'.trParams({'count': '${controller.tenants.length}'})),
                ),
              ),
              ButtonSegment(
                value: 2,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('tab_templates'.tr),
                ),
              ),
            ],
            selected: {tab},
            onSelectionChanged: (s) => controller.subTab.value = s.first,
          ),
        ),
        Expanded(child: tab == 0 ? _contractsList(context, pCtrl) : tab == 1 ? _tenantsList(context) : _templatesList()),
      ]);
    });
  }

  Widget _contractsList(BuildContext context, PropertiesController pCtrl) => ListView(padding: const EdgeInsets.all(14), children: [
        FilledButton.icon(
          onPressed: () => showNewContractSheet(context),
          icon: const Icon(Icons.note_add_outlined),
          label: Text('create_contract_btn'.tr),
        ),
        const SizedBox(height: 10),
        ...controller.contracts.map((c) {
          final u = pCtrl.unitById(c.unitId), t = controller.tenantById(c.tenantId);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text('${c.id} • ${'unit_label'.trParams({'code': u?.code ?? '-'})}', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${t?.name ?? '-'}\n${c.startDate} → ${c.endDate} | ${AppFormatters.money(c.rent)} ${c.currency}'),
              isThreeLine: true,
              trailing: Chip(label: Text(c.status)),
              onTap: () => Get.toNamed(AppRoutes.contractDetail, arguments: c.id),
            ),
          );
        }),
      ]);

  Widget _tenantsList(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
        TextField(
          onChanged: (v) => controller.tenantSearch.value = v,
          decoration: InputDecoration(
            hintText: 'tenant_search_hint'.tr,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => showTenantFormSheet(context),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: Text('add_tenant_btn'.tr),
        ),
        const SizedBox(height: 10),
        ...controller.filteredTenants.map((t) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${t.type} • ${t.phone} • ${'national_id'.tr}: ${t.idNum}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(AppRoutes.tenantDetail, arguments: t.id),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success.withValues(alpha: 0.14),
                        foregroundColor: AppColors.success,
                      ),
                      onPressed: () => showTenantNotifySheet(context, tenantId: t.id),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: Text('notify_tenant_btn'.tr),
                    ),
                  ),
                ]),
              ),
            )),
      ]);

  Widget _templatesList() => ListView(
        padding: const EdgeInsets.all(14),
        children: controller.templates.map((tp) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tp.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  for (var i = 0; i < tp.terms.length; i++) Text('${i + 1}. ${tp.terms[i]}'),
                ]),
              ),
            )).toList(),
      );

  static void showTenantFormSheet(BuildContext context, {TenantEntity? edit}) {
    final ctrl = Get.find<ContractsController>();
    final nC = TextEditingController(text: edit?.name ?? ''), idC = TextEditingController(text: edit?.idNum ?? ''), pC = TextEditingController(text: edit?.phone ?? ''), altC = TextEditingController(text: edit?.altPhone ?? ''), aC = TextEditingController(text: edit?.address ?? ''), mC = TextEditingController(text: edit?.email ?? ''), ntC = TextEditingController(text: edit?.notes ?? ''), jC = TextEditingController(text: edit?.job ?? ''), fC = TextEditingController(text: (edit?.familyMembers ?? 0).toString());
    // Normalize stored tenant type to canonical key for matching dropdown items
    final rawType = edit?.type ?? '';
    final type = (rawType.isNotEmpty ? AppDropdownHelpers.normalizeTenantType(rawType) : AppDropdownHelpers.tenantTypeKeys.first).obs;
    Get.bottomSheet(Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(edit == null ? 'add_tenant_btn'.tr : 'edit_tenant'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(controller: nC, decoration: InputDecoration(labelText: '${'tenant_name'.tr} *')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Obx(() => DropdownButtonFormField<String>(
            value: type.value,
            decoration: InputDecoration(labelText: 'tenant_type'.tr),
            items: AppDropdownHelpers.tenantTypeKeys
                .map((k) => DropdownMenuItem(value: k, child: Text(AppDropdownHelpers.tenantTypeLabel(k))))
                .toList(),
            onChanged: (v) => type.value = v ?? type.value,
          ))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: idC, decoration: InputDecoration(labelText: 'national_id'.tr))),
        ]),
        const SizedBox(height: 8),
        Obx(() => type.value == 'Family' ? TextField(controller: fC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'family_members_count'.tr)) : const SizedBox()),
        Obx(() => type.value == 'Family' ? const SizedBox(height: 8) : const SizedBox()),
        TextField(controller: jC, decoration: InputDecoration(labelText: 'job_title'.tr)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: pC, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: '${'phone_number'.tr} *'))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: altC, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'alt_phone_number'.tr))),
        ]),
        const SizedBox(height: 8),
        TextField(controller: aC, decoration: InputDecoration(labelText: 'prop_addr'.tr)),
        const SizedBox(height: 8),
        TextField(controller: mC, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 8),
        TextField(controller: ntC, decoration: InputDecoration(labelText: 'notes_label'.tr)),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            final name = nC.text.trim();
            final phone = pC.text.trim();
            if (name.isEmpty) {
              UIHelper.showWarning('يرجى إدخال اسم المستأجر الكامل أو الجهة', title: 'tenant_name'.tr);
              return;
            }
            if (phone.isEmpty) {
              UIHelper.showWarning('يرجى إدخال رقم الهاتف للتواصل', title: 'phone_number'.tr);
              return;
            }
            if (phone.length < 6) {
              UIHelper.showWarning('يرجى إدخال رقم هاتف صحيح', title: 'phone_number'.tr);
              return;
            }
            if (type.value == 'Family' && fC.text.trim().isNotEmpty) {
              final count = int.tryParse(fC.text.trim());
              if (count == null || count < 1) {
                UIHelper.showWarning('يرجى إدخال عدد أفراد العائلة بشكل صحيح (أرقام فقط)', title: 'family_members_count'.tr);
                return;
              }
            }
            try {
              await ctrl.saveTenant(TenantEntity(
                id: edit?.id ?? 'T${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                type: type.value,
                phone: phone,
                altPhone: altC.text.trim(),
                idNum: idC.text.isEmpty ? '-' : idC.text.trim(),
                address: aC.text.isEmpty ? '-' : aC.text.trim(),
                email: mC.text.trim(),
                notes: ntC.text.trim(),
                status: 'Active',
                job: jC.text.trim(),
                familyMembers: int.tryParse(fC.text.trim()) ?? 0,
              ));
              Get.back();
              UIHelper.showSuccess('tenant_saved_success'.tr);
            } catch (e) {
              UIHelper.showError('${'error'.tr}: $e');
            }
          },
          child: Text(edit == null ? 'save_tenant'.tr : 'save'.tr),
        ),
      ])),
    ));
  }

  static void showNewContractSheet(BuildContext context) {
    final ctrl = Get.find<ContractsController>(), pCtrl = Get.find<PropertiesController>();
    final avail = pCtrl.units.where((u) => u.status == 'Available' || u.status == 'Pending').toList();
    
    // فحص المتطلبات مسبقاً مع رسائل تنبيه واضحة ومفهومة للمستخدم
    if (ctrl.tenants.isEmpty && avail.isEmpty) {
      UIHelper.showWarning(
        'cannot_create_contract_no_tenants_units'.tr,
        title: 'contract_requirements_title'.tr,
      );
      return;
    }
    if (ctrl.tenants.isEmpty) {
      UIHelper.showWarning(
        'cannot_create_contract_no_tenants'.tr,
        title: 'no_tenants_title'.tr,
      );
      return;
    }
    if (avail.isEmpty) {
      UIHelper.showWarning(
        'cannot_create_contract_no_units'.tr,
        title: 'no_available_units_title'.tr,
      );
      return;
    }
    if (ctrl.templates.isEmpty) {
      UIHelper.showWarning(
        'cannot_create_contract_no_templates'.tr,
        title: 'no_templates_title'.tr,
      );
      return;
    }

    final tid = ctrl.tenants.first.id.obs;
    final uid = avail.first.id.obs;
    final tpl = ctrl.templates.first.id.obs;
    final cur = 'YER'.obs;
    final frq = 'Monthly'.obs;

    final now = DateTime.now();
    final oneYearLater = DateTime(now.year + 1, now.month, now.day);
    final sC = TextEditingController(text: AppFormatters.todayIso());
    final eC = TextEditingController(text: AppFormatters.date(oneYearLater));
    final rC = TextEditingController();
    final dC = TextEditingController();
    final wC = TextEditingController();

    Future<void> pickDate(TextEditingController dateController) async {
      final current = DateTime.tryParse(dateController.text) ?? now;
      final picked = await showDatePicker(
        context: context,
        initialDate: current,
        firstDate: DateTime(2020),
        lastDate: DateTime(2040),
      );
      if (picked != null) {
        dateController.text = AppFormatters.date(picked);
      }
    }

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
            Text('create_contract_btn'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Obx(() => DropdownButtonFormField<String>(
              initialValue: tid.value,
              decoration: InputDecoration(labelText: 'tenant_type'.tr),
              items: ctrl.tenants.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
              onChanged: (v) => tid.value = v ?? tid.value,
            )),
            const SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<String>(
              initialValue: uid.value,
              decoration: InputDecoration(labelText: 'unit_type_label'.tr),
              items: avail.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.code} (${AppDropdownHelpers.normalizeUnitType(u.type)})'))).toList(),
              onChanged: (v) => uid.value = v ?? uid.value,
            )),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: sC,
                  readOnly: true,
                  onTap: () => pickDate(sC),
                  decoration: InputDecoration(
                    labelText: 'start_date'.tr,
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: eC,
                  readOnly: true,
                  onTap: () => pickDate(eC),
                  decoration: InputDecoration(
                    labelText: 'end_date'.tr,
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: rC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${'rent_amount'.tr} *',
                    hintText: '0.00',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                  initialValue: cur.value,
                  decoration: InputDecoration(labelText: 'currency'.tr),
                  items: const ['YER', 'SAR', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => cur.value = v ?? 'YER',
                )),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                  initialValue: AppDropdownHelpers.normalizeFrequency(frq.value),
                  decoration: InputDecoration(labelText: 'periodicity'.tr),
                  items: AppDropdownHelpers.frequencyKeys
                      .map((f) => DropdownMenuItem(value: f, child: Text(AppDropdownHelpers.frequencyLabel(f))))
                      .toList(),
                  onChanged: (v) => frq.value = v ?? 'Monthly',
                )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: dC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'deposit_amount'.tr,
                    hintText: '0.00',
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<String>(
              initialValue: tpl.value,
              decoration: InputDecoration(labelText: 'template_label'.tr),
              items: ctrl.templates.map((tp) => DropdownMenuItem(value: tp.id, child: Text(tp.name))).toList(),
              onChanged: (v) => tpl.value = v ?? tpl.value,
            )),
            const SizedBox(height: 8),
            TextField(controller: wC, decoration: InputDecoration(labelText: 'witnesses_label'.tr)),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () async {
                final rentVal = double.tryParse(rC.text.trim()) ?? 0;
                if (rentVal <= 0) {
                  UIHelper.showWarning('enter_valid_rent_amount'.tr, title: 'rent_amount'.tr);
                  return;
                }
                final sDate = DateTime.tryParse(sC.text.trim());
                final eDate = DateTime.tryParse(eC.text.trim());
                if (sDate == null || eDate == null || !eDate.isAfter(sDate)) {
                  UIHelper.showWarning('invalid_contract_dates'.tr, title: 'notice'.tr);
                  return;
                }

                final selectedTenant = ctrl.tenantById(tid.value);
                final selectedUnit = pCtrl.unitById(uid.value);

                final confirm = await UIHelper.showConfirmDialog(
                  title: 'approve_contract'.tr,
                  message: 'confirm_approve_contract'.trParams({
                    'unit': selectedUnit?.code ?? uid.value,
                    'tenant': selectedTenant?.name ?? tid.value,
                  }),
                  confirmText: 'approve_contract'.tr,
                );
                if (!confirm) return;

                final err = await ctrl.createContract(
                  unitId: uid.value,
                  tenantId: tid.value,
                  startDate: sC.text.trim(),
                  endDate: eC.text.trim(),
                  rent: rentVal,
                  currency: cur.value,
                  frequency: frq.value,
                  deposit: double.tryParse(dC.text.trim()) ?? 0,
                  templateId: tpl.value,
                  witnesses: wC.text
                      .split(RegExp(r'[,،]'))
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .map((e) => ContractWitness(name: e, detail: 'شاهد'))
                      .toList(),
                );
                if (err != null) {
                  UIHelper.showError('${'error'.tr}: $err');
                } else {
                  Get.back();
                  UIHelper.showSuccess('contract_approved_success'.tr);
                }
              },
              child: Text('approve_contract'.tr),
            ),
          ],
        ),
      ),
    ));
  }
}
