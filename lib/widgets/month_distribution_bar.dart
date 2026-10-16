import 'package:flutter/material.dart';
import '../services/calculation_service.dart';
import '../theme/app_theme.dart';

class MonthDistributionBar extends StatelessWidget {
  final MonthlyReportSummary summary;

  const MonthDistributionBar({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary.totalLoggedDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'توزيع أيام الشهر ونسب الحضور',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'متوسط: ${summary.averageDailyHours.toStringAsFixed(1)} س/يوم',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: AppTheme.fontFamily,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Multi-segmented colored progress bar
          if (total == 0)
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(999),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    if (summary.workDaysCount > 0)
                      Expanded(
                        flex: summary.workDaysCount,
                        child: Container(color: AppColors.success),
                      ),
                    if (summary.paidLeaveDaysCount > 0)
                      Expanded(
                        flex: summary.paidLeaveDaysCount,
                        child: Container(color: AppColors.paidLeave),
                      ),
                    if (summary.unpaidLeaveDaysCount > 0)
                      Expanded(
                        flex: summary.unpaidLeaveDaysCount,
                        child: Container(color: AppColors.unpaidLeave),
                      ),
                    if (summary.absentDaysCount > 0)
                      Expanded(
                        flex: summary.absentDaysCount,
                        child: Container(color: AppColors.crimson),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendItem('عمل (${summary.workDaysCount})', AppColors.success),
              _buildLegendItem('إجازة مدفوعة (${summary.paidLeaveDaysCount})', AppColors.paidLeave),
              _buildLegendItem('بدون أجر (${summary.unpaidLeaveDaysCount})', AppColors.unpaidLeave),
              _buildLegendItem('غياب (${summary.absentDaysCount})', AppColors.crimson),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ],
    );
  }
}
