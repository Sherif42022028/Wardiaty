import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../theme/app_theme.dart';
import 'circular_shift_gauge.dart';

class LivePunchCard extends StatelessWidget {
  final VoidCallback? onShiftSaved;

  const LivePunchCard({super.key, this.onShiftSaved});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final isActive = provider.hasActiveShift;
    final activeShift = provider.activeShift;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Gauge with live second ticks
            CircularShiftGauge(
              activeShift: activeShift,
              currentTime: provider.currentTime,
              settings: provider.settings,
              liveAccruedEarnings: provider.liveAccruedEarnings,
              size: 220,
            ),
            const SizedBox(height: 18),

            // Active Shift Status banner
            if (isActive) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm_on_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'بدأت الوردية في الساعة ${activeShift!.startHour.toString().padLeft(2, '0')}:${activeShift.startMinute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.textSecondary,
                      ),
                      onPressed: () => _confirmCancelShift(context, provider),
                      child: const Text('إلغاء', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons Row: Punch In & Punch Out
            Row(
              children: [
                // Button 1: Check In (حضور)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.divider,
                      disabledForegroundColor: AppColors.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: isActive ? 0 : 3,
                    ),
                    onPressed: isActive
                        ? null
                        : () async {
                            await provider.startShiftNow();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    'تم تسجيل حضور الوردية بنجاح! بدأ احتساب الساعات والمستحقات.',
                                    style: TextStyle(fontFamily: AppTheme.fontFamily),
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: const Text(
                      'تسجيل حضور الآن',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Button 2: Check Out (انصراف)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.crimson,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.divider,
                      disabledForegroundColor: AppColors.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: isActive ? 3 : 0,
                    ),
                    onPressed: !isActive
                        ? null
                        : () async {
                            final log = await provider.endShiftNow();
                            onShiftSaved?.call();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.secondary,
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    'تم تسجيل الانصراف وحفظ يوم العمل (${log.actualHours.toStringAsFixed(1)} ساعة)!',
                                    style: const TextStyle(fontFamily: AppTheme.fontFamily),
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text(
                      'تسجيل انصراف الآن',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancelShift(BuildContext context, AttendanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إلغاء الوردية النشطة؟', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'هل تريد إلغاء هذه الوردية دون حفظ السجل؟ يمكنك البدء مجدداً في أي وقت.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
            onPressed: () {
              provider.cancelActiveShift();
              Navigator.pop(ctx);
            },
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );
  }
}
