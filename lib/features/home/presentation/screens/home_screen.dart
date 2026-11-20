import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_settings_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/arkan_logo.dart';
import '../../../../routes/app_routes.dart';
import '../../../contracts/presentation/controllers/contracts_controller.dart';
import '../../../contracts/presentation/screens/contracts_screen.dart';
import '../../../contracts/presentation/screens/tenant_notify_sheet.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';
import '../../../finance/presentation/screens/finance_screen.dart';
import '../../../pin/presentation/controllers/pin_controller.dart';
import '../../../properties/presentation/controllers/properties_controller.dart';
import '../../../properties/presentation/screens/properties_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();
    return Obx(() => Scaffold(
          appBar: AppBar(
            title: Row(children: [
              const ArkanLogo(size: 34),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('app_title'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis), Text('app_sub'.tr, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.5), overflow: TextOverflow.ellipsis)])),
            ]),
            actions: [
              IconButton(icon: const Icon(Icons.dark_mode_outlined), onPressed: () => settings.toggleTheme()),
              TextButton(onPressed: () => settings.toggleLanguage(), child: Text(settings.isArabic ? 'EN' : 'AR', style: const TextStyle(fontWeight: FontWeight.w800))),
              IconButton(icon: const Icon(Icons.lock_outline_rounded), onPressed: () => Get.offAllNamed(AppRoutes.pin, arguments: PinMode.verify)),
            ],
          ),
          body: IndexedStack(index: controller.currentIndex.value, children: const [_Dashboard(), PropertiesScreen(), ContractsScreen(), FinanceScreen(), ReportsScreen()]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: controller.currentIndex.value,
            onDestinationSelected: controller.setTab,
            destinations: [
              NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard_rounded), label: 'nav_home'.tr),
              NavigationDestination(icon: const Icon(Icons.apartment_outlined), selectedIcon: const Icon(Icons.apartment_rounded), label: 'nav_props'.tr),
              NavigationDestination(icon: const Icon(Icons.description_outlined), selectedIcon: const Icon(Icons.description_rounded), label: 'nav_contracts'.tr),
              NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), selectedIcon: const Icon(Icons.account_balance_wallet_rounded), label: 'nav_finance'.tr),
              NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: const Icon(Icons.bar_chart_rounded), label: 'nav_reports'.tr),
            ],
          ),
        ));
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    final pCtrl = Get.find<PropertiesController>(), cCtrl = Get.find<ContractsController>(), fCtrl = Get.find<FinanceController>(), hCtrl = Get.find<HomeController>();
    return Obx(() {
      final tot = pCtrl.units.length, rented = pCtrl.units.where((u) => u.status == 'Rented').length, occ = tot > 0 ? rented / tot : 0.0, overdue = fCtrl.overdueDues;
      return ListView(padding: const EdgeInsets.all(14), children: [
        Text('currencies_title'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AppConstants.currencies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final cur = AppConstants.currencies[i], s = fCtrl.summaryForCurrency(cur);
              final colors = cur == 'YER' ? [const Color(0xFF0B3F34), const Color(0xFF1A7864)] : cur == 'SAR' ? [const Color(0xFF16324F), const Color(0xFF1F4D78)] : [const Color(0xFF2D264B), const Color(0xFF483B7A)];
              return Container(
                width: 280, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(cur, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)), child: Text('${'collection_rate'.tr} ${s.rate}%', style: const TextStyle(color: Colors.white, fontSize: 11))),
                  ]),
                  Text('${AppFormatters.money(s.net)} $cur ${'net_balance'.tr}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _m('collected'.tr, AppFormatters.money(s.collected)),
                    _m('pending'.tr, AppFormatters.money(s.pending)),
                    _m('expenses'.tr, AppFormatters.money(s.expenses)),
                  ]),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Text('quick_actions'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        GridView.count(crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.92, children: [
          _qa(context, Icons.person_add_outlined, 'qa_tenant'.tr, () => ContractsScreen.showTenantFormSheet(context)),
          _qa(context, Icons.note_add_outlined, 'qa_contract'.tr, () => ContractsScreen.showNewContractSheet(context)),
          _qa(context, Icons.payments_outlined, 'qa_payment'.tr, () => FinanceScreen.showPaymentSheet(context)),
          _qa(context, Icons.send_rounded, 'qa_notice'.tr, () => showTenantNotifySheet(context)),
        ]),
        const SizedBox(height: 10),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${'unit_occupancy'.tr} (${(occ * 100).round()}%)', style: const TextStyle(fontWeight: FontWeight.w800)),
            TextButton(onPressed: () => hCtrl.setTab(1), child: Text('manage_units'.tr)),
          ]),
          LinearProgressIndicator(value: occ, minHeight: 7, borderRadius: BorderRadius.circular(99)),
          const SizedBox(height: 6),
          Text('rented_from_total'.trParams({'rented': '$rented', 'total': '$tot'})),
        ]))),
        const SizedBox(height: 12),
        Text('${'overdue_title'.tr} (${overdue.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        ...overdue.map((d) {
          final t = cCtrl.tenantById(d.tenantId), u = pCtrl.unitById(d.unitId), late = AppFormatters.daysLate(d.dueDate);
          return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t?.name ?? '-', style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis), 
                Text('${u?.code ?? '-'} • ${d.dueType} (${d.periodLabel})', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)
              ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${AppFormatters.money(d.remaining)} ${d.currency}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)), 
                Text('days_late'.trParams({'days': '$late'}), style: const TextStyle(color: AppColors.danger, fontSize: 11))
              ]),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white), onPressed: () { if (t != null) showTenantNotifySheet(context, tenantId: t.id); }, icon: const Icon(Icons.send_rounded, size: 16), label: Text('send_reminder'.tr))),
              const SizedBox(width: 8),
              FilledButton.tonal(onPressed: () => FinanceScreen.showPaymentSheet(context, preTenantId: d.tenantId, preCurrency: d.currency), child: Text('collect_now'.tr)),
            ]),
          ])));
        }),
      ]);
    });
  }

  Widget _m(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 10.5)), Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))]);
  Widget _qa(BuildContext ctx, IconData ico, String lbl, VoidCallback onTap) {
    final p = Theme.of(ctx).colorScheme.primary;
    return Card(child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: p.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(ico, color: p, size: 18)), const SizedBox(height: 5), Text(lbl, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))])));
  }
}