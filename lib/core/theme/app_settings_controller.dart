import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AppSettingsController extends GetxController {
  AppSettingsController(this._prefs);
  final SharedPreferences _prefs;
  final isDarkMode = false.obs;
  final localeCode = 'ar'.obs;
  bool get isArabic => localeCode.value == 'ar';

  final notificationsEnabled = true.obs;
  static const _prefNotif = 'pref_notif';

  Future<void> load() async {
    isDarkMode.value = _prefs.getBool(AppConstants.prefDark) ?? false;
    localeCode.value = _prefs.getString(AppConstants.prefLocale) ?? 'ar';
    notificationsEnabled.value = _prefs.getBool(_prefNotif) ?? true;
  }

  Future<void> toggleNotifications(bool val) async {
    notificationsEnabled.value = val;
    await _prefs.setBool(_prefNotif, val);
  }

  Future<void> toggleTheme([bool? val]) async {
    final next = val ?? !isDarkMode.value;
    isDarkMode.value = next;
    await _prefs.setBool(AppConstants.prefDark, next);
    Get.changeThemeMode(next ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleLanguage() async {
    final next = isArabic ? 'en' : 'ar';
    localeCode.value = next;
    await _prefs.setString(AppConstants.prefLocale, next);
    await Get.updateLocale(Locale(next));
  }
}