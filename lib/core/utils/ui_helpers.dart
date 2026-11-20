import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';

abstract final class UIHelper {
  /// نافذة حوار تأكيد أنيقة تدعم الحذف، التعديل، والعمليات الحساسة
  static Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDanger = false,
    IconData? icon,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDanger ? AppColors.danger : AppColors.emerald).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? (isDanger ? Icons.warning_amber_rounded : Icons.help_outline_rounded),
                color: isDanger ? AppColors.danger : AppColors.emerald,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Get.back(result: false),
            child: Text(cancelText ?? 'cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isDanger ? AppColors.danger : AppColors.emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Get.back(result: true),
            child: Text(confirmText ?? 'confirm'.tr),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// إشعار نجاح بتصميم فخم متوافق مع هوية أركان
  static void showSuccess(String message, {String? title}) {
    Get.snackbar(
      title ?? 'success'.tr,
      message,
      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 26),
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.emerald,
      colorText: Colors.white,
      borderRadius: 16,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 3),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// إشعار خطأ / فشل بتصميم واضح
  static void showError(String message, {String title = 'فشل العملية'}) {
    Get.snackbar(
      title,
      message,
      icon: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 26),
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.danger,
      colorText: Colors.white,
      borderRadius: 16,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 4),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// إشعار تنبيه باللون الذهبي
  static void showWarning(String message, {String title = 'تنبيه'}) {
    Get.snackbar(
      title,
      message,
      icon: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 26),
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.gold,
      colorText: Colors.white,
      borderRadius: 16,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 3),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
