import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/utils/formatters.dart';
import '../../../contracts/presentation/controllers/contracts_controller.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';
import '../../../properties/presentation/controllers/properties_controller.dart';

class ReportGenerator {
  static Future<void> generate(String type, DateTime start, DateTime end,
      {String wallet = 'ALL',
      String transType = 'ALL',
      String currency = 'ALL'}) async {
    final doc = pw.Document();
    final fCtrl = Get.find<FinanceController>();
    final pCtrl = Get.find<PropertiesController>();
    final cCtrl = Get.find<ContractsController>();

    // تحميل الخطوط - محاولة محلية أولاً، ثم Google Fonts، ثم Helvetica
    pw.Font font;
    pw.Font bold;
    try {
      font = await _loadFontLocal('Cairo-Regular.ttf');
      bold = await _loadFontLocal('Cairo-Bold.ttf');
    } catch (_) {
      try {
        font = await PdfGoogleFonts.cairoRegular();
        bold = await PdfGoogleFonts.cairoBold();
      } catch (_) {
        font = pw.Font.helvetica();
        bold = pw.Font.helveticaBold();
      }
    }

    String typeLabel = switch (type) {
      'all_rents' || 'كافة الإيجارات' => 'كافة الإيجارات',
      'collected_rents' || 'الإيجارات المحصلة' => 'الإيجارات المحصلة',
      'remaining_rents' || 'الإيجارات المتبقية' => 'الإيجارات المتبقية',
      'properties' || 'تقارير العقارات' => 'تقارير العقارات',
      'tenants' || 'تقارير المستأجرين' => 'تقارير المستأجرين',
      'financial' || 'تقارير مالية' => 'تقارير مالية',
      _ => type,
    };

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      build: (context) {
        return [
          pw.Header(
              level: 0,
              child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('تقرير: $typeLabel',
                        style: pw.TextStyle(font: bold, fontSize: 20)),
                    pw.Text(DateTime.now().toString().split(' ')[0],
                        style: pw.TextStyle(font: font, fontSize: 10)),
                  ])),
          pw.Text(
              'من ${start.toString().split(' ')[0]} إلى ${end.toString().split(' ')[0]} | الفلتر: $wallet | النوع: $transType | العملة: $currency',
              style: pw.TextStyle(font: font)),
          pw.SizedBox(height: 20),
          _buildContent(type, fCtrl, pCtrl, cCtrl, font, bold, start, end,
              wallet, transType, currency),
        ];
      },
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static Future<pw.Font> _loadFontLocal(String name) async {
    final fontData = await rootBundle.load('assets/fonts/$name');
    return pw.Font.ttf(fontData);
  }

  static pw.Widget _buildContent(
      String type,
      FinanceController f,
      PropertiesController p,
      ContractsController c,
      pw.Font font,
      pw.Font bold,
      DateTime start,
      DateTime end,
      String wallet,
      String transType,
      String currency) {
    final isFinancial = type == 'financial' ||
        type == 'تقارير مالية' ||
        type == 'Financial Reports';
    final isProperties = type == 'properties' ||
        type == 'تقارير العقارات' ||
        type == 'Property Reports';
    final isTenants = type == 'tenants' ||
        type == 'تقارير المستأجرين' ||
        type == 'Tenant Reports';
    final isAllRents =
        type == 'all_rents' || type == 'كافة الإيجارات' || type == 'All Rentals';
    final isCollectedRents = type == 'collected_rents' ||
        type == 'الإيجارات المحصلة' ||
        type == 'Collected Rentals';
    final isRemainingRents = type == 'remaining_rents' ||
        type == 'الإيجارات المتبقية' ||
        type == 'Remaining Rentals';

    if (isFinancial) {
      // دمج المدفوعات والمصاريف في تقرير مالي شامل
      final List<List<String>> rows = [];

      // إضافة المدفوعات (دخل)
      for (final pay in f.payments) {
        if (pay.reversed) continue;
        // فلترة حسب التاريخ
        final payDate = DateTime.tryParse(pay.paymentDate);
        if (payDate != null &&
            (payDate.isBefore(start) ||
                payDate.isAfter(end.add(const Duration(days: 1))))) {
          continue;
        }
        // فلترة حسب طريقة الدفع (wallet)
        bool matchWallet = wallet == 'ALL' ||
            wallet == 'الكل' ||
            wallet == 'All' ||
            pay.method.contains(wallet);
        // فلترة حسب العملة
        bool matchCurrency = currency == 'ALL' ||
            currency == 'الكل' ||
            currency == 'All' ||
            pay.currency == currency;
        // فلترة حسب النوع
        bool matchType = transType == 'ALL' ||
            transType == 'الكل' ||
            transType == 'All' ||
            transType == 'income' ||
            transType == 'دخل' ||
            transType == 'Income';

        if (matchWallet && matchCurrency && matchType) {
          final tenant = c.tenantById(pay.tenantId);
          rows.add([
            tenant?.name ?? pay.tenantId,
            'دخل (إيجار)',
            AppFormatters.money(pay.amount),
            pay.currency,
          ]);
        }
      }

      // إضافة المصاريف
      for (final exp in f.expenses) {
        // فلترة حسب التاريخ
        final expDate = DateTime.tryParse(exp.date);
        if (expDate != null &&
            (expDate.isBefore(start) ||
                expDate.isAfter(end.add(const Duration(days: 1))))) {
          continue;
        }
        // فلترة حسب العملة
        bool matchCurrency = currency == 'ALL' ||
            currency == 'الكل' ||
            currency == 'All' ||
            exp.currency == currency;
        // فلترة حسب النوع
        bool matchType = transType == 'ALL' ||
            transType == 'الكل' ||
            transType == 'All' ||
            transType == 'expense' ||
            transType == 'صرف' ||
            transType == 'Expense';

        if (matchCurrency && matchType) {
          rows.add([
            exp.category,
            'مصروف',
            AppFormatters.money(exp.amount),
            exp.currency,
          ]);
        }
      }

      if (rows.isEmpty) {
        return pw.Text('لا توجد بيانات مالية في الفترة المحددة.',
            style: pw.TextStyle(font: font));
      }

      return pw.TableHelper.fromTextArray(
        headers: ['البيان', 'النوع', 'المبلغ', 'العملة'],
        data: rows,
        cellStyle: pw.TextStyle(font: font),
        headerStyle: pw.TextStyle(font: bold),
      );
    }

    if (isProperties) {
      final props = p.properties;
      if (props.isEmpty) {
        return pw.Text('لا توجد عقارات مسجلة.',
            style: pw.TextStyle(font: font));
      }
      return pw.TableHelper.fromTextArray(
        headers: ['اسم العقار', 'الرمز', 'الحالة', 'الوحدات'],
        data: props
            .map((pr) => [
                  pr.name,
                  pr.code,
                  pr.status,
                  p.unitsForProperty(pr.id).length.toString()
                ])
            .toList(),
        cellStyle: pw.TextStyle(font: font),
        headerStyle: pw.TextStyle(font: bold),
      );
    }

    if (isTenants) {
      final tenants = c.tenants;
      if (tenants.isEmpty) {
        return pw.Text('لا يوجد مستأجرون مسجلون.',
            style: pw.TextStyle(font: font));
      }
      return pw.TableHelper.fromTextArray(
        headers: ['اسم المستأجر', 'رقم الهاتف', 'الهوية'],
        data: tenants.map((t) => [t.name, t.phone, t.idNum]).toList(),
        cellStyle: pw.TextStyle(font: font),
        headerStyle: pw.TextStyle(font: bold),
      );
    }

    if (isAllRents ||
        isCollectedRents ||
        isRemainingRents ||
        type.contains('الإيجارات')) {
      final dues = f.dues
          .where((d) =>
              isAllRents ||
              (isRemainingRents ? d.remaining > 0 : d.remaining == 0))
          .toList();
      if (dues.isEmpty) {
        return pw.Text('لا توجد مستحقات في الفترة المحددة.',
            style: pw.TextStyle(font: font));
      }
      return pw.TableHelper.fromTextArray(
        headers: ['المستأجر', 'الوحدة', 'المبلغ', 'المدفوع', 'المتبقي'],
        data: dues
            .map((d) => [
                  c.tenantById(d.tenantId)?.name ?? '-',
                  p.unitById(d.unitId)?.code ?? '-',
                  AppFormatters.money(d.amount),
                  AppFormatters.money(d.amount - d.remaining),
                  AppFormatters.money(d.remaining)
                ])
            .toList(),
        cellStyle: pw.TextStyle(font: font),
        headerStyle: pw.TextStyle(font: bold),
      );
    }

    return pw.Text('يرجى اختيار تقرير لعرض محتواه.',
        style: pw.TextStyle(font: font));
  }
}
