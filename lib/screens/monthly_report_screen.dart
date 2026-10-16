import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/daily_log.dart';
import '../providers/attendance_provider.dart';
import '../services/calculation_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/day_form_card.dart';
import '../widgets/month_distribution_bar.dart';
import '../widgets/month_stats_grid.dart';
import '../widgets/paycheck_summary_card.dart';

class MonthlyReportScreen extends StatelessWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final summary = provider.currentMonthSummary;
    final settings = provider.settings;
    final filteredResults = provider.filteredDayResults;

    final monthTitle = DateFormat('MMMM yyyy', 'ar').format(DateTime(summary.year, summary.month));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Month Selector Header Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'الشهر السابق',
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onPressed: () => provider.previousMonth(),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _showMonthYearPicker(context, provider),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: [
                            Text(
                              monthTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                            const Text(
                              'اضغط لاختيار شهر آخر',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'الشهر التالي',
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                    onPressed: () => provider.nextMonth(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Paycheck Summary Card (الكارت الكحلي المميز)
            PaycheckSummaryCard(
              summary: summary,
              settings: settings,
            ),
            const SizedBox(height: 16),

            // 3 Offline Export & Share Actions
            _buildExportActionsCard(context, summary, settings),
            const SizedBox(height: 16),

            // 4 Stats Grid
            MonthStatsGrid(
              summary: summary,
              settings: settings,
            ),
            const SizedBox(height: 16),

            // Visual Distribution Progress Bar
            MonthDistributionBar(summary: summary),
            const SizedBox(height: 20),

            // Filter Chips Bar
            Row(
              children: [
                const Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'جدول أيام الشهر',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredResults.length} من ${summary.totalLoggedDays} يوم',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: AppTheme.fontFamily,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: DayFilter.values.map((filter) {
                  final isSelected = filter == provider.currentFilter;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(filter.arabicLabel),
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                      ),
                      onSelected: (_) {
                        provider.setFilter(filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Table / List of Days for the month
            if (filteredResults.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.inbox_outlined, size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 10),
                    const Text(
                      'لا توجد أيام مطابقة لهذا الفلتر في هذا الشهر',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredResults.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final res = filteredResults[index];
                  return _buildMonthDayRow(context, res, settings);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportActionsCard(
    BuildContext context,
    MonthlyReportSummary summary,
    dynamic settings,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تصدير ومشاركة التقرير أوفلاين',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // 1: Copy WhatsApp Summary
              Expanded(
                child: _buildExportButton(
                  context: context,
                  label: 'ملخص واتساب',
                  icon: Icons.copy_rounded,
                  color: const Color(0xFF25D366),
                  onTap: () async {
                    final text = ExportService.generateWhatsAppSummary(summary, settings);
                    await ExportService.copyToClipboard(text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF1E293B),
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'تم نسخ ملخص الشهر بنجاح! جاهز للصق في واتساب.',
                            style: TextStyle(fontFamily: AppTheme.fontFamily),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 2: Export CSV (UTF-8 BOM)
              Expanded(
                child: _buildExportButton(
                  context: context,
                  label: 'Excel / CSV',
                  icon: Icons.table_chart_outlined,
                  color: const Color(0xFF107C41),
                  onTap: () async {
                    try {
                      await ExportService.shareCsv(summary, settings);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطأ أثناء التصدير: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 3: Print / PDF
              Expanded(
                child: _buildExportButton(
                  context: context,
                  label: 'تقرير PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  color: AppColors.crimson,
                  onTap: () async {
                    try {
                      await ExportService.printOrSharePdf(summary, settings);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطأ أثناء إنشاء ملف PDF: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthDayRow(
    BuildContext context,
    DayCalculationResult res,
    dynamic settings,
  ) {
    final log = res.log;
    final dayName = DateFormat('EEEE', 'ar').format(log.date);
    final dateStr = DateFormat('d MMMM', 'ar').format(log.date);

    final checkInStr = log.checkInTime != null
        ? '${log.checkInTime!.hour.toString().padLeft(2, '0')}:${log.checkInTime!.minute.toString().padLeft(2, '0')}'
        : null;
    final checkOutStr = log.checkOutTime != null
        ? '${log.checkOutTime!.hour.toString().padLeft(2, '0')}:${log.checkOutTime!.minute.toString().padLeft(2, '0')}'
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Date, Status Badge, Edit Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: log.status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(log.status.icon, color: log.status.color, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      log.status.arabicLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: log.status.color,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$dayName، $dateStr',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                tooltip: 'تعديل هذا اليوم',
                onPressed: () => _showEditDayModal(context, log),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Middle row: Times & Hours breakdown
          Row(
            children: [
              if (log.status == DayStatus.work) ...[
                if (checkInStr != null && checkOutStr != null) ...[
                  Text(
                    'من $checkInStr إلى $checkOutStr',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: AppTheme.fontFamily,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Text('  •  ', style: TextStyle(color: AppColors.divider)),
                ],
                Text(
                  '${res.actualHours.toStringAsFixed(1)} ساعة',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: AppTheme.fontFamily,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 6),
                if (res.hasOvertime)
                  Text(
                    '(+${res.overtimeHours.toStringAsFixed(1)}س إضافي)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  )
                else if (res.hasShortfall)
                  Text(
                    '(-${res.shortfallHours.toStringAsFixed(1)}س نقص)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.crimson,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
              ] else
                Text(
                  'اليومية المستحقة: ${log.status == DayStatus.paidLeave ? "${log.dailyRate.toStringAsFixed(0)} ${settings.currency}" : "0 ${settings.currency}"}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              const Spacer(),
              // Net day pay
              Text(
                '${res.netPay.toStringAsFixed(1)} ${settings.currency}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  fontFamily: AppTheme.fontFamily,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          // If there are notes or adjustments
          if (log.adjustment != 0 || log.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (log.adjustment != 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (log.adjustment > 0 ? AppColors.success : AppColors.crimson).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.adjustment > 0 ? '+${log.adjustment.toStringAsFixed(0)} مكافأة' : '${log.adjustment.toStringAsFixed(0)} سلفة/خصم',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: log.adjustment > 0 ? AppColors.success : AppColors.crimson,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                if (log.notes.isNotEmpty)
                  Expanded(
                    child: Text(
                      log.notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context, AttendanceProvider provider) {
    int tempYear = provider.selectedYear;
    int tempMonth = provider.selectedMonth;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('اختيار الشهر والسنة', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Year selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setModalState(() => tempYear--),
                    ),
                    Text(
                      '$tempYear',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setModalState(() => tempYear++),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Months Grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(12, (i) {
                    final m = i + 1;
                    final isSel = m == tempMonth;
                    final name = DateFormat('MMMM', 'ar').format(DateTime(2026, m));
                    return ChoiceChip(
                      selected: isSel,
                      label: Text(name),
                      onSelected: (_) => setModalState(() => tempMonth = m),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  provider.setSelectedMonth(tempYear, tempMonth);
                  Navigator.pop(ctx);
                },
                child: const Text('تأكيد'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDayModal(BuildContext context, DailyLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                DayFormCard(
                  initialDate: log.date,
                  onLogSaved: (_) => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
