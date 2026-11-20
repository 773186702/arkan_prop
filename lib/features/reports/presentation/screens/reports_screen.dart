import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_settings_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../routes/app_routes.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';
import '../../../pin/presentation/controllers/pin_controller.dart';
import '../controllers/reports_controller.dart';
import 'notifications_screen.dart';

class ReportsScreen extends GetView<ReportsController> {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fCtrl = Get.find<FinanceController>(), settings = Get.find<AppSettingsController>();
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
              ButtonSegment(value: 0, label: FittedBox(fit: BoxFit.scaleDown, child: Text('tab_reports'.tr))),
              ButtonSegment(value: 1, label: FittedBox(fit: BoxFit.scaleDown, child: Text('tab_settings'.tr))),
              ButtonSegment(value: 2, label: FittedBox(fit: BoxFit.scaleDown, child: Text('tab_audit'.tr))),
            ],
            selected: {tab},
            onSelectionChanged: (s) => controller.subTab.value = s.first,
          ),
        ),
        Expanded(
          child: switch (tab) {
            0 => ListView(padding: const EdgeInsets.all(14), children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Text('report_settings_card'.tr, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: Obx(() => TextButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(controller.startDate.value.toString().split(' ')[0]),
                                onPressed: () => controller.pickDate(context, true),
                              )),
                        ),
                        Text('to_date'.tr),
                        Expanded(
                          child: Obx(() => TextButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(controller.endDate.value.toString().split(' ')[0]),
                                onPressed: () => controller.pickDate(context, false),
                              )),
                        ),
                      ]),
                      Obx(() {
                        final reportOptions = [
                          (key: 'all_rents', label: 'report_all_rents'.tr),
                          (key: 'collected_rents', label: 'report_collected_rents'.tr),
                          (key: 'remaining_rents', label: 'report_remaining_rents'.tr),
                          (key: 'properties', label: 'report_properties'.tr),
                          (key: 'tenants', label: 'report_tenants'.tr),
                          (key: 'financial', label: 'report_financial'.tr),
                        ];
                        final currentVal = reportOptions.any((opt) => opt.key == controller.reportType.value)
                            ? controller.reportType.value
                            : 'all_rents';

                        return DropdownButton<String>(
                          isExpanded: true,
                          value: currentVal,
                          items: reportOptions
                              .map((opt) => DropdownMenuItem(value: opt.key, child: Text(opt.label)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) controller.reportType.value = val;
                          },
                        );
                      }),
                      const SizedBox(height: 10),
                      Obx(() {
                        final isFinancial = controller.reportType.value == 'financial' ||
                            controller.reportType.value == 'تقارير مالية' ||
                            controller.reportType.value == 'Financial Reports' ||
                            controller.reportType.value == 'report_financial'.tr;

                        if (!isFinancial) return const SizedBox();

                        final walletOptions = [
                          (key: 'ALL', label: 'all'.tr),
                          ...AppConstants.walletTypes.map((w) => (key: w, label: w)),
                        ];
                        final curWallet = walletOptions.any((w) => w.key == controller.selectedWallet.value)
                            ? controller.selectedWallet.value
                            : 'ALL';

                        final typeOptions = [
                          (key: 'ALL', label: 'all'.tr),
                          (key: 'income', label: 'trans_income'.tr),
                          (key: 'expense', label: 'trans_expense'.tr),
                        ];
                        final curType = typeOptions.any((t) => t.key == controller.selectedTransType.value)
                            ? controller.selectedTransType.value
                            : 'ALL';

                        final currOptions = [
                          (key: 'ALL', label: 'all'.tr),
                          (key: 'YER', label: 'YER'),
                          (key: 'SAR', label: 'SAR'),
                          (key: 'USD', label: 'USD'),
                        ];
                        final curCurrency = currOptions.any((c) => c.key == controller.selectedCurrency.value)
                            ? controller.selectedCurrency.value
                            : 'ALL';

                        return Column(children: [
                          DropdownButtonFormField<String>(
                            key: ValueKey('wallet_$curWallet'),
                            decoration: InputDecoration(labelText: 'wallet_filter'.tr),
                            initialValue: curWallet,
                            items: walletOptions.map((w) => DropdownMenuItem(value: w.key, child: Text(w.label))).toList(),
                            onChanged: (v) {
                              if (v != null) controller.selectedWallet.value = v;
                            },
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            key: ValueKey('type_$curType'),
                            decoration: InputDecoration(labelText: 'trans_type_filter'.tr),
                            initialValue: curType,
                            items: typeOptions.map((t) => DropdownMenuItem(value: t.key, child: Text(t.label))).toList(),
                            onChanged: (v) {
                              if (v != null) controller.selectedTransType.value = v;
                            },
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            key: ValueKey('curr_$curCurrency'),
                            decoration: InputDecoration(labelText: 'currency'.tr),
                            initialValue: curCurrency,
                            items: currOptions.map((c) => DropdownMenuItem(value: c.key, child: Text(c.label))).toList(),
                            onChanged: (v) {
                              if (v != null) controller.selectedCurrency.value = v;
                            },
                          ),
                        ]);
                      }),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: Text('export_pdf_btn'.tr),
                          onPressed: controller.generateReport,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                Text('currencies_title'.tr, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...AppConstants.currencies.map((c) {
                  final s = fCtrl.summaryForCurrency(c);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text('$c — ${'net_balance'.tr}: ${AppFormatters.money(s.net)} $c', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${'collected'.tr}: ${AppFormatters.money(s.collected)} | ${'pending'.tr}: ${AppFormatters.money(s.pending)}\n${'expenses'.tr}: ${AppFormatters.money(s.expenses)} | ${'collection_rate'.tr}: ${s.rate}%'),
                      isThreeLine: true,
                    ),
                  );
                }),
                Text('settlements_header'.trParams({'count': '${fCtrl.settlements.length}'}), style: const TextStyle(fontWeight: FontWeight.w800)),
                ...fCtrl.settlements.map((st) => Card(
                      child: ListTile(
                        title: Text('${st['contract_id']} • ${st['settlement_type']}'),
                        subtitle: Text('${st['settlement_date']} • ${st['notes']}'),
                        trailing: Text('${AppFormatters.money(st['amount'] as num)} ${st['currency']}'),
                      ),
                    )),
              ]),
            1 => ListView(padding: const EdgeInsets.all(14), children: [
                Card(
                  child: Column(children: [
                    Obx(() => SwitchListTile(
                          secondary: const Icon(Icons.notifications_active_outlined),
                          title: Text('enable_notifications'.tr),
                          value: settings.notificationsEnabled.value,
                          onChanged: (val) => settings.toggleNotifications(val),
                        )),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications_none),
                      title: Text('notification_log'.tr),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.to(() => const NotificationsScreen()),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.language_rounded),
                      title: Text('language'.tr),
                      subtitle: Text(settings.isArabic ? 'العربية' : 'English'),
                      trailing: FilledButton.tonal(
                        onPressed: settings.toggleLanguage,
                        child: Text('language_name'.tr),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.pin_outlined),
                      title: Text('change_pin'.tr),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.toNamed(AppRoutes.pin, arguments: PinMode.change),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.backup_outlined),
                      title: Text('backup_db'.tr),
                      subtitle: Text('backup_subtitle'.tr),
                      trailing: FilledButton(
                        onPressed: controller.exportBackup,
                        child: Text('export_backup_btn'.tr),
                      ),
                    ),
                    const Divider(height: 1),
                    // زر استعادة قاعدة البيانات المطلوب من المستخدم
                    ListTile(
                      leading: Icon(Icons.settings_backup_restore_rounded, color: AppColors.emerald),
                      title: Text('restore_db'.tr),
                      subtitle: Text('restore_subtitle'.tr),
                      trailing: FilledButton.tonal(
                        onPressed: controller.restoreBackup,
                        child: Text('restore_backup_btn'.tr),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: Text('lock_app'.tr),
                      onTap: () => Get.offAllNamed(AppRoutes.pin, arguments: PinMode.verify),
                    ),
                  ]),
                ),
              ]),
            _ => ListView(
                padding: const EdgeInsets.all(14),
                children: fCtrl.auditLogs.map((l) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.history_rounded, size: 18),
                        title: Text(l['message'] as String),
                        subtitle: Text(l['created_at'] as String),
                      ),
                    )).toList(),
              ),
          },
        ),
      ]);
    });
  }
}
