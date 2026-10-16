import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_settings.dart';
import '../models/daily_log.dart';
import 'calculation_service.dart';

class ExportService {
  /// Generates a clean, emoji-formatted Arabic summary text for WhatsApp
  static String generateWhatsAppSummary(MonthlyReportSummary summary, AppSettings settings) {
    final monthName = DateFormat('MMMM yyyy', 'ar').format(DateTime(summary.year, summary.month));
    final f = NumberFormat('#,##0.00', 'ar');

    final buffer = StringBuffer();
    buffer.writeln('📋 *تقرير الحضور والمستحقات الشهرية - تطبيق ورديتي*');
    buffer.writeln('👤 *الموظف:* ${settings.userName}');
    buffer.writeln('🗓️ *الشهر:* $monthName');
    buffer.writeln('⏰ *الوردية القياسية:* ${settings.standardHours.toStringAsFixed(0)} ساعة | *معامل الإضافي:* ${settings.overtimeMultiplier}x');
    buffer.writeln('-----------------------------------');
    buffer.writeln('💰 *صافي المستحقات النهائية:* ${f.format(summary.netMonthlyEarnings)} ${settings.currency}');
    buffer.writeln('💵 إجمالي أجر الساعات قبل السلف: ${f.format(summary.totalGrossHoursPay)} ${settings.currency}');
    if (summary.totalOvertimePay > 0) {
      buffer.writeln('➕ إجمالي ساعات إضافية: +${f.format(summary.totalOvertimePay)} ${settings.currency}');
    }
    if (summary.totalShortfallDeduction > 0) {
      buffer.writeln('➖ خصم نقص الساعات/تأخير: -${f.format(summary.totalShortfallDeduction)} ${settings.currency}');
    }
    if (summary.totalAdjustment != 0) {
      final sign = summary.totalAdjustment > 0 ? '+' : '';
      buffer.writeln('⚖️ صافي المكافآت والسلف: $sign${f.format(summary.totalAdjustment)} ${settings.currency}');
    }
    buffer.writeln('-----------------------------------');
    buffer.writeln('📊 *إحصائيات العمل والغياب:*');
    buffer.writeln('• أيام العمل الفعلية: ${summary.workDaysCount} يوم');
    buffer.writeln('• إجمالي الساعات الفعلية: ${summary.totalActualHours.toStringAsFixed(1)} ساعة (المفترض: ${summary.totalExpectedHours.toStringAsFixed(0)} ساعة)');
    final diffSign = summary.netHoursDifference >= 0 ? '+' : '';
    buffer.writeln('• صافي فرق الساعات: $diffSign${summary.netHoursDifference.toStringAsFixed(1)} ساعة');
    buffer.writeln('• إجازات مدفوعة: ${summary.paidLeaveDaysCount} يوم (${f.format(summary.totalPaidLeavePay)} ${settings.currency})');
    buffer.writeln('• إجازات بدون أجر: ${summary.unpaidLeaveDaysCount} يوم | غياب: ${summary.absentDaysCount} يوم');
    buffer.writeln('• متوسط الساعات اليومي: ${summary.averageDailyHours.toStringAsFixed(1)} ساعة/يوم');
    buffer.writeln('-----------------------------------');
    buffer.writeln('✨ _«ورديتي: وقتك محسوب.. ويوميتك بالملّيم»_');

    return buffer.toString();
  }

  /// Copies formatted summary text to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Generates CSV report string with UTF-8 BOM (\uFEFF) for Microsoft Excel compatibility
  static String generateCsv(MonthlyReportSummary summary, AppSettings settings) {
    final buffer = StringBuffer();
    // UTF-8 BOM
    buffer.write('\uFEFF');

    // Headers
    buffer.writeln(
      'التاريخ,اليوم,الحالة,من,إلى,ساعات العمل,الفرق عن 12س,اليومية,سعر الساعة,إضافي (+),خصم نقص (-),مكافأة/سلفة,الصافي اليومي,ملاحظات',
    );

    for (final res in summary.dayResults) {
      final log = res.log;
      final dayName = DateFormat('EEEE', 'ar').format(log.date);
      final checkInStr = log.checkInTime != null
          ? '${log.checkInTime!.hour.toString().padLeft(2, '0')}:${log.checkInTime!.minute.toString().padLeft(2, '0')}'
          : '-';
      final checkOutStr = log.checkOutTime != null
          ? '${log.checkOutTime!.hour.toString().padLeft(2, '0')}:${log.checkOutTime!.minute.toString().padLeft(2, '0')}'
          : '-';

      final diffStr = log.status == DayStatus.work
          ? (res.hoursDifference >= 0 ? '+${res.hoursDifference.toStringAsFixed(1)}' : res.hoursDifference.toStringAsFixed(1))
          : '0.0';

      final cleanNotes = log.notes.replaceAll(',', ' - ').replaceAll('\n', ' ');

      buffer.writeln(
        '${log.dateKey},'
        '$dayName,'
        '${log.status.arabicLabel},'
        '$checkInStr,'
        '$checkOutStr,'
        '${res.actualHours.toStringAsFixed(1)},'
        '$diffStr,'
        '${log.dailyRate.toStringAsFixed(2)},'
        '${res.hourlyRate.toStringAsFixed(2)},'
        '${res.overtimePay.toStringAsFixed(2)},'
        '${res.shortfallDeduction.toStringAsFixed(2)},'
        '${log.adjustment.toStringAsFixed(2)},'
        '${res.netPay.toStringAsFixed(2)},'
        '"$cleanNotes"',
      );
    }

    // Totals row
    buffer.writeln(
      'الإجمالي,,'
      '${summary.workDaysCount} عمل / ${summary.paidLeaveDaysCount} مدفوعة / ${summary.unpaidLeaveDaysCount + summary.absentDaysCount} أخرى,,,'
      '${summary.totalActualHours.toStringAsFixed(1)},'
      '${summary.netHoursDifference >= 0 ? "+" : ""}${summary.netHoursDifference.toStringAsFixed(1)},,,,'
      '${summary.totalOvertimePay.toStringAsFixed(2)},'
      '${summary.totalShortfallDeduction.toStringAsFixed(2)},'
      '${summary.totalAdjustment.toStringAsFixed(2)},'
      '${summary.netMonthlyEarnings.toStringAsFixed(2)},'
      '"صافي المستحقات النهائية"',
    );

    return buffer.toString();
  }

  /// Exports CSV using share_plus or file download
  static Future<void> shareCsv(MonthlyReportSummary summary, AppSettings settings) async {
    final csvContent = generateCsv(summary, settings);
    final fileName = 'wardiaty_report_${summary.year}_${summary.month.toString().padLeft(2, '0')}.csv';

    final bytes = utf8.encode(csvContent);
    final xFile = XFile.fromData(
      Uint8List.fromList(bytes),
      mimeType: 'text/csv',
      name: fileName,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        text: 'تقرير ورديتي الشهري $fileName',
      ),
    );
  }


  /// Builds a PDF document with RTL Arabic text and clean styling
  static Future<Uint8List> buildPdfBytes(MonthlyReportSummary summary, AppSettings settings) async {
    final pdf = pw.Document();

    // Load bundled Arabic font from assets
    pw.Font arabicFont;
    pw.Font arabicBoldFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/AppFont.ttf');
      final boldData = await rootBundle.load('assets/fonts/AppFont-Bold.ttf');
      arabicFont = pw.Font.ttf(fontData);
      arabicBoldFont = pw.Font.ttf(boldData);
    } catch (e) {
      debugPrint('Fallback to standard PDF font due to: $e');
      arabicFont = pw.Font.helvetica();
      arabicBoldFont = pw.Font.helveticaBold();
    }

    final theme = pw.ThemeData.withFont(
      base: arabicFont,
      bold: arabicBoldFont,
    );

    final monthName = DateFormat('MMMM yyyy', 'ar').format(DateTime(summary.year, summary.month));

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF0F172A),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ورديتي (Wardiaty)',
                        style: pw.TextStyle(
                          color: const PdfColor.fromInt(0xFFF59E0B),
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'كشف حساب الحضور واليومية الشهري',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'الموظف: ${settings.userName}',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 13),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'الشهر: $monthName',
                        style: pw.TextStyle(
                          color: const PdfColor.fromInt(0xFF14B8A6),
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Financial & hours summary cards
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFF0F766E),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'صافي القبض المستحق',
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${summary.netMonthlyEarnings.toStringAsFixed(2)} ${settings.currency}',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFF1F5F9),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'الساعات الفعلية / المفترضة',
                          style: const pw.TextStyle(color: PdfColor.fromInt(0xFF64748B), fontSize: 11),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${summary.totalActualHours.toStringAsFixed(1)} س / ${summary.totalExpectedHours.toStringAsFixed(0)} س',
                          style: pw.TextStyle(
                            color: const PdfColor.fromInt(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFF1F5F9),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'الإضافي / الخصومات',
                          style: const pw.TextStyle(color: PdfColor.fromInt(0xFF64748B), fontSize: 11),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '+${summary.totalOvertimePay.toStringAsFixed(0)} / -${summary.totalShortfallDeduction.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            color: const PdfColor.fromInt(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Days table
            pw.Text(
              'تفاصيل الأيام المسجلة',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0F172A)),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.center,
              headerAlignment: pw.Alignment.center,
              headers: [
                'التاريخ',
                'اليوم',
                'الحالة',
                'الساعات',
                'الفرق',
                'اليومية',
                'إضافي',
                'خصم',
                'مكافأة/سلفة',
                'الصافي',
              ],
              data: summary.dayResults.map((r) {
                final dayName = DateFormat('EEEE', 'ar').format(r.log.date);
                final diffStr = r.log.status == DayStatus.work
                    ? (r.hoursDifference >= 0 ? '+${r.hoursDifference.toStringAsFixed(1)}' : r.hoursDifference.toStringAsFixed(1))
                    : '-';
                return [
                  r.log.dateKey,
                  dayName,
                  r.log.status.arabicLabel,
                  r.actualHours > 0 ? r.actualHours.toStringAsFixed(1) : '-',
                  diffStr,
                  r.log.dailyRate.toStringAsFixed(0),
                  r.overtimePay > 0 ? '+${r.overtimePay.toStringAsFixed(0)}' : '-',
                  r.shortfallDeduction > 0 ? '-${r.shortfallDeduction.toStringAsFixed(0)}' : '-',
                  r.log.adjustment != 0 ? r.log.adjustment.toStringAsFixed(0) : '-',
                  r.netPay.toStringAsFixed(0),
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),
            pw.Divider(color: const PdfColor.fromInt(0xFFCBD5E1)),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '«ورديتي: وقتك محسوب.. ويوميتك بالملّيم»',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF64748B)),
                ),
                pw.Text(
                  'تم الإصدار بتاريخ: ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF94A3B8)),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Prints or saves PDF via printing package
  static Future<void> printOrSharePdf(MonthlyReportSummary summary, AppSettings settings) async {
    final bytes = await buildPdfBytes(summary, settings);
    final fileName = 'wardiaty_report_${summary.year}_${summary.month.toString().padLeft(2, '0')}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}
