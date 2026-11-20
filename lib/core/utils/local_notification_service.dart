import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/contracts/domain/contract_models.dart';
import '../../features/finance/domain/finance_models.dart';
import '../theme/app_settings_controller.dart';
import 'formatters.dart';

enum AppNotificationType { overdue, dueSoon, contractExpiry, general }

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final AppNotificationType type;
  final String? targetId;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.targetId,
  });
}

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  /// سجل الإشعارات التفاعلي لعرضه في شاشة الإشعارات
  static final RxList<AppNotificationItem> notificationLog = <AppNotificationItem>[].obs;
  
  static const String channelId = 'arkan_alerts_channel';
  static const String channelName = 'تنبيهات ركن العقار';
  static const String channelDescription = 'إشعارات المتأخرات ومواعيد السداد وانتهاء عقود الإيجار في ركن العقار';

  static SharedPreferences? _cachedPrefs;

  static Future<SharedPreferences> _getPrefs() async {
    if (_cachedPrefs != null) return _cachedPrefs!;
    try {
      if (Get.isRegistered<SharedPreferences>()) {
        _cachedPrefs = Get.find<SharedPreferences>();
        return _cachedPrefs!;
      }
    } catch (_) {}
    _cachedPrefs = await SharedPreferences.getInstance();
    return _cachedPrefs!;
  }

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // تفاعل عند النقر على الإشعار
      },
    );

    // إنشاء قناة إشعارات عالية الأهمية لنظام أندرويد
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      
      const androidChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      );
      await androidImplementation.createNotificationChannel(androidChannel);
    }
  }

  /// تسجيل إشعار في السجل بدون تكرار لنفس العنصر في نفس اليوم
  static void _logNotification(AppNotificationItem item) {
    final today = AppFormatters.todayIso();
    final existingIdx = notificationLog.indexWhere((n) =>
        n.targetId != null &&
        n.targetId == item.targetId &&
        n.type == item.type &&
        AppFormatters.date(n.timestamp) == today);

    if (existingIdx >= 0) {
      notificationLog[existingIdx] = item;
    } else {
      notificationLog.insert(0, item);
      if (notificationLog.length > 80) {
        notificationLog.removeRange(80, notificationLog.length);
      }
    }
  }

  /// إرسال إشعار فوري
  static Future<void> showNotification(
    int id,
    String title,
    String body, {
    String? payload,
    AppNotificationType type = AppNotificationType.general,
    String? targetId,
  }) async {
    if (_isNotificationsDisabled()) return;

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(id, title, body, details, payload: payload);

    _logNotification(
      AppNotificationItem(
        id: '${id}_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        timestamp: DateTime.now(),
        type: type,
        targetId: targetId,
      ),
    );
  }

  /// إلغاء إشعار مجدول
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// جدولة إشعار في موعد محدد في المستقبل
  static Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate, {
    String? payload,
    AppNotificationType type = AppNotificationType.general,
    String? targetId,
    bool addToLog = true,
  }) async {
    if (_isNotificationsDisabled()) return;

    if (scheduledDate.isBefore(DateTime.now())) {
      await showNotification(
        id,
        title,
        body,
        payload: payload,
        type: type,
        targetId: targetId,
      );
      return;
    }

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      if (addToLog) {
        _logNotification(
          AppNotificationItem(
            id: '${id}_${DateTime.now().millisecondsSinceEpoch}',
            title: title,
            body: '$body (مجدول في: ${AppFormatters.date(scheduledDate)})',
            timestamp: DateTime.now(),
            type: type,
            targetId: targetId,
          ),
        );
      }
    } catch (_) {
      // Fallback to instant notification if exact alarm is restricted
      await showNotification(
        id,
        title,
        body,
        payload: payload,
        type: type,
        targetId: targetId,
      );
    }
  }

  /// مزامنة وجدولة مواعيد سداد الأقساط القادمة بهدوء بدون إزعاج أو تكرار
  static Future<void> syncAndScheduleDues(List<DueEntity> dues, List<TenantEntity> tenants) async {
    if (_isNotificationsDisabled()) return;
    final prefs = await _getPrefs();
    final now = DateTime.now();

    TenantEntity? findTenant(String id) {
      try {
        return tenants.firstWhere((t) => t.id == id);
      } catch (_) {
        return null;
      }
    }

    for (final due in dues) {
      final notifId = due.id.hashCode.abs() + 200000;
      if (due.remaining <= 0) {
        // تم السداد: إلغاء أي جدولة وحذف المفتاح
        await cancelNotification(notifId);
        await prefs.remove('notif_scheduled_due_${due.id}');
        await prefs.remove('notif_overdue_${due.id}');
        continue;
      }

      final dueDate = DateTime.tryParse(due.dueDate);
      if (dueDate != null && dueDate.isAfter(now)) {
        final expectedScheduleKey = '${due.dueDate}_${due.remaining}';
        final alreadyScheduled = prefs.getString('notif_scheduled_due_${due.id}');
        if (alreadyScheduled == expectedScheduleKey) {
          // مجدول مسبقاً بنفس القيمة والموعد
          continue;
        }

        // جدولة تنبيه قبل موعد الاستحقاق بيوم واحد في الساعة 9 صباحاً
        var reminderDate = DateTime(dueDate.year, dueDate.month, dueDate.day - 1, 9, 0);
        if (reminderDate.isBefore(now)) {
          // إذا كان اليوم هو السابق للموعد أو موعد السداد، الجدولة في صباح موعد السداد
          reminderDate = DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0);
        }

        if (reminderDate.isAfter(now)) {
          final tenant = findTenant(due.tenantId);
          final title = '📅 تذكير بموعد استحقاق سداد';
          final body = 'موعد سداد قسط إيجار بقيمة ${AppFormatters.money(due.remaining)} ${due.currency} للمستأجر ${tenant?.name ?? due.tenantId} بتاريخ ${due.dueDate} (الوحدة ${due.unitId}).';

          await scheduleNotification(
            notifId,
            title,
            body,
            reminderDate,
            type: AppNotificationType.dueSoon,
            targetId: due.id,
            addToLog: false, // لا تملأ السجل قبل موعد الحدث
          );

          await prefs.setString('notif_scheduled_due_${due.id}', expectedScheduleKey);
        }
      }
    }
  }

  /// مزامنة وجدولة تنبيهات قرب انتهاء عقود الإيجار بهدوء بدون تكرار
  static Future<void> syncAndScheduleContracts(List<ContractEntity> contracts, List<TenantEntity> tenants) async {
    if (_isNotificationsDisabled()) return;
    final prefs = await _getPrefs();
    final now = DateTime.now();

    TenantEntity? findTenant(String id) {
      try {
        return tenants.firstWhere((t) => t.id == id);
      } catch (_) {
        return null;
      }
    }

    for (final contract in contracts) {
      final notifId = contract.id.hashCode.abs() + 300000;
      if (contract.status != 'Active') {
        await cancelNotification(notifId);
        await prefs.remove('notif_contract_expiry_${contract.id}');
        continue;
      }

      final endDate = DateTime.tryParse(contract.endDate);
      if (endDate != null) {
        final diffDays = endDate.difference(now).inDays;
        if (diffDays >= 0 && diffDays <= 30) {
          final stage = diffDays <= 7 ? 'urgent' : 'warning';
          final expectedKey = '${contract.endDate}_$stage';
          final alreadyNotified = prefs.getString('notif_contract_expiry_${contract.id}');
          if (alreadyNotified == expectedKey) {
            continue;
          }

          final tenant = findTenant(contract.tenantId);
          final title = diffDays <= 7 ? '🚨 تنبيه عاجل: قرب انتهاء العقد' : '⏳ تنبيه قرب انتهاء عقد الإيجار';
          final body = 'عقد الوحدة ${contract.unitId} للمستأجر ${tenant?.name ?? contract.tenantId} ينتهي بتاريخ ${contract.endDate} (متبقي $diffDays يوم).';

          if (diffDays <= 7) {
            await showNotification(
              notifId,
              title,
              body,
              type: AppNotificationType.contractExpiry,
              targetId: contract.id,
            );
          } else {
            // جدولة قبل 7 أيام من تاريخ الانتهاء
            final reminderDate = DateTime(endDate.year, endDate.month, endDate.day - 7, 9, 0);
            if (reminderDate.isAfter(now)) {
              await scheduleNotification(
                notifId,
                title,
                body,
                reminderDate,
                type: AppNotificationType.contractExpiry,
                targetId: contract.id,
                addToLog: false,
              );
            }
          }
          await prefs.setString('notif_contract_expiry_${contract.id}', expectedKey);
        }
      }
    }
  }

  /// فحص وإطلاق التنبيهات مع منع التكرار والإزعاج اليومي
  /// الحالات المعتمدة:
  /// 1. موعد سداد محدد (يجدول مسبقاً ويظهر في موعده)
  /// 2. تنبيه بالمتأخرات (يظهر مرة واحدة في اليوم لكل قسط متأخر فقط عند وجود جديد)
  /// 3. قرب انتهاء العقد (يظهر مرة واحدة عند دخول مهلة 30 يوماً أو 7 أيام)
  static Future<int> checkAndDispatchAllAlerts({
    required List<ContractEntity> contracts,
    required List<DueEntity> dues,
    required List<TenantEntity> tenants,
    bool forceInstant = false,
  }) async {
    if (_isNotificationsDisabled()) return 0;

    final prefs = await _getPrefs();
    int alertCount = 0;
    final now = DateTime.now();
    final todayIso = AppFormatters.todayIso();

    TenantEntity? findTenant(String id) {
      try {
        return tenants.firstWhere((t) => t.id == id);
      } catch (_) {
        return null;
      }
    }

    // 1. مزامنة وجدولة مواعيد السداد المستقبلية
    await syncAndScheduleDues(dues, tenants);

    // 2. مزامنة وجدولة تنبيهات قرب انتهاء العقود
    await syncAndScheduleContracts(contracts, tenants);

    // 3. فحص المتأخرات (Overdue Dues) - يُطلق إشعاراً مرة واحدة فقط في اليوم للمتأخرات
    for (final due in dues) {
      if (due.remaining > 0) {
        final daysLate = AppFormatters.daysLate(due.dueDate);
        if (daysLate > 0) {
          final expectedOverdueKey = '${todayIso}_${due.remaining}_$daysLate';
          final alreadyNotified = prefs.getString('notif_overdue_${due.id}');

          if (!forceInstant && alreadyNotified == expectedOverdueKey) {
            // تم إشعار المستخدم اليوم بالفعل بنفس المبلغ وعدد أيام التأخير
            continue;
          }

          final tenant = findTenant(due.tenantId);
          final title = '🚨 متأخرات سداد: ${tenant?.name ?? due.tenantId}';
          final body = 'يوجد قسط متأخر بقيمة ${AppFormatters.money(due.remaining)} ${due.currency} للوحدة ${due.unitId} (متأخر $daysLate يوم).';
          
          await showNotification(
            due.id.hashCode.abs() + 100000,
            title,
            body,
            type: AppNotificationType.overdue,
            targetId: due.id,
          );

          await prefs.setString('notif_overdue_${due.id}', expectedOverdueKey);
          alertCount++;
        }
      }
    }

    // 4. إذا كان الفحص يدوي فورياً (من شاشة الإشعارات عبر زر "فحص التنبيهات الآن")
    if (forceInstant) {
      // إشعار بمواعيد السداد المستحقة اليوم
      for (final due in dues) {
        if (due.remaining > 0) {
          final dueDate = DateTime.tryParse(due.dueDate);
          if (dueDate != null && dueDate.year == now.year && dueDate.month == now.month && dueDate.day == now.day) {
            final tenant = findTenant(due.tenantId);
            final title = '📅 قسط مستحق اليوم';
            final body = 'يستحق اليوم سداد قسط بقيمة ${AppFormatters.money(due.remaining)} ${due.currency} للمستأجر ${tenant?.name ?? due.tenantId} (الوحدة ${due.unitId}).';
            await showNotification(
              due.id.hashCode.abs() + 200000,
              title,
              body,
              type: AppNotificationType.dueSoon,
              targetId: due.id,
            );
            alertCount++;
          }
        }
      }
    }

    return alertCount;
  }

  static bool _isNotificationsDisabled() {
    try {
      if (Get.isRegistered<AppSettingsController>()) {
        final settings = Get.find<AppSettingsController>();
        return !settings.notificationsEnabled.value;
      }
    } catch (_) {}
    return false;
  }
}
