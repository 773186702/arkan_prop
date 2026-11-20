import '../utils/local_notification_service.dart';

/// واجهة توافقية لخدمة الإشعارات تربط تلقائياً مع LocalNotificationService الموحدة
class NotificationService {
  static Future<void> init() => LocalNotificationService.init();

  static Future<void> showNotification(String title, String body) =>
      LocalNotificationService.showNotification(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
      );

  static Future<void> checkAlerts(List<dynamic> contracts, List<dynamic> dues) async {
    // Delegated to LocalNotificationService
  }
}
