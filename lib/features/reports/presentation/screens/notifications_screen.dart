import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/local_notification_service.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../contracts/presentation/controllers/contracts_controller.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final selectedFilter = Rx<AppNotificationType?>(null);
  bool isChecking = false;

  Future<void> _checkNow() async {
    setState(() => isChecking = true);
    try {
      final cCtrl = Get.find<ContractsController>();
      final fCtrl = Get.find<FinanceController>();
      final count = await LocalNotificationService.checkAndDispatchAllAlerts(
        contracts: cCtrl.contracts,
        dues: fCtrl.dues,
        tenants: cCtrl.tenants,
        forceInstant: true,
      );
      if (count > 0) {
        UIHelper.showSuccess('alerts_found_msg'.trParams({'n': '$count'}));
      } else {
        UIHelper.showSuccess('all_clear_msg'.tr);
      }
    } catch (e) {
      UIHelper.showError('alerts_error_msg'.trParams({'err': '$e'}));
    } finally {
      if (mounted) setState(() => isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('notifications_title'.tr),
        actions: [
          IconButton(
            icon: isChecking
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync_rounded),
            tooltip: 'check_alerts_btn'.tr,
            onPressed: isChecking ? null : _checkNow,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'clear_notifications_btn'.tr,
            onPressed: () async {
              if (LocalNotificationService.notificationLog.isEmpty) return;
              final confirm = await UIHelper.showConfirmDialog(
                title: 'clear_notifications_title'.tr,
                message: 'clear_notifications_msg'.tr,
                isDanger: true,
                confirmText: 'delete'.tr,
              );
              if (confirm) {
                LocalNotificationService.notificationLog.clear();
                UIHelper.showSuccess('notifications_cleared'.tr);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Obx(() => FilterChip(
                        label: Text('filter_all'.tr),
                        selected: selectedFilter.value == null,
                        onSelected: (_) => selectedFilter.value = null,
                      )),
                  const SizedBox(width: 8),
                  Obx(() => FilterChip(
                        avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                        label: Text('filter_overdue'.tr),
                        selected: selectedFilter.value == AppNotificationType.overdue,
                        onSelected: (_) => selectedFilter.value = AppNotificationType.overdue,
                      )),
                  const SizedBox(width: 8),
                  Obx(() => FilterChip(
                        avatar: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.blue),
                        label: Text('filter_dues'.tr),
                        selected: selectedFilter.value == AppNotificationType.dueSoon,
                        onSelected: (_) => selectedFilter.value = AppNotificationType.dueSoon,
                      )),
                  const SizedBox(width: 8),
                  Obx(() => FilterChip(
                        avatar: const Icon(Icons.timelapse_rounded, size: 16, color: Colors.amber),
                        label: Text('filter_expiry'.tr),
                        selected: selectedFilter.value == AppNotificationType.contractExpiry,
                        onSelected: (_) => selectedFilter.value = AppNotificationType.contractExpiry,
                      )),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: isChecking ? null : _checkNow,
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text('check_alerts_btn'.tr),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final list = LocalNotificationService.notificationLog.where((n) {
                if (selectedFilter.value == null) return true;
                return n.type == selectedFilter.value;
              }).toList();

              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('no_notifications_title'.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text('no_notifications_desc'.tr, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final item = list[i];
                  final (icon, color) = switch (item.type) {
                    AppNotificationType.overdue => (Icons.error_outline_rounded, AppColors.danger),
                    AppNotificationType.dueSoon => (Icons.alarm_rounded, AppColors.info),
                    AppNotificationType.contractExpiry => (Icons.access_time_rounded, AppColors.warning),
                    _ => (Icons.notifications_rounded, AppColors.emerald),
                  };

                  return Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(item.body, style: const TextStyle(fontSize: 12.5)),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.date(item.timestamp),
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontSize: 10.5, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
