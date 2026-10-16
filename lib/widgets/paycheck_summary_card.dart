import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_settings.dart';
import '../services/calculation_service.dart';
import '../theme/app_theme.dart';

class PaycheckSummaryCard extends StatelessWidget {
  final MonthlyReportSummary summary;
  final AppSettings settings;

  const PaycheckSummaryCard({
    super.key,
    required this.summary,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy', 'ar').format(DateTime(summary.year, summary.month));
    final f = NumberFormat('#,##0.0', 'ar');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary,
            Color(0xFF1E293B),
            AppColors.secondaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryDark.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative bank chip & subtle circle
          Positioned(
            left: -30,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.accent, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'كشف حساب إلكتروني',
                    style: TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card header: User name & month
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.primaryLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        Text(
                          'تقرير شهر $monthName',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Main Metric: Net Monthly Earnings (صافي المستحقات النهائية)
                const Text(
                  'صافي المستحقات النهائية لشهر الحساب:',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      f.format(summary.netMonthlyEarnings),
                      style: const TextStyle(
                        color: Color(0xFF34D399), // Bright success emerald
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontFamily: AppTheme.fontFamily,
                        letterSpacing: 0.5,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      settings.currency,
                      style: const TextStyle(
                        color: AppColors.accentLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                Text(
                  'إجمالي أجر الساعات والأيام قبل السلف: ${f.format(summary.totalGrossHoursPay)} ${settings.currency}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontFamily: AppTheme.fontFamily,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),

                const SizedBox(height: 18),
                const Divider(color: Color(0xFF334155), height: 1),
                const SizedBox(height: 14),

                // 3 Sub-Metrics Row: Overtime (+) | Shortfall (-) | Adjustments (⚖️)
                Row(
                  children: [
                    Expanded(
                      child: _buildSubMetric(
                        title: 'ساعات إضافية (+)',
                        value: '+${f.format(summary.totalOvertimePay)}',
                        currency: settings.currency,
                        color: const Color(0xFF34D399),
                        icon: Icons.add_circle_outline_rounded,
                      ),
                    ),
                    Container(height: 36, width: 1, color: const Color(0xFF334155)),
                    Expanded(
                      child: _buildSubMetric(
                        title: 'خصم نقص الساعات (-)',
                        value: '-${f.format(summary.totalShortfallDeduction)}',
                        currency: settings.currency,
                        color: const Color(0xFFF87171),
                        icon: Icons.remove_circle_outline_rounded,
                      ),
                    ),
                    Container(height: 36, width: 1, color: const Color(0xFF334155)),
                    Expanded(
                      child: _buildSubMetric(
                        title: 'صافي سلف/مكافأة',
                        value: '${summary.totalAdjustment >= 0 ? "+" : ""}${f.format(summary.totalAdjustment)}',
                        currency: settings.currency,
                        color: summary.totalAdjustment >= 0 ? AppColors.accentLight : const Color(0xFFF87171),
                        icon: Icons.swap_horiz_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric({
    required String title,
    required String value,
    required String currency,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: AppTheme.fontFamily,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
