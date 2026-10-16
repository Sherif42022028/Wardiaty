import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/calculation_service.dart';
import '../theme/app_theme.dart';

class MonthStatsGrid extends StatelessWidget {
  final MonthlyReportSummary summary;
  final AppSettings settings;

  const MonthStatsGrid({
    super.key,
    required this.summary,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Card 1: Work Days & Expected Hours
            _buildStatCard(
              width: cardWidth,
              title: 'أيام العمل الفعلية',
              primaryValue: '${summary.workDaysCount} يوم',
              secondaryValue: 'المفترض: ${summary.totalExpectedHours.toStringAsFixed(0)} ساعة',
              icon: Icons.calendar_month_rounded,
              iconColor: AppColors.primary,
              badgeText: '${summary.workDaysCount > 0 ? ((summary.workDaysCount / 30) * 100).toStringAsFixed(0) : "0"}% من الشهر',
              badgeColor: AppColors.primary.withValues(alpha: 0.1),
            ),

            // Card 2: Actual Worked Hours & Net Difference
            _buildStatCard(
              width: cardWidth,
              title: 'إجمالي الساعات الفعلية',
              primaryValue: '${summary.totalActualHours.toStringAsFixed(1)} س',
              secondaryValue: summary.netHoursDifference >= 0
                  ? 'صافي زيادة: +${summary.netHoursDifference.toStringAsFixed(1)} س'
                  : 'صافي عجز: ${summary.netHoursDifference.toStringAsFixed(1)} س',
              icon: Icons.timer_outlined,
              iconColor: summary.netHoursDifference >= 0 ? AppColors.success : AppColors.crimson,
              badgeText: summary.netHoursDifference >= 0 ? 'فائض (+)' : 'عجز (-)',
              badgeColor: summary.netHoursDifference >= 0
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.crimson.withValues(alpha: 0.1),
            ),

            // Card 3: Paid Leave Days & Total Value
            _buildStatCard(
              width: cardWidth,
              title: 'إجازات مدفوعة الأجر',
              primaryValue: '${summary.paidLeaveDaysCount} يوم',
              secondaryValue: 'قيمتها: ${summary.totalPaidLeavePay.toStringAsFixed(0)} ${settings.currency}',
              icon: Icons.beach_access_rounded,
              iconColor: AppColors.paidLeave,
              badgeText: 'مدفوعة كاملة',
              badgeColor: AppColors.paidLeave.withValues(alpha: 0.1),
            ),

            // Card 4: Unpaid Leave & Absence Days
            _buildStatCard(
              width: cardWidth,
              title: 'بدون أجر وغياب',
              primaryValue: '${summary.unpaidLeaveDaysCount + summary.absentDaysCount} يوم',
              secondaryValue: '${summary.unpaidLeaveDaysCount} راحة / ${summary.absentDaysCount} غياب',
              icon: Icons.person_off_rounded,
              iconColor: AppColors.unpaidLeave,
              badgeText: 'أيام غير مدفوعة',
              badgeColor: AppColors.unpaidLeave.withValues(alpha: 0.1),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required double width,
    required String title,
    required String primaryValue,
    required String secondaryValue,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            primaryValue,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              fontFamily: AppTheme.fontFamily,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            secondaryValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
