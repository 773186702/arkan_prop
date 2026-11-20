import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_dropdown_helpers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/notification_helper.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';
import '../../../properties/presentation/controllers/properties_controller.dart';
import '../../domain/contract_models.dart';
import '../controllers/contracts_controller.dart';
import 'contract_print_helper.dart';
import 'tenant_notify_sheet.dart';

class ContractDetailScreen extends GetView<ContractsController> {
  const ContractDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cid = Get.arguments as String;
    final pCtrl = Get.find<PropertiesController>(), fCtrl = Get.find<FinanceController>();
    return Obx(() {
      final c = controller.contractById(cid);
      if (c == null) return const Scaffold();
      final u = pCtrl.unitById(c.unitId), p = u != null ? pCtrl.propertyById(u.propertyId) : null, t = controller.tenantById(c.tenantId);
      final dues = fCtrl.dues.where((d) => d.contractId == c.id).toList();
      return Scaffold(
        appBar: AppBar(
          title: Text('contract_title'.trParams({'id': c.id})),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'edit'.tr,
              onPressed: () => _editContractDlg(c),
            ),
          ],
        ),
        body: ListView(padding: const EdgeInsets.all(14), children: [
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${p?.name ?? ''} / ${u?.code ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Chip(label: Text(c.status)),
            ]),
            const SizedBox(height: 6),
            Text('${'tenant_label'.trParams({'name': t?.name ?? '-'})} | ${'unit_label'.trParams({'code': u?.code ?? '-'})}'),
            Text('${'start_date'.tr}: ${c.startDate} → ${'end_date'.tr}: ${c.endDate}'),
            const SizedBox(height: 4),
            Text('${'rent_amount'.tr}: ${AppFormatters.money(c.rent)} ${c.currency} (${AppDropdownHelpers.frequencyLabel(c.frequency)}) • ${'deposit_amount'.tr}: ${AppFormatters.money(c.deposit)} ${c.currency}'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(
                onPressed: () {
                  if (p != null && u != null && t != null) {
                    ContractPrintHelper.printContract(contract: c, property: p, unit: u, tenant: t);
                  }
                },
                icon: const Icon(Icons.print_outlined, size: 17),
                label: Text('print'.tr),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _renewDlg(c),
                icon: const Icon(Icons.autorenew_rounded, size: 17),
                label: Text('renew_contract_btn'.tr),
              ),
              OutlinedButton(
                onPressed: () async {
                  try {
                    await controller.generateNextDue(c.id);
                    UIHelper.showSuccess('success'.tr);
                  } catch (e) {
                    UIHelper.showError('${'error'.tr}: $e');
                  }
                },
                child: Text('gen_due_btn'.tr),
              ),
              if (t != null)
                OutlinedButton(
                  onPressed: () => showTenantNotifySheet(context, tenantId: t.id, initialType: TenantNoticeType.contractExpiry),
                  child: Text('notify_tenant_btn'.tr),
                ),
              if (c.status == 'Active')
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _termDlg(c),
                  child: Text('term_contract_btn'.tr),
                ),
            ]),
          ]))),
          const SizedBox(height: 10),
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('terms_header'.trParams({'count': '${c.terms.length}'}), style: const TextStyle(fontWeight: FontWeight.w800)),
              TextButton(onPressed: () => _termAddDlg(c.id), child: Text('add_term_btn'.tr)),
            ]),
            for (var i = 0; i < c.terms.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${i + 1}. ${c.terms[i]}'),
              ),
          ]))),
          const SizedBox(height: 10),
          Text('dues_header'.trParams({'count': '${dues.length}'}), style: const TextStyle(fontWeight: FontWeight.w800)),
          ...dues.map((d) => Card(
            margin: const EdgeInsets.only(top: 6),
            child: ListTile(
              title: Text('${AppFormatters.money(d.amount)} ${d.currency} (${d.periodLabel})'),
              subtitle: Text('${'start_date'.tr}: ${d.dueDate} • ${'collected'.tr}: ${AppFormatters.money(d.paid)}'),
              trailing: Chip(
                label: Text(d.status),
                backgroundColor: d.remaining <= 0
                    ? Colors.green.withValues(alpha: 0.15)
                    : (d.paid > 0 ? Colors.amber.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15)),
              ),
            ),
          )),
        ]),
      );
    });
  }

  void _editContractDlg(ContractEntity c) {
    final sC = TextEditingController(text: c.startDate), eC = TextEditingController(text: c.endDate);
    final rC = TextEditingController(text: c.rent.toString()), dC = TextEditingController(text: c.deposit.toString());
    final cur = c.currency.obs, frq = c.frequency.obs;

    Get.defaultDialog(
      title: 'edit'.tr,
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: sC, decoration: InputDecoration(labelText: 'start_date'.tr)),
          const SizedBox(height: 8),
          TextField(controller: eC, decoration: InputDecoration(labelText: 'end_date'.tr)),
          const SizedBox(height: 8),
          TextField(controller: rC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'rent_amount'.tr)),
          const SizedBox(height: 8),
          TextField(controller: dC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'deposit_amount'.tr)),
          const SizedBox(height: 8),
          Obx(() => DropdownButtonFormField<String>(
            initialValue: cur.value,
            decoration: InputDecoration(labelText: 'currency'.tr),
            items: ['YER', 'SAR', 'USD'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => cur.value = v ?? cur.value,
          )),
          const SizedBox(height: 8),
          Obx(() => DropdownButtonFormField<String>(
            initialValue: AppDropdownHelpers.normalizeFrequency(frq.value),
            decoration: InputDecoration(labelText: 'periodicity'.tr),
            items: AppDropdownHelpers.frequencyKeys
                .map((k) => DropdownMenuItem(value: k, child: Text(AppDropdownHelpers.frequencyLabel(k))))
                .toList(),
            onChanged: (v) => frq.value = v ?? frq.value,
          )),
        ]),
      ),
      textConfirm: 'save'.tr,
      textCancel: 'cancel'.tr,
      onConfirm: () async {
        final start = sC.text.trim();
        final end = eC.text.trim();
        if (start.isEmpty || end.isEmpty) {
          UIHelper.showWarning('invalid_contract_dates'.tr);
          return;
        }
        final sDate = DateTime.tryParse(start);
        final eDate = DateTime.tryParse(end);
        if (sDate == null || eDate == null || !eDate.isAfter(sDate)) {
          UIHelper.showWarning('invalid_contract_dates'.tr);
          return;
        }
        final rentVal = double.tryParse(rC.text.trim()) ?? 0;
        if (rentVal <= 0) {
          UIHelper.showWarning('enter_valid_rent_amount'.tr, title: 'rent_amount'.tr);
          return;
        }
        final confirm = await UIHelper.showConfirmDialog(
          title: 'confirm'.tr,
          message: 'confirm_renew_contract'.tr,
          confirmText: 'save'.tr,
        );
        if (confirm) {
          try {
            final updated = ContractEntity(
              id: c.id, unitId: c.unitId, tenantId: c.tenantId, createdDate: c.createdDate,
              startDate: start, endDate: end,
              rent: rentVal, currency: cur.value,
              frequency: frq.value, customInterval: c.customInterval,
              deposit: double.tryParse(dC.text.trim()) ?? c.deposit,
              graceDays: c.graceDays, status: c.status, prevContractId: c.prevContractId,
              increasePct: c.increasePct, witnesses: c.witnesses, terms: c.terms,
            );
            await controller.updateContract(updated);
            Get.back();
            UIHelper.showSuccess('contract_renewed_success'.tr);
          } catch (e) {
            UIHelper.showError('${'error'.tr}: $e');
          }
        }
      },
    );
  }

  void _termDlg(ContractEntity c) {
    final type = 'Termination'.obs;
    final aC = TextEditingController();
    final nC = TextEditingController();
    Get.defaultDialog(
      title: 'term_contract_btn'.tr,
      content: Column(children: [
        Obx(() => DropdownButtonFormField<String>(
          initialValue: type.value,
          items: ['Termination', 'Settlement'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => type.value = v ?? type.value,
        )),
        const SizedBox(height: 8),
        TextField(controller: aC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: '${'rent_amount'.tr} (${c.currency})')),
        const SizedBox(height: 8),
        TextField(controller: nC, decoration: InputDecoration(labelText: 'notes_label'.tr)),
      ]),
      textConfirm: 'confirm'.tr,
      textCancel: 'cancel'.tr,
      onConfirm: () async {
        final confirm = await UIHelper.showConfirmDialog(
          title: 'term_contract_btn'.tr,
          message: 'confirm_terminate_contract'.tr,
          isDanger: true,
          confirmText: 'term_contract_btn'.tr,
        );
        if (confirm) {
          try {
            await controller.terminate(c.id, type.value, double.tryParse(aC.text) ?? 0, nC.text.trim());
            Get.back();
            UIHelper.showSuccess('contract_terminated_success'.tr);
          } catch (e) {
            UIHelper.showError('${'error'.tr}: $e');
          }
        }
      },
    );
  }

  void _renewDlg(ContractEntity c) {
    // حساب تاريخ البداية الجديد ليكون اليوم التالي لانتهاء العقد الحالي
    DateTime startDate;
    final currentEnd = DateTime.tryParse(c.endDate);
    if (currentEnd != null) {
      startDate = currentEnd.add(const Duration(days: 1));
    } else {
      startDate = DateTime.now();
    }
    final endDate = DateTime(startDate.year + 1, startDate.month, startDate.day);

    final sC = TextEditingController(text: AppFormatters.date(startDate));
    final eC = TextEditingController(text: AppFormatters.date(endDate));
    final rC = TextEditingController(text: c.rent.toStringAsFixed(0));
    final pctC = TextEditingController(text: '0');
    final calculatedRent = c.rent.obs;

    void updateByPct() {
      final pct = double.tryParse(pctC.text.trim()) ?? 0;
      final newRent = c.rent * (1 + pct / 100);
      calculatedRent.value = newRent;
      rC.text = newRent.toStringAsFixed(0);
    }

    void updateByRent() {
      final rent = double.tryParse(rC.text.trim()) ?? c.rent;
      calculatedRent.value = rent;
      if (c.rent > 0) {
        final pct = ((rent - c.rent) / c.rent) * 100;
        pctC.text = pct.toStringAsFixed(1);
      }
    }

    Future<void> pickDate(BuildContext context, TextEditingController controller) async {
      final current = DateTime.tryParse(controller.text) ?? DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: current,
        firstDate: DateTime(2020),
        lastDate: DateTime(2040),
      );
      if (picked != null) {
        controller.text = AppFormatters.date(picked);
      }
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
                Text(
                  '${'renew_contract_btn'.tr} (${c.id})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sC,
                        readOnly: true,
                        onTap: () => pickDate(context, sC),
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
                        onTap: () => pickDate(context, eC),
                        decoration: InputDecoration(
                          labelText: 'end_date'.tr,
                          suffixIcon: const Icon(Icons.calendar_today, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pctC,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'increase_pct_label'.tr,
                          suffixText: '%',
                        ),
                        onChanged: (_) => updateByPct(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: rC,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '${'rent_amount'.tr} *',
                          suffixText: c.currency,
                        ),
                        onChanged: (_) => updateByRent(),
                      ),
                    ),
                  ],
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
                          Text('calculated_rent'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            '${AppFormatters.money(calculatedRent.value)} ${c.currency}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 14),
                FilledButton.icon(
                  icon: const Icon(Icons.autorenew_rounded),
                  label: Text('renew_contract_btn'.tr),
                  onPressed: () async {
                    final start = sC.text.trim();
                    final end = eC.text.trim();
                    if (start.isEmpty || end.isEmpty) {
                      UIHelper.showWarning('invalid_contract_dates'.tr);
                      return;
                    }
                    final sDate = DateTime.tryParse(start);
                    final eDate = DateTime.tryParse(end);
                    if (sDate == null || eDate == null || !eDate.isAfter(sDate)) {
                      UIHelper.showWarning('invalid_contract_dates'.tr);
                      return;
                    }

                    final newRent = double.tryParse(rC.text.trim()) ?? c.rent;
                    if (newRent <= 0) {
                      UIHelper.showWarning('enter_valid_rent_amount'.tr);
                      return;
                    }

                    final confirm = await UIHelper.showConfirmDialog(
                      title: 'renew_contract_btn'.tr,
                      message: 'confirm_renew_contract'.tr,
                      confirmText: 'renew_contract_btn'.tr,
                    );
                    if (confirm) {
                      try {
                        final pct = double.tryParse(pctC.text.trim()) ?? 0;
                        await controller.renew(c, start, end, newRent, pct);
                        Get.back();
                        UIHelper.showSuccess('contract_renewed_success'.tr);
                      } catch (e) {
                        UIHelper.showError('${'error'.tr}: $e');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _termAddDlg(String contractId) {
    final tC = TextEditingController();
    Get.defaultDialog(
      title: 'add_term_btn'.tr,
      content: TextField(controller: tC, decoration: InputDecoration(labelText: 'terms_header'.trParams({'count': ''}))),
      textConfirm: 'save'.tr,
      textCancel: 'cancel'.tr,
      onConfirm: () async {
        if (tC.text.trim().isEmpty) return;
        try {
          await controller.addCustomTerm(contractId, tC.text.trim());
          Get.back();
          UIHelper.showSuccess('success'.tr);
        } catch (e) {
          UIHelper.showError('${'error'.tr}: $e');
        }
      },
    );
  }
}
