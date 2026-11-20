import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../routes/app_routes.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';
import '../controllers/contracts_controller.dart';
import 'contracts_screen.dart';
import 'tenant_notify_sheet.dart';
import '../../../../core/utils/ui_helpers.dart';

class TenantDetailScreen extends GetView<ContractsController> {
  const TenantDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tid = Get.arguments as String;
    final fCtrl = Get.find<FinanceController>();
    return Obx(() {
      final t = controller.tenantById(tid);
      if (t == null) return const Scaffold();
      final dues = fCtrl.dues.where((d) => d.tenantId == tid).toList();
      final cs = controller.contracts.where((c) => c.tenantId == tid).toList();
      return Scaffold(
        appBar: AppBar(
          title: Text(t.name), 
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'edit_tenant'.tr,
              onPressed: () => ContractsScreen.showTenantFormSheet(context, edit: t),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red), 
              tooltip: 'delete_tenant'.tr,
              onPressed: () async {
                final confirm = await UIHelper.showConfirmDialog(
                  title: 'delete_tenant'.tr,
                  message: 'delete_tenant_msg'.trParams({'name': t.name}),
                  isDanger: true,
                  confirmText: 'delete'.tr,
                );
                if (confirm) {
                  try {
                    await controller.deleteTenant(t.id);
                    Get.back();
                    UIHelper.showSuccess('tenant_deleted_success'.tr);
                  } catch (e) {
                    UIHelper.showError('${'error'.tr}: $e');
                  }
                }
              },
            ),
          ],
        ),
        body: ListView(padding: const EdgeInsets.all(14), children: [
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${t.type} • ${'national_id'.tr}: ${t.idNum}'),
            Text('${'phone_number'.tr}: ${t.phone} | ${'alt_phone_number'.tr}: ${t.altPhone}'),
            Text('${'prop_addr'.tr}: ${t.address} | Email: ${t.email}'),
            if (t.job.isNotEmpty) Text('${'job_title'.tr}: ${t.job}'),
            if (t.type == 'tenant_family'.tr || t.type == 'عائلة') Text('${'family_members_count'.tr}: ${t.familyMembers}'),
            if (t.notes.isNotEmpty) Text('${'notes_label'.tr}: ${t.notes}'),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
              onPressed: () => showTenantNotifySheet(context, tenantId: t.id),
              icon: const Icon(Icons.send_rounded, size: 17),
              label: Text('notify_tenant_btn'.tr),
            ),
          ]))),
          const SizedBox(height: 12),
          Text('save_as_advance'.tr, style: const TextStyle(fontWeight: FontWeight.w800)),
          Row(children: AppConstants.currencies.map((c) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [Text(c), Text(AppFormatters.money(fCtrl.tenantAdvanceCredit(t.id, c)), style: const TextStyle(fontWeight: FontWeight.w800))]))))).toList()),
          const SizedBox(height: 12),
          Text('dues_header'.trParams({'count': '${dues.length}'}), style: const TextStyle(fontWeight: FontWeight.w800)),
          ...dues.map((d) => Card(margin: const EdgeInsets.only(top: 6), child: ListTile(title: Text('${d.dueType} • ${d.periodLabel}'), subtitle: Text('${'contract_title'.trParams({'id': d.contractId})} | ${d.dueDate}'), trailing: Text('${AppFormatters.money(d.remaining)} ${d.currency}', style: TextStyle(fontWeight: FontWeight.w700, color: d.remaining == 0 ? AppColors.success : AppColors.danger))))),
          const SizedBox(height: 12),
          Text('tab_contracts'.trParams({'count': '${cs.length}'}), style: const TextStyle(fontWeight: FontWeight.w800)),
          ...cs.map((c) => Card(margin: const EdgeInsets.only(top: 6), child: ListTile(title: Text('${c.id} • ${c.status}'), subtitle: Text('${c.startDate} → ${c.endDate}'), trailing: const Icon(Icons.chevron_right), onTap: () => Get.toNamed(AppRoutes.contractDetail, arguments: c.id)))),
        ]),
      );
    });
  }
}
