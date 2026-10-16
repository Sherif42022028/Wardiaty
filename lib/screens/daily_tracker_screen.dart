import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/daily_log.dart';
import '../providers/attendance_provider.dart';
import '../services/calculation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/day_form_card.dart';
import '../widgets/live_punch_card.dart';
import '../widgets/rate_header_card.dart';

class DailyTrackerScreen extends StatefulWidget {
  const DailyTrackerScreen({super.key});

  @override
  State<DailyTrackerScreen> createState() => _DailyTrackerScreenState();
}

class _DailyTrackerScreenState extends State<DailyTrackerScreen> {
  final GlobalKey<DayFormCardState> _formKey = GlobalKey<DayFormCardState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToFormAndLoad(DateTime date) {
    _formKey.currentState?.loadDate(date);
    // Smooth scroll down to the form
    _scrollController.animateTo(
      420,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final recentLogs = provider.recentLogs;
    final settings = provider.settings;

    return RefreshIndicator(
      onRefresh: () async {
        await provider.init();
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Rate & Shift Header Card
            const RateHeaderCard(),
            const SizedBox(height: 16),

            // Live Punch In/Out Card (Gauge + Timer)
            LivePunchCard(
              onShiftSaved: () {
                // Refresh form if today
                _formKey.currentState?.loadDate(DateTime.now());
              },
            ),
            const SizedBox(height: 16),

            // Day Entry & Modification Form Card
            DayFormCard(
              key: _formKey,
              onLogSaved: (log) {
                setState(() {});
              },
            ),

            const SizedBox(height: 24),

            // Recent 7 Days Header
            Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'آخر 7 أيام مسجلة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const Spacer(),
                Text(
                  'اضغط على أي يوم لتعديله',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recent 7 Days List
            if (recentLogs.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_note_rounded, size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 10),
                    const Text(
                      'لا توجد سجلات بعد',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'سجل حضورك اليوم أو استخدم النموذج أعلاه لإضافة أيام سابقة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentLogs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final log = recentLogs[index];
                  final result = CalculationService.calculateDay(log, settings);
                  return _buildRecentDayCard(log, result, settings);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDayCard(
    DailyLog log,
    DayCalculationResult res,
    dynamic settings,
  ) {
    final dayName = DateFormat('EEEE', 'ar').format(log.date);
    final dateStr = DateFormat('d MMMM yyyy', 'ar').format(log.date);

    return InkWell(
      onTap: () => _scrollToFormAndLoad(log.date),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status Icon circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: log.status.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(log.status.icon, color: log.status.color, size: 20),
            ),
            const SizedBox(width: 12),

            // Date & Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: log.status.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log.status.arabicLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: log.status.color,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                      if (log.status == DayStatus.work) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${res.actualHours.toStringAsFixed(1)} ساعة',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontFamily: AppTheme.fontFamily,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (res.hasOvertime) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(+${res.overtimeHours.toStringAsFixed(1)}س)',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ] else if (res.hasShortfall) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(-${res.shortfallHours.toStringAsFixed(1)}س)',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.crimson,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Net Pay
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${res.netPay.toStringAsFixed(0)} ${settings.currency}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    fontFamily: AppTheme.fontFamily,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                const Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
