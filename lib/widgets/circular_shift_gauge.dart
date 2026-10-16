import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/active_shift.dart';
import '../models/app_settings.dart';
import '../theme/app_theme.dart';

class CircularShiftGauge extends StatelessWidget {
  final ActiveShift? activeShift;
  final DateTime currentTime;
  final AppSettings settings;
  final double liveAccruedEarnings;
  final double size;

  const CircularShiftGauge({
    super.key,
    required this.activeShift,
    required this.currentTime,
    required this.settings,
    required this.liveAccruedEarnings,
    this.size = 230.0,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeShift != null;
    final standardHours = settings.standardHours > 0 ? settings.standardHours : 12.0;

    double progress = 0.0;
    String timeMain = '';
    String subLabel = '';

    if (isActive) {
      final elapsed = activeShift!.elapsed;
      final hours = elapsed.inHours;
      final minutes = elapsed.inMinutes.remainder(60);
      final seconds = elapsed.inSeconds.remainder(60);

      timeMain =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      final elapsedHours = activeShift!.elapsedHours;
      progress = (elapsedHours / standardHours).clamp(0.0, 1.0);
      subLabel = 'الوقت المنقضي من ${standardHours.toStringAsFixed(0)} ساعة';
    } else {
      timeMain = DateFormat('HH:mm:ss').format(currentTime);
      subLabel = 'الساعة الحالية';
      progress = 0.0;
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular Progress Track & Fill
          CustomPaint(
            size: Size(size, size),
            painter: _ShiftGaugePainter(
              progress: progress,
              isActive: isActive,
            ),
          ),

          // Central Information Display
          Padding(
            padding: EdgeInsets.all(size * 0.16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.divider,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? AppColors.success : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isActive ? 'وردية جارية' : 'في انتظار البدء',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive ? AppColors.success : AppColors.textSecondary,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Live Clock / Elapsed time
                Text(
                  timeMain,
                  style: TextStyle(
                    fontSize: size * 0.13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                    letterSpacing: 1.2,
                    fontFamily: AppTheme.fontFamily,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),

                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),

                const SizedBox(height: 6),

                // Live Accrued Earnings (if active)
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'المكتسب: ${liveAccruedEarnings.toStringAsFixed(1)} ${settings.currency}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentDark,
                        fontFamily: AppTheme.fontFamily,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  )
                else
                  Text(
                    'الوردية: ${standardHours.toStringAsFixed(0)} ساعة',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftGaugePainter extends CustomPainter {
  final double progress;
  final bool isActive;

  _ShiftGaugePainter({
    required this.progress,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Hour notches (12 notches for 12 hours)
    final notchPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * (math.pi / 180);
      final outer = Offset(
        center.dx + (radius + 6) * math.cos(angle),
        center.dy + (radius + 6) * math.sin(angle),
      );
      final inner = Offset(
        center.dx + (radius - 6) * math.cos(angle),
        center.dy + (radius - 6) * math.sin(angle),
      );
      canvas.drawLine(inner, outer, notchPaint);
    }

    if (progress > 0) {
      // Progress sweep
      final progressPaint = Paint()
        ..shader = const LinearGradient(
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
            AppColors.accent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShiftGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isActive != isActive;
  }
}
