import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/localization/app_translations.dart';
import 'core/theme/app_settings_controller.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'core/utils/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs, permanent: true);
  Get.put<FlutterSecureStorage>(const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true)), permanent: true);
  final settings = AppSettingsController(prefs);
  await settings.load();
  await LocalNotificationService.init();
  Get.put<AppSettingsController>(settings, permanent: true);
  runApp(const ArkanApp());
}

class ArkanApp extends StatelessWidget {
  const ArkanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();
    return Obx(() => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'app_title'.tr,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
          translations: AppTranslations(),
          locale: Locale(settings.localeCode.value),
          fallbackLocale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: AppRoutes.splash,
          getPages: AppPages.pages,
        ));
  }
}