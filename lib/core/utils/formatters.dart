import 'package:intl/intl.dart';

abstract final class AppFormatters {
  static final NumberFormat _fmt = NumberFormat('#,##0.##', 'en_US');
  static String money(num v) => _fmt.format(v);
  static String todayIso() => DateFormat('yyyy-MM-dd').format(DateTime.now());
  static String date(DateTime d) => DateFormat('yyyy-MM-dd HH:mm').format(d);
  static String nowTs() => DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  static int daysLate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return 0;
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    return diff > 0 ? diff : 0;
  }
}