import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../contracts/presentation/controllers/contracts_controller.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';
import '../../../properties/presentation/controllers/properties_controller.dart';
import 'report_generator.dart';

class ReportsController extends GetxController {
  final subTab = 0.obs;
  var startDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  var endDate = DateTime.now().obs;
  var reportType = 'all_rents'.obs;

  Future<void> exportBackup() async {
    final path = await AppDatabase.instance.getDbPath();
    await Share.shareXFiles([XFile(path)], text: 'backup_share_text'.tr);
  }

  Future<void> restoreBackup() async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'select_backup_dialog'.tr,
        type: FileType.any,
      );
      if (result == null || result.files.single.path == null) return;
      final filePath = result.files.single.path!;

      final confirm = await UIHelper.showConfirmDialog(
        title: 'confirm_restore_db'.tr,
        message: 'confirm_restore_msg'.tr,
        isDanger: true,
        confirmText: 'restore_now'.tr,
      );

      if (confirm) {
        await AppDatabase.instance.restoreDatabase(filePath);
        // تحديث جميع وحدات التحكم بالبيانات
        await Get.find<PropertiesController>().loadAll();
        await Get.find<ContractsController>().loadAll();
        await Get.find<FinanceController>().loadAll();
        UIHelper.showSuccess('db_restored_success'.tr);
      }
    } catch (e) {
      UIHelper.showError('${'db_restore_failed'.tr}: $e');
    }
  }

  Future<void> pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: isStart ? startDate.value : endDate.value,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) {
      if (isStart) {
        startDate.value = picked;
      } else {
        endDate.value = picked;
      }
    }
  }

  var selectedWallet = 'ALL'.obs;
  var selectedTransType = 'ALL'.obs;
  var selectedCurrency = 'ALL'.obs;

  Future<void> generateReport() async {
    try {
      await ReportGenerator.generate(
        reportType.value, 
        startDate.value, 
        endDate.value,
        wallet: selectedWallet.value,
        transType: selectedTransType.value,
        currency: selectedCurrency.value
      );
    } catch (e) {
      UIHelper.showError('${'error'.tr}: $e');
    }
  }
}
