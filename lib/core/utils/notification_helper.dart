import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'formatters.dart';

enum TenantNoticeType { overdue, upcoming, receipt, contractExpiry }

abstract final class NotificationHelper {
  static String buildTenantMessage({
    required String tenantName, required String propertyName, required String unitCode,
    required String contractId, required TenantNoticeType type,
    List<Map<String, dynamic>> unpaidDues = const [], String? rentLabel, String? contractEndDate, String? paymentSummary,
  }) {
    switch (type) {
      case TenantNoticeType.overdue:
        final rentDues = <Map<String, dynamic>>[];
        final serviceDues = <Map<String, dynamic>>[];
        double totalRem = 0.0;
        String cur = '';

        for (final d in unpaidDues) {
          final rem = (d['amount'] as num) - (d['paid'] as num);
          if (rem <= 0) continue;
          totalRem += rem;
          cur = d['currency'] as String? ?? '';
          final type = d['due_type']?.toString() ?? '';
          if (type.contains('خدمة')) {
            serviceDues.add(d);
          } else {
            rentDues.add(d);
          }
        }

        final b = StringBuffer();
        if (rentDues.isNotEmpty) {
          b.writeln('📋 *أقساط الإيجار المستحقة:*');
          for (final d in rentDues) {
            final rem = (d['amount'] as num) - (d['paid'] as num);
            final late = AppFormatters.daysLate(d['due_date'] as String);
            b.writeln('  • ${d['due_type']} (${d['period_label']}): ${AppFormatters.money(rem)} ${d['currency']}${late > 0 ? ' [متأخر $late يوم]' : ''}');
          }
        }

        if (serviceDues.isNotEmpty) {
          if (rentDues.isNotEmpty) b.writeln();
          b.writeln('⚡ *رسوم واستهلاك الخدمات (ماء / كهرباء / أخرى):*');
          for (final d in serviceDues) {
            final rem = (d['amount'] as num) - (d['paid'] as num);
            b.writeln('  • ${d['due_type']} (${d['period_label']}): ${AppFormatters.money(rem)} ${d['currency']}');
          }
        }

        if (unpaidDues.isEmpty) {
          b.writeln('- لا توجد مستحقات متأخرة حالياً.');
        } else {
          b.writeln('\n💰 *الإجمالي المستحق السداد:* ${AppFormatters.money(totalRem)} $cur');
        }

        return 'السلام عليكم الأخ/الأستاذ $tenantName المحترم،\nتحية طيبة من إدارة ($propertyName).\nنود تذكيركم بفاتورة المستحقات للوحدة ($unitCode) ضمن العقد ($contractId):\n\n${b.toString().trimRight()}\n\nيمكنكم سداد الإيجار والخدمات معاً أو سداد كل بند على حدة حسب رغبتكم. نرجو تزويدنا برقم الإشعار عند التحويل.';
      case TenantNoticeType.upcoming:
        return 'السلام عليكم $tenantName، تذكير ودي بقرب موعد استحقاق الإيجار للوحدة ($unitCode) في ($propertyName) بمبلغ ${rentLabel ?? '-'}.';
      case TenantNoticeType.receipt:
        return 'السلام عليكم $tenantName، نؤكد استلام الدفعة المالية: ${paymentSummary ?? '-'}. شكراً لالتزامكم.';
      case TenantNoticeType.contractExpiry:
        return 'السلام عليكم $tenantName، نحيطكم علماً بأن عقد الوحدة ($unitCode) رقم ($contractId) ينتهي بتاريخ ${contractEndDate ?? '-'}. نرجو التواصل للتجديد أو التسليم.';
    }
  }

  static Future<void> copy(String text) => Clipboard.setData(ClipboardData(text: text));

  static Future<bool> openWhatsApp(String phone, String msg) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return false;
    return launchUrl(Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(msg)}'), mode: LaunchMode.externalApplication);
  }
}