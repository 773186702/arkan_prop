abstract final class AppConstants {
  static const String dbName = 'arkan_property_v1.db';
  static const int dbVersion = 1;
  static const int pinLength = 4;
  static const int maxPinAttempts = 5;
  static const int lockoutSeconds = 30;
  static const String defaultPin = '1234';
  static const List<String> currencies = ['YER', 'SAR', 'USD'];
  static const List<String> walletTypes = ['جيب', 'فلوسك', 'جوالي', 'ون كاش', 'كريمي', 'ايزي', 'سباء كاش', 'كاش', 'بيس', 'محفظتي'];
  static const String prefDark = 'pref_dark';
  static const String prefLocale = 'pref_locale';
  static const String secPinHash = 'arkan_pin_hash';
  static const String secFailed = 'arkan_pin_failed';
  static const String secLockUntil = 'arkan_pin_lock_until';
}