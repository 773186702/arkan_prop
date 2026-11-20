import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/utils/app_dropdown_helpers.dart';
import '../../../../core/utils/formatters.dart';
import 'package:flutter/foundation.dart';
import '../../../properties/domain/property_models.dart';
import '../../domain/contract_models.dart';

abstract final class ContractPrintHelper {
  static Future<void> printContract({
    required ContractEntity contract,
    required PropertyEntity property,
    required UnitEntity unit,
    required TenantEntity tenant,
  }) async {
    pw.Font reg;
    pw.Font bold;
    try {
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      reg = pw.Font.ttf(fontData);
      final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      bold = pw.Font.ttf(boldData);
    } catch (e) {
      debugPrint("Error loading local font for contract: $e");
      try {
        reg = await PdfGoogleFonts.cairoRegular();
        bold = await PdfGoogleFonts.cairoBold();
      } catch (_) {
        reg = pw.Font.helvetica();
        bold = pw.Font.helveticaBold();
      }
    }

    final doc = pw.Document();
    
    // دالة مساعدة لاستخدام الخط العربي في أي نص
    pw.TextStyle textStyle(double size, {bool isBold = false}) => pw.TextStyle(
      font: isBold ? bold : reg, 
      fontSize: size,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        pw.Center(child: pw.Text('بسم الله الرحمن الرحيم\nعقد إيجار عقاري (${contract.id})', textAlign: pw.TextAlign.center, style: textStyle(16, isBold: true))),
        pw.Divider(),
        pw.Text('الإنشاء: ${contract.createdDate} | السريان: ${contract.startDate} إلى ${contract.endDate}', style: textStyle(12)),
        pw.Text('الطرف الأول (المالك): مالك ${property.name}', style: textStyle(12)),
        pw.Text('الطرف الثاني (المستأجر): ${tenant.name} | هوية: ${tenant.idNum} | هاتف: ${tenant.phone}', style: textStyle(12)),
        pw.Text('الوحدة: ${unit.type} (${unit.code}) • ${unit.area} • ${property.address}', style: textStyle(12)),
        pw.Text('الأجرة: ${AppFormatters.money(contract.rent)} ${contract.currency} (${AppDropdownHelpers.frequencyLabel(contract.frequency)}) | التأمين: ${AppFormatters.money(contract.deposit)} ${contract.currency}', style: textStyle(12)),
        pw.SizedBox(height: 8),
        pw.Text('الشروط والأحكام:', style: textStyle(12, isBold: true)),
        for (var i = 0; i < contract.terms.length; i++) pw.Text('${i + 1}. ${contract.terms[i]}', style: textStyle(12)),
        pw.SizedBox(height: 8),
        pw.Text('الشهود: ${contract.witnesses.map((w) => w.name).join(' ، ')}', style: textStyle(12)),
        pw.Spacer(),
        pw.Container(padding: const pw.EdgeInsets.all(6), decoration: pw.BoxDecoration(border: pw.Border.all()), child: pw.Text('طباعة العقد لا تعني اعتماده رسمياً قبل التوقيع وختم عاقل المنطقة خارج التطبيق.', textAlign: pw.TextAlign.center, style: textStyle(9))),
        pw.SizedBox(height: 12),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [_sig('توقيع الطرف الأول', textStyle(10)), _sig('توقيع الطرف الثاني', textStyle(10)), _sig('ختم عاقل المنطقة', textStyle(10))]),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static pw.Widget _sig(String lbl, pw.TextStyle style) => pw.Container(width: 150, height: 60, padding: const pw.EdgeInsets.all(6), decoration: pw.BoxDecoration(border: pw.Border.all()), child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(lbl, style: style), pw.Text('...................', style: style)]));
}