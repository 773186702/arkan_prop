import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_dropdown_helpers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/notification_helper.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../contracts/presentation/controllers/contracts_controller.dart';
import '../../../contracts/presentation/screens/tenant_notify_sheet.dart';
import '../../../properties/presentation/controllers/properties_controller.dart';
import '../../domain/finance_models.dart';
import '../controllers/finance_controller.dart';

class FinanceScreen extends GetView<FinanceController> {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.subTab.value;
      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: [
              ButtonSegment(value: 0, label: FittedBox(fit: BoxFit.scaleDown, child: Text('seg_dues'.tr))),
              ButtonSegment(value: 1, label: FittedBox(fit: BoxFit.scaleDown, child: Text('seg_payments'.tr))),
              ButtonSegment(value: 2, label: FittedBox(fit: BoxFit.scaleDown, child: Text('seg_accounts'.tr))),
              ButtonSegment(value: 3, label: FittedBox(fit: BoxFit.scaleDown, child: Text('seg_expenses'.tr))),
            ],
            selected: {tab},
            onSelectionChanged: (s) => controller.subTab.value = s.first,
          ),
        ),
        Expanded(
          child: switch (tab) {
            0 => _dues(context),
            1 => _pays(context),
            2 => _accs(context),
            _ => _exps(context),
          },
        ),
      ]);
    });
  }

  Widget _dues(BuildContext context) {
    final cCtrl = Get.find<ContractsController>(), pCtrl = Get.find<PropertiesController>();
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        FilledButton.icon(
          onPressed: () => showPaymentSheet(context),
          icon: const Icon(Icons.payments_outlined),
          label: Text('record_payment_title'.tr),
        ),
        const SizedBox(height: 10),
        if (controller.dues.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('no_dues_registered'.tr),
            ),
          ),
        ...controller.dues.map((d) {
          final late = d.remaining > 0 ? AppFormatters.daysLate(d.dueDate) : 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text('${d.id} • ${cCtrl.tenantById(d.tenantId)?.name ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${pCtrl.unitById(d.unitId)?.code ?? '-'} • ${d.dueType} (${d.periodLabel})\n${'date_label'.tr}: ${d.dueDate}${late > 0 ? ' • ' + 'days_late'.trParams({'days': '$late'}) : ''}'),
              isThreeLine: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${AppFormatters.money(d.remaining)} ${d.currency}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: d.remaining == 0 ? AppColors.success : AppColors.danger,
                    ),
                  ),
                  Text(
                    d.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: d.remaining == 0 ? AppColors.success : (d.paid > 0 ? AppColors.warning : AppColors.danger),
                    ),
                  ),
                ],
              ),
              onTap: d.remaining > 0
                  ? () => showPaymentSheet(
                        context,
                        preTenantId: d.tenantId,
                        preCurrency: d.currency,
                        preDueId: d.id,
                        preAmount: d.remaining,
                      )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _pays(BuildContext context) {
    final cCtrl = Get.find<ContractsController>();
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        FilledButton.icon(
          onPressed: () => showPaymentSheet(context),
          icon: const Icon(Icons.add_card_rounded),
          label: Text('record_payment_title'.tr),
        ),
        const SizedBox(height: 10),
        if (controller.payments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('no_payments_registered'.tr),
            ),
          ),
        ...controller.payments.map((p) {
          final acc = controller.accounts.firstWhereOrNull((a) => a.id == p.accountId);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${p.id} • ${cCtrl.tenantById(p.tenantId)?.name ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                        '${AppFormatters.money(p.amount)} ${p.currency}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: p.reversed ? AppColors.danger : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${'payment_method'.tr}: ${p.method} • ${'seg_accounts'.tr}: ${acc?.name ?? '-'} | ${'ref_number'.tr}: ${p.refNumber} | ${p.paymentDate}'),
                  if (p.notes.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('${'notes_label'.tr}: ${p.notes}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Chip(
                          label: Text(p.reversed ? 'payment_status_reversed'.tr : 'payment_status_approved'.tr),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: (p.reversed ? AppColors.danger : AppColors.success).withValues(alpha: 0.15),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'edit_payment_tooltip'.tr,
                          onPressed: () => _editPaymentSheet(context, p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          tooltip: 'delete_payment_tooltip'.tr,
                          onPressed: () => _deletePayment(p),
                        ),
                        TextButton(
                          onPressed: () => showTenantNotifySheet(
                            context,
                            tenantId: p.tenantId,
                            initialType: TenantNoticeType.receipt,
                            paymentSummary: '${p.id} - ${AppFormatters.money(p.amount)} ${p.currency}',
                          ),
                          child: Text('send_receipt_btn'.tr),
                        ),
                        if (!p.reversed)
                          TextButton(
                            onPressed: () => _reversePayment(p),
                            child: Text('reverse_btn'.tr, style: const TextStyle(color: AppColors.danger)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _accs(BuildContext context) {
    final curFilter = 'ALL'.obs;
    return Obx(() {
      final allAccounts = controller.accounts;
      final yerBal = allAccounts.where((a) => a.currency == 'YER').fold<double>(0, (s, a) => s + controller.accountBalance(a));
      final sarBal = allAccounts.where((a) => a.currency == 'SAR').fold<double>(0, (s, a) => s + controller.accountBalance(a));
      final usdBal = allAccounts.where((a) => a.currency == 'USD').fold<double>(0, (s, a) => s + controller.accountBalance(a));

      final filtered = curFilter.value == 'ALL'
          ? allAccounts
          : allAccounts.where((a) => a.currency == curFilter.value).toList();

      return ListView(
        padding: const EdgeInsets.all(14),
        children: [
          FilledButton.icon(
            onPressed: () => _showAccountSheet(context),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: Text('add_account_btn'.tr),
          ),
          const SizedBox(height: 12),
          // ملخص إجمالي الأرصدة لكل عملة بشكل مستقل
          Row(
            children: [
              Expanded(
                child: _currencySummaryCard(
                  context,
                  title: 'YER',
                  amount: yerBal,
                  color: AppColors.emerald,
                  isSelected: curFilter.value == 'YER',
                  onTap: () => curFilter.value = curFilter.value == 'YER' ? 'ALL' : 'YER',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _currencySummaryCard(
                  context,
                  title: 'SAR',
                  amount: sarBal,
                  color: const Color(0xFF1976D2),
                  isSelected: curFilter.value == 'SAR',
                  onTap: () => curFilter.value = curFilter.value == 'SAR' ? 'ALL' : 'SAR',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _currencySummaryCard(
                  context,
                  title: 'USD',
                  amount: usdBal,
                  color: const Color(0xFFE65100),
                  isSelected: curFilter.value == 'USD',
                  onTap: () => curFilter.value = curFilter.value == 'USD' ? 'ALL' : 'USD',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // شريط فلترة العملات
          SegmentedButton<String>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: [
              ButtonSegment(value: 'ALL', label: FittedBox(fit: BoxFit.scaleDown, child: Text('tab_all_currencies'.tr))),
              ButtonSegment(value: 'YER', label: FittedBox(fit: BoxFit.scaleDown, child: Text('tab_yer'.tr))),
              ButtonSegment(value: 'SAR', label: FittedBox(fit: BoxFit.scaleDown, child: Text('tab_sar'.tr))),
              ButtonSegment(value: 'USD', label: FittedBox(fit: BoxFit.scaleDown, child: Text('tab_usd'.tr))),
            ],
            selected: {curFilter.value},
            onSelectionChanged: (s) => curFilter.value = s.first,
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('لا توجد صناديق أو حسابات مضافة لهذه العملة'),
              ),
            ),
          ...filtered.map((a) {
            final bal = controller.accountBalance(a);
            final isCash = a.type == 'Cash';
            final isWallet = a.type == 'E-Wallet';
            final icon = isCash
                ? Icons.payments_outlined
                : (isWallet ? Icons.phone_android_rounded : Icons.account_balance_outlined);
            final color = a.currency == 'YER'
                ? AppColors.emerald
                : (a.currency == 'SAR' ? const Color(0xFF1976D2) : const Color(0xFFE65100));

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(
                                '${a.provider} • ${a.accountRef.isEmpty ? '-' : a.accountRef}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${AppFormatters.money(bal)} ${a.currency}',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isCash ? 'account_type_cash'.tr : (isWallet ? 'account_type_wallet'.tr : 'account_type_bank'.tr),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _reconcileDlg(a, bal),
                          icon: const Icon(Icons.balance_rounded, size: 16),
                          label: Text('reconcile_btn'.tr),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'edit_account_btn'.tr,
                          onPressed: () => _showAccountSheet(context, edit: a),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          tooltip: 'delete_account_btn'.tr,
                          onPressed: () => _deleteAccount(a),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _currencySummaryCard(
    BuildContext context, {
    required String title,
    required double amount,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor.withValues(alpha: 0.2),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppFormatters.money(amount),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountSheet(BuildContext context, {FinancialAccountEntity? edit}) {
    final nameC = TextEditingController(text: edit?.name ?? '');
    final provC = TextEditingController(text: edit?.provider ?? '');
    final refC = TextEditingController(text: edit?.accountRef ?? '');
    final openBalC = TextEditingController(text: edit != null ? edit.openingBalance.toString() : '0');
    final cur = (edit?.currency ?? 'YER').obs;
    final type = (edit?.type ?? 'Cash').obs;

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
              Text(
                edit == null ? 'add_account_btn'.tr : 'edit_account_btn'.tr,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameC,
                decoration: InputDecoration(
                  labelText: '${'account_name'.tr} *',
                  hintText: 'مثال: صندوق الرياض (كاش)',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Obx(() => DropdownButtonFormField<String>(
                          value: cur.value,
                          decoration: InputDecoration(labelText: 'currency_label'.tr),
                          items: AppConstants.currencies
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => cur.value = v ?? 'YER',
                        )),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() => DropdownButtonFormField<String>(
                          value: type.value,
                          decoration: InputDecoration(labelText: 'account_type'.tr),
                          items: [
                            DropdownMenuItem(value: 'Cash', child: Text('account_type_cash'.tr)),
                            DropdownMenuItem(value: 'E-Wallet', child: Text('account_type_wallet'.tr)),
                            DropdownMenuItem(value: 'Bank', child: Text('account_type_bank'.tr)),
                          ],
                          onChanged: (v) => type.value = v ?? 'Cash',
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: provC,
                decoration: InputDecoration(
                  labelText: 'account_provider'.tr,
                  hintText: 'مثال: خزنة المكتب، بنك الرياض، محفظة STC Pay',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: refC,
                decoration: InputDecoration(
                  labelText: 'account_ref_label'.tr,
                  hintText: 'رقم الخزنة أو الحساب أو المحفظة',
                ),
              ),
              if (edit == null) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: openBalC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'opening_balance'.tr,
                    hintText: '0.00',
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  final name = nameC.text.trim();
                  if (name.isEmpty) {
                    UIHelper.showWarning('enter_valid_name'.tr, title: 'account_name'.tr);
                    return;
                  }
                  final openBal = double.tryParse(openBalC.text.trim()) ?? 0;
                  if (openBal < 0) {
                    UIHelper.showWarning('الرصيد الافتتاحي لا يمكن أن يكون سالباً');
                    return;
                  }

                  if (edit == null) {
                    final newAcc = FinancialAccountEntity(
                      id: 'FA_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      type: type.value,
                      provider: provC.text.trim().isEmpty ? 'خزنة المكتب' : provC.text.trim(),
                      accountRef: refC.text.trim().isEmpty ? '-' : refC.text.trim(),
                      currency: cur.value,
                      openingBalance: openBal,
                      status: 'نشط',
                    );
                    final err = await controller.addAccount(newAcc);
                    Get.back();
                    if (err != null) {
                      UIHelper.showError(err);
                    } else {
                      UIHelper.showSuccess('تمت إضافة الصندوق/الحساب بنجاح');
                    }
                  } else {
                    final updatedAcc = FinancialAccountEntity(
                      id: edit.id,
                      name: name,
                      type: type.value,
                      provider: provC.text.trim().isEmpty ? edit.provider : provC.text.trim(),
                      accountRef: refC.text.trim().isEmpty ? edit.accountRef : refC.text.trim(),
                      currency: cur.value,
                      openingBalance: edit.openingBalance,
                      status: edit.status,
                    );
                    final err = await controller.updateAccount(updatedAcc);
                    Get.back();
                    if (err != null) {
                      UIHelper.showError(err);
                    } else {
                      UIHelper.showSuccess('تم تحديث بيانات الصندوق/الحساب بنجاح');
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

  void _deleteAccount(FinancialAccountEntity a) async {
    final confirm = await UIHelper.showConfirmDialog(
      title: 'delete_account_btn'.tr,
      message: 'delete_account_confirm'.tr,
      isDanger: true,
      confirmText: 'delete'.tr,
    );
    if (confirm) {
      final err = await controller.deleteAccount(a.id);
      if (err != null) {
        UIHelper.showError(err);
      } else {
        UIHelper.showSuccess('تم حذف الحساب بنجاح');
      }
    }
  }

  Widget _exps(BuildContext context) => ListView(
        padding: const EdgeInsets.all(14),
        children: [
          FilledButton.icon(
            onPressed: () => showExpenseSheet(context),
            icon: const Icon(Icons.receipt_long_outlined),
            label: Text('record_expense_title'.tr),
          ),
          const SizedBox(height: 10),
          if (controller.expenses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('no_expenses_registered'.tr),
              ),
            ),
          ...controller.expenses.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.category, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                        '-${AppFormatters.money(e.amount)} ${e.currency}',
                        style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('${e.targetLabel} • ${'expense_bearer'.tr}: ${e.bearer} • ${'date_label'.tr}: ${e.date}'),
                      if (e.notes.isNotEmpty) Text('${'notes_label'.tr}: ${e.notes}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'edit_expense_tooltip'.tr,
                        onPressed: () => _editExpenseSheet(context, e),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        tooltip: 'delete_expense_tooltip'.tr,
                        onPressed: () => _deleteExpense(e),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      );

  void _reconcileDlg(FinancialAccountEntity a, double book) {
    final c = TextEditingController(text: '$book');
    Get.defaultDialog(
      title: 'reconcile_title'.trParams({'name': a.name}),
      content: Column(children: [
        Text('book_balance'.trParams({'amt': '${AppFormatters.money(book)} ${a.currency}'})),
        const SizedBox(height: 8),
        TextField(controller: c, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'actual_balance'.tr)),
      ]),
      textConfirm: 'confirm_reconcile_btn'.tr,
      textCancel: 'cancel'.tr,
      onConfirm: () async {
        try {
          await controller.reconcileAccount(a.id, (double.tryParse(c.text) ?? book) - book);
          Get.back();
          UIHelper.showSuccess('reconcile_success'.tr);
        } catch (e) {
          UIHelper.showError('reconcile_failed'.trParams({'err': '$e'}));
        }
      },
    );
  }

  void _editExpenseSheet(BuildContext context, ExpenseEntity e) {
    final pCtrl = Get.find<PropertiesController>();
    final catC = TextEditingController(text: e.category);
    final amtC = TextEditingController(text: e.amount.toString());
    final nC = TextEditingController(text: e.notes);
    final dateC = TextEditingController(text: e.date);
    final cur = e.currency.obs;
    // Normalize bearer to canonical key
    final bear = AppDropdownHelpers.normalizeBearer(e.bearer).obs;
    // Normalize target label: if it matches 'general_mgmt_expense' translation in any lang, use canonical
    final tgt = e.targetLabel.obs;

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
              Text('edit_expense_title'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              TextField(controller: catC, decoration: InputDecoration(labelText: '${'expense_category'.tr} *')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: amtC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'amount_label'.tr))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() => DropdownButtonFormField<String>(
                          value: cur.value,
                          items: AppConstants.currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => cur.value = v ?? cur.value,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: dateC, decoration: InputDecoration(labelText: 'expense_date_label'.tr)),
              const SizedBox(height: 8),
              Obx(() {
                // Build target items with canonical stable value
                final generalKey = 'GENERAL_MGMT';
                final allItems = [
                  DropdownMenuItem(value: generalKey, child: Text('general_mgmt_expense'.tr)),
                  ...pCtrl.properties.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))),
                ];
                // Normalize stored tgt: if it matches any translation of 'general_mgmt_expense', use generalKey
                final normalizedTgt = (tgt.value == 'مصروف عام للإدارة' ||
                        tgt.value == 'General Management Expense' ||
                        tgt.value == generalKey)
                    ? generalKey
                    : tgt.value;
                final safeVal = allItems.any((i) => i.value == normalizedTgt) ? normalizedTgt : generalKey;
                return DropdownButtonFormField<String>(
                  value: safeVal,
                  decoration: InputDecoration(labelText: 'expense_target'.tr),
                  items: allItems,
                  onChanged: (v) => tgt.value = v ?? tgt.value,
                );
              }),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                    value: bear.value,
                    decoration: InputDecoration(labelText: 'expense_bearer'.tr),
                    items: AppDropdownHelpers.bearerKeys
                        .map((k) => DropdownMenuItem(value: k, child: Text(AppDropdownHelpers.bearerLabel(k))))
                        .toList(),
                    onChanged: (v) => bear.value = v ?? bear.value,
                  )),
              const SizedBox(height: 8),
              TextField(controller: nC, decoration: InputDecoration(labelText: 'notes_label'.tr)),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  final amt = double.tryParse(amtC.text) ?? 0;
                  if (amt <= 0) {
                    UIHelper.showWarning('enter_valid_amount'.tr);
                    return;
                  }
                  final confirm = await UIHelper.showConfirmDialog(
                    title: 'confirm_edit_expense_title'.tr,
                    message: 'confirm_edit_expense_msg'.tr,
                    confirmText: 'save'.tr,
                  );
                  if (confirm) {
                    // Resolve tgt back: if 'GENERAL_MGMT' use translated label to store
                    final finalTgt = tgt.value == 'GENERAL_MGMT' ? 'general_mgmt_expense'.tr : tgt.value;
                    final err = await controller.updateExpense(ExpenseEntity(
                      id: e.id,
                      date: dateC.text.trim().isEmpty ? e.date : dateC.text.trim(),
                      category: catC.text.trim().isEmpty ? e.category : catC.text.trim(),
                      amount: amt,
                      currency: cur.value,
                      accountId: e.accountId,
                      targetLabel: finalTgt,
                      bearer: bear.value,
                      notes: nC.text.trim(),
                    ));
                    if (err != null) {
                      UIHelper.showError('$err');
                    } else {
                      Get.back();
                      UIHelper.showSuccess('expense_updated_success'.tr);
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

  void _deleteExpense(ExpenseEntity e) async {
    final confirm = await UIHelper.showConfirmDialog(
      title: 'delete_expense_title'.tr,
      message: 'delete_expense_msg'.tr,
      isDanger: true,
      confirmText: 'delete'.tr,
    );
    if (confirm) {
      final err = await controller.deleteExpense(e.id);
      if (err != null) {
        UIHelper.showError('$err');
      } else {
        UIHelper.showSuccess('expense_deleted_success'.tr);
      }
    }
  }

  void _editPaymentSheet(BuildContext context, PaymentEntity p) {
    final dateC = TextEditingController(text: p.paymentDate);
    final refC = TextEditingController(text: p.refNumber);
    final notesC = TextEditingController(text: p.notes);
    // Normalize stored method to canonical key
    final method = AppDropdownHelpers.normalizePaymentMethod(p.method).obs;
    final accId = p.accountId.obs;

    final accs = controller.accounts.where((a) => a.currency == p.currency).toList();

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
              Text('edit_payment_title'.trParams({'id': p.id}), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text('payment_amount_immutable_note'.trParams({'amt': '${AppFormatters.money(p.amount)} ${p.currency}'})),
              const SizedBox(height: 8),
              TextField(controller: dateC, decoration: InputDecoration(labelText: 'payment_date_label'.tr)),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                    value: method.value,
                    decoration: InputDecoration(labelText: 'payment_method'.tr),
                    items: AppDropdownHelpers.paymentMethodKeys
                        .map((k) => DropdownMenuItem(value: k, child: Text(AppDropdownHelpers.paymentMethodLabel(k))))
                        .toList(),
                    onChanged: (v) => method.value = v ?? method.value,
                  )),
              const SizedBox(height: 8),
              if (accs.isNotEmpty)
                Obx(() => DropdownButtonFormField<String>(
                      value: accs.any((a) => a.id == accId.value) ? accId.value : accs.first.id,
                      decoration: InputDecoration(labelText: 'receiving_account'.tr),
                      items: accs.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                      onChanged: (v) => accId.value = v ?? accId.value,
                    )),
              const SizedBox(height: 8),
              TextField(controller: refC, decoration: InputDecoration(labelText: 'ref_number'.tr)),
              const SizedBox(height: 8),
              TextField(controller: notesC, decoration: InputDecoration(labelText: 'notes_label'.tr)),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  final confirm = await UIHelper.showConfirmDialog(
                    title: 'confirm_edit_payment_title'.tr,
                    message: 'confirm_edit_payment_msg'.tr,
                    confirmText: 'save'.tr,
                  );
                  if (confirm) {
                    final err = await controller.updatePayment(
                      paymentId: p.id,
                      paymentDate: dateC.text.trim().isEmpty ? p.paymentDate : dateC.text.trim(),
                      method: method.value,
                      accountId: accId.value,
                      refNumber: refC.text.trim().isEmpty ? '-' : refC.text.trim(),
                      notes: notesC.text.trim(),
                    );
                    if (err != null) {
                      UIHelper.showError('$err');
                    } else {
                      Get.back();
                      UIHelper.showSuccess('payment_updated_success'.tr);
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

  void _reversePayment(PaymentEntity p) async {
    final confirm = await UIHelper.showConfirmDialog(
      title: 'reverse_payment_title'.tr,
      message: 'reverse_payment_msg'.tr,
      isDanger: true,
      confirmText: 'reverse_btn'.tr,
    );
    if (confirm) {
      try {
        await controller.reversePayment(p.id);
        UIHelper.showSuccess('payment_reversed_success'.tr);
      } catch (e) {
        UIHelper.showError('$e');
      }
    }
  }

  void _deletePayment(PaymentEntity p) async {
    final confirm = await UIHelper.showConfirmDialog(
      title: 'delete_payment_title'.tr,
      message: 'delete_payment_msg'.tr,
      isDanger: true,
      confirmText: 'delete'.tr,
    );
    if (confirm) {
      final err = await controller.deletePayment(p.id);
      if (err != null) {
        UIHelper.showError('$err');
      } else {
        UIHelper.showSuccess('payment_deleted_success'.tr);
      }
    }
  }

  static void showPaymentSheet(BuildContext context, {String? preTenantId, String? preCurrency, String? preDueId, double? preAmount}) {
    final ctrl = Get.find<FinanceController>(), cCtrl = Get.find<ContractsController>();
    if (cCtrl.tenants.isEmpty) {
      UIHelper.showWarning('no_tenants_for_payment'.tr);
      return;
    }
    // Use canonical keys for method to avoid mismatch with translated items
    final tid = (preTenantId ?? cCtrl.tenants.first.id).obs;
    final cur = (preCurrency ?? 'YER').obs;
    final met = AppDropdownHelpers.paymentMethodKeys.first.obs; // 'Cash'
    final mode = (preDueId != null ? 'manual' : 'auto').obs, walletType = ''.obs;
    final defaultAmt = preAmount != null ? preAmount.toStringAsFixed(0) : '120000';
    final amtC = TextEditingController(text: defaultAmt), refC = TextEditingController(), notesC = TextEditingController();
    final manualCtrls = <String, TextEditingController>{};
    if (preDueId != null && preAmount != null) {
      manualCtrls[preDueId] = TextEditingController(text: preAmount.toStringAsFixed(0));
    }
    final accId = (ctrl.accounts.firstWhereOrNull((a) => a.currency == cur.value)?.id ?? ctrl.accounts.first.id).obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
        child: SingleChildScrollView(child: Obx(() {
          final accs = ctrl.accounts.where((a) => a.currency == cur.value).toList();
          if (accs.isNotEmpty && !accs.any((a) => a.id == accId.value)) {
            // Auto-select cashbox if method is cash, or first account
            final match = met.value == 'Cash'
                ? (accs.firstWhereOrNull((x) => x.type == 'Cash') ?? accs.first)
                : (accs.firstWhereOrNull((x) => x.type == 'E-Wallet' || x.type == 'Bank') ?? accs.first);
            accId.value = match.id;
          }
          final amt = double.tryParse(amtC.text) ?? 0;
          final autoPlan = ctrl.computeAutoPlan(tid.value, cur.value, amt);
          final openDues = ctrl.dues.where((d) => d.tenantId == tid.value && d.currency == cur.value && d.remaining > 0).toList();

          // قائمة المحافظ المرنة حسب العملة المختارة
          final List<String> availableWallets = cur.value == 'SAR'
              ? const ['STC Pay', 'Urpay', 'Alinma Pay', 'Tiqmo', 'حساب الراجحي', 'حساب الأهلي', 'تحويل صرافة', 'أخرى']
              : (cur.value == 'USD'
                  ? const ['محفظة رقمية', 'PayPal', 'حساب بنكي', 'Binance / USDT', 'تحويل صرافة', 'أخرى']
                  : AppConstants.walletTypes);

          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('record_payment_title'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: tid.value,
              decoration: InputDecoration(labelText: '${'tenant_name'.tr} *'),
              items: cCtrl.tenants.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
              onChanged: (v) => tid.value = v ?? tid.value,
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: amtC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${'amount_label'.tr} *',
                    hintText: '0.00',
                  ),
                  onChanged: (_) => cur.refresh(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: cur.value,
                  decoration: InputDecoration(labelText: '${'currency_label'.tr} *'),
                  items: AppConstants.currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      cur.value = v;
                      final matchAccs = ctrl.accounts.where((a) => a.currency == v).toList();
                      if (matchAccs.isNotEmpty) {
                        accId.value = matchAccs.first.id;
                      }
                    }
                  },
                ),
              ),
            ]),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
                value: met.value,
                decoration: InputDecoration(labelText: '${'payment_method'.tr} *'),
                items: AppDropdownHelpers.paymentMethodKeys
                    .map((k) => DropdownMenuItem(value: k, child: Text(AppDropdownHelpers.paymentMethodLabel(k))))
                    .toList(),
                onChanged: (v) {
                  met.value = v ?? AppDropdownHelpers.paymentMethodKeys.first;
                  if (v != 'E-Wallet') {
                    walletType.value = '';
                  } else {
                    walletType.value = availableWallets.first;
                  }
                  final matchAccs = ctrl.accounts.where((a) => a.currency == cur.value).toList();
                  if (matchAccs.isNotEmpty) {
                    final preferred = v == 'Cash'
                        ? matchAccs.firstWhereOrNull((x) => x.type == 'Cash')
                        : matchAccs.firstWhereOrNull((x) => x.type == 'E-Wallet' || x.type == 'Bank');
                    if (preferred != null) accId.value = preferred.id;
                  }
                }),
            if (met.value == 'E-Wallet') ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: '${'wallet_type'.tr} (${cur.value})'),
                value: availableWallets.contains(walletType.value) ? walletType.value : availableWallets.first,
                items: availableWallets.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                onChanged: (v) => walletType.value = v ?? '',
              ),
            ],
            const SizedBox(height: 8),
            TextField(controller: refC, decoration: InputDecoration(labelText: 'ref_number'.tr)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: accs.any((a) => a.id == accId.value) ? accId.value : (accs.isNotEmpty ? accs.first.id : null),
              decoration: InputDecoration(
                labelText: '${'receiving_account'.tr} (${cur.value}) *',
                helperText: accs.isEmpty ? 'لا يوجد صندوق أو حساب مضاف لهذه العملة، يرجى إضافته' : null,
              ),
              items: accs.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.type})'))).toList(),
              onChanged: (v) {
                if (v != null) accId.value = v;
              },
            ),
            const SizedBox(height: 8),
            TextField(controller: notesC, decoration: InputDecoration(labelText: 'notes_label'.tr)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(value: mode.value, decoration: InputDecoration(labelText: 'allocation'.tr), items: [DropdownMenuItem(value: 'auto', child: Text('alloc_auto'.tr)), DropdownMenuItem(value: 'manual', child: Text('alloc_manual'.tr))], onChanged: (v) => mode.value = v ?? 'auto'),
            const SizedBox(height: 8),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: mode.value == 'auto'
                        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('preview_allocation'.tr, style: const TextStyle(fontWeight: FontWeight.w700)), if (autoPlan.isEmpty) Text('save_as_advance'.tr), ...autoPlan.map((a) => Text('• ${a.dueId}: +${AppFormatters.money(a.amount)} ${cur.value}'))])
                        : Column(children: openDues.map((d) {
                            final mc = manualCtrls.putIfAbsent(d.id, () => TextEditingController(text: '0'));
                            return Row(children: [Expanded(child: Text('${d.id} • ${d.dueType} (${AppFormatters.money(d.remaining)} ${cur.value})')), SizedBox(width: 85, child: TextField(controller: mc, keyboardType: TextInputType.number))]);
                          }).toList()))),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: () async {
                  final finalAmt = double.tryParse(amtC.text.trim()) ?? 0;
                  if (finalAmt <= 0) {
                    UIHelper.showWarning('enter_valid_payment_amount'.tr, title: 'amount_label'.tr);
                    return;
                  }
                  if (accs.isEmpty || accId.value.isEmpty) {
                    UIHelper.showWarning('يرجى اختيار أو إضافة صندوق/حساب لهذه العملة أولاً', title: 'receiving_account'.tr);
                    return;
                  }
                  final allocs = mode.value == 'auto'
                      ? ctrl.computeAutoPlan(tid.value, cur.value, finalAmt)
                      : openDues.map((d) => PaymentAllocationItem(dueId: d.id, amount: double.tryParse(manualCtrls[d.id]?.text ?? '0') ?? 0)).where((a) => a.amount > 0).toList();

                  if (mode.value == 'manual' && allocs.isEmpty) {
                    UIHelper.showWarning('يرجى تحديد مبالغ التخصيص للمستحقات في الوضع اليدوي');
                    return;
                  }

                  final methodLabel = AppDropdownHelpers.paymentMethodLabel(met.value) + (walletType.value.isNotEmpty ? ' (${walletType.value})' : '');
                  final err = await ctrl.savePayment(tid.value, finalAmt, cur.value, methodLabel, accId.value, refC.text.trim(), mode.value, allocs);
                  if (err != null) {
                    UIHelper.showError('$err');
                  } else {
                    Get.back();
                    UIHelper.showSuccess('payment_saved_success'.tr);
                  }
                },
                child: Text('save'.tr),
              ),
            ]);
        })),
      ),
      isScrollControlled: true,
    );
  }

  static void showExpenseSheet(BuildContext context) {
    final ctrl = Get.find<FinanceController>(), pCtrl = Get.find<PropertiesController>();
    final catC = TextEditingController(), amtC = TextEditingController(text: '15000'), nC = TextEditingController();
    // Use canonical keys for all dropdowns
    final cur = 'YER'.obs;
    final bear = AppDropdownHelpers.bearerKeys.first.obs; // 'Owner'
    final tgt = 'GENERAL_MGMT'.obs; // canonical key for general expense
    final method = AppDropdownHelpers.paymentMethodKeys.first.obs; // 'Cash'
    final walletType = ''.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('record_expense_title'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              TextField(controller: catC, decoration: InputDecoration(labelText: '${'expense_category'.tr} *')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: amtC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'amount_label'.tr))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() => DropdownButtonFormField<String>(
                          value: cur.value,
                          items: AppConstants.currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => cur.value = v ?? 'YER',
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(() {
                final generalKey = 'GENERAL_MGMT';
                final allItems = [
                  DropdownMenuItem(value: generalKey, child: Text('general_mgmt_expense'.tr)),
                  ...pCtrl.properties.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))),
                ];
                return DropdownButtonFormField<String>(
                  value: tgt.value,
                  decoration: InputDecoration(labelText: 'expense_target'.tr),
                  items: allItems,
                  onChanged: (v) => tgt.value = v ?? generalKey,
                );
              }),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                    value: bear.value,
                    decoration: InputDecoration(labelText: 'expense_bearer'.tr),
                    items: AppDropdownHelpers.bearerKeys
                        .map((k) => DropdownMenuItem(value: k, child: Text(AppDropdownHelpers.bearerLabel(k))))
                        .toList(),
                    onChanged: (v) => bear.value = v ?? AppDropdownHelpers.bearerKeys.first,
                  )),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                    value: method.value,
                    decoration: InputDecoration(labelText: 'payment_method'.tr),
                    items: AppDropdownHelpers.paymentMethodKeys
                        .map((k) => DropdownMenuItem(value: k, child: Text(AppDropdownHelpers.paymentMethodLabel(k))))
                        .toList(),
                    onChanged: (v) {
                      method.value = v ?? AppDropdownHelpers.paymentMethodKeys.first;
                      if (v != 'E-Wallet') walletType.value = '';
                    },
                  )),
              Obx(() => method.value == 'E-Wallet'
                  ? Column(children: [
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'wallet_type'.tr),
                        value: walletType.value.isEmpty ? AppConstants.walletTypes.first : walletType.value,
                        items: AppConstants.walletTypes.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                        onChanged: (v) => walletType.value = v ?? '',
                      ),
                    ])
                  : const SizedBox()),
              const SizedBox(height: 8),
              TextField(controller: nC, decoration: InputDecoration(labelText: 'notes_label'.tr)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  if (catC.text.trim().isEmpty) {
                    UIHelper.showWarning('يرجى إدخال بند أو تصنيف المصروف', title: 'expense_category'.tr);
                    return;
                  }
                  final amt = double.tryParse(amtC.text.trim()) ?? 0;
                  if (amt <= 0) {
                    UIHelper.showWarning('enter_valid_expense_amount'.tr, title: 'amount_label'.tr);
                    return;
                  }
                  final acc = ctrl.accounts.firstWhereOrNull((a) => a.currency == cur.value) ?? ctrl.accounts.first;
                  // Resolve tgt: 'GENERAL_MGMT' → translated label; otherwise use as-is (property name)
                  final finalTgt = tgt.value == 'GENERAL_MGMT' ? 'general_mgmt_expense'.tr : tgt.value;
                  // Resolve method to translated label for storage
                  final finalMethod = AppDropdownHelpers.paymentMethodLabel(method.value) + (walletType.value.isNotEmpty ? ' (${walletType.value})' : '');
                  try {
                    await ctrl.addExpense(
                      catC.text.trim(),
                      amt,
                      cur.value,
                      acc.id,
                      finalTgt,
                      bear.value,
                      nC.text.trim(),
                    );
                    Get.back();
                    UIHelper.showSuccess('expense_saved_success'.tr);
                  } catch (e) {
                    UIHelper.showError('$e');
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
