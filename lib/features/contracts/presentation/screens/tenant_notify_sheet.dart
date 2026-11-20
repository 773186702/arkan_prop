import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/notification_helper.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';
import '../../../properties/presentation/controllers/properties_controller.dart';
import '../controllers/contracts_controller.dart';

void showTenantNotifySheet(BuildContext context, {String? tenantId, TenantNoticeType initialType = TenantNoticeType.overdue, String? paymentSummary}) {
  final cCtrl = Get.find<ContractsController>(), pCtrl = Get.find<PropertiesController>(), fCtrl = Get.find<FinanceController>();
  if (cCtrl.tenants.isEmpty) return;
  final selT = (tenantId ?? cCtrl.tenants.first.id).obs;
  final selType = initialType.obs;
  final msgC = TextEditingController();

  void buildMsg() {
    final t = cCtrl.tenantById(selT.value);
    if (t == null) return;
    final c = cCtrl.activeContractForTenant(t.id) ?? cCtrl.contracts.firstWhereOrNull((x) => x.tenantId == t.id);
    final u = c != null ? pCtrl.unitById(c.unitId) : null;
    final p = u != null ? pCtrl.propertyById(u.propertyId) : null;
    final unpaid = fCtrl.dues.where((d) => d.tenantId == t.id && d.remaining > 0).map((d) => {'due_type': d.dueType, 'period_label': d.periodLabel, 'due_date': d.dueDate, 'amount': d.amount, 'paid': d.paid, 'currency': d.currency}).toList();
    msgC.text = NotificationHelper.buildTenantMessage(tenantName: t.name, propertyName: p?.name ?? 'app_title'.tr, unitCode: u?.code ?? '-', contractId: c?.id ?? '-', type: selType.value, unpaidDues: unpaid, rentLabel: c != null ? '${AppFormatters.money(c.rent)} ${c.currency}' : '-', contractEndDate: c?.endDate, paymentSummary: paymentSummary);
  }
  buildMsg();

  Get.bottomSheet(Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('إرسال إشعار منسق للمستأجر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 10),
      Obx(() => DropdownButtonFormField<String>(initialValue: selT.value, decoration: const InputDecoration(labelText: 'المستأجر'), items: cCtrl.tenants.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(), onChanged: (v) { if (v != null) { selT.value = v; buildMsg(); } })),
      const SizedBox(height: 8),
      Obx(() => DropdownButtonFormField<TenantNoticeType>(initialValue: selType.value, decoration: const InputDecoration(labelText: 'نوع الإشعار'), items: const [DropdownMenuItem(value: TenantNoticeType.overdue, child: Text('تذكير متأخرات واستحقاقات')), DropdownMenuItem(value: TenantNoticeType.upcoming, child: Text('تذكير موعد قادم')), DropdownMenuItem(value: TenantNoticeType.receipt, child: Text('إيصال دفعة')), DropdownMenuItem(value: TenantNoticeType.contractExpiry, child: Text('تنبيه انتهاء عقد'))], onChanged: (v) { if (v != null) { selType.value = v; buildMsg(); } })),
      const SizedBox(height: 8),
      TextField(controller: msgC, maxLines: 6, decoration: const InputDecoration(labelText: 'الرسالة (بيانات حقيقية قابلة للتعديل)')),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white), onPressed: () async { final t = cCtrl.tenantById(selT.value); if (t != null) await NotificationHelper.openWhatsApp(t.phone, msgC.text); }, icon: const Icon(Icons.send_rounded, size: 17), label: const Text('واتساب'))),
        const SizedBox(width: 8),
        Expanded(child: FilledButton.tonalIcon(onPressed: () async { await NotificationHelper.copy(msgC.text); Get.snackbar('تم', 'تم نسخ الرسالة'); }, icon: const Icon(Icons.copy_rounded, size: 17), label: const Text('نسخ'))),
      ]),
    ])),
  ));
}