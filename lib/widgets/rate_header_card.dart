import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../theme/app_theme.dart';
import 'wardiaty_logo_widget.dart';

class RateHeaderCard extends StatelessWidget {
  final VoidCallback? onEditRate;

  const RateHeaderCard({super.key, this.onEditRate});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final settings = provider.settings;
    final now = provider.currentTime;

    final arabicDateStr = DateFormat('EEEE، d MMMM yyyy', 'ar').format(now);
    final hourlyRate = settings.defaultHourlyRate;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Logo, App Name, Date, User greeting
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                const WardiatyLogoWidget(size: 46, useImage: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'ورديتي',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              settings.userName,
                              style: const TextStyle(
                                color: AppColors.accentLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        arabicDateStr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'تعديل اليومية الافتراضية',
                  onPressed: onEditRate ?? () => _showQuickEditRateDialog(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Glassmorphism Strip: 3 Metrics (Standard Hours | Daily Rate | Hourly Rate in Gold)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Metric 1: Shift Hours
                      Expanded(
                        child: _buildMetricItem(
                          label: 'الوردية الأساسية',
                          value: '${settings.standardHours.toStringAsFixed(0)} ساعة',
                          icon: Icons.timelapse_rounded,
                          color: Colors.white,
                        ),
                      ),
                      _buildVerticalDivider(),
                      // Metric 2: Daily Rate
                      Expanded(
                        child: _buildMetricItem(
                          label: 'حساب اليوم',
                          value: '${settings.defaultDailyRate.toStringAsFixed(0)} ${settings.currency}',
                          icon: Icons.payments_outlined,
                          color: Colors.white,
                        ),
                      ),
                      _buildVerticalDivider(),
                      // Metric 3: Golden Hourly Rate
                      Expanded(
                        child: _buildMetricItem(
                          label: 'سعر الساعة',
                          value: '${hourlyRate.toStringAsFixed(1)} ${settings.currency}',
                          icon: Icons.speed_rounded,
                          color: AppColors.accentLight,
                          isHighlight: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isHighlight = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isHighlight ? AppColors.accentLight : Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isHighlight ? AppColors.accentLight : Colors.white.withValues(alpha: 0.8),
                fontFamily: AppTheme.fontFamily,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: AppTheme.fontFamily,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  static void _showQuickEditRateDialog(BuildContext context) {
    final provider = context.read<AttendanceProvider>();
    final controller = TextEditingController(
      text: provider.settings.defaultDailyRate.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'تعديل حساب اليوم (اليومية)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'سيتم تحديث سعر الساعة تلقائياً فوراً (اليومية ÷ 12 ساعة).',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  suffixText: provider.settings.currency,
                  labelText: 'اليومية',
                ),
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
                final newRate = double.tryParse(controller.text.trim());
                if (newRate != null && newRate > 0) {
                  provider.updateSettings(
                    provider.settings.copyWith(defaultDailyRate: newRate),
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }
}
