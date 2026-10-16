import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/daily_log.dart';

/// Calculation breakdown for a single day
class DayCalculationResult {
  final DailyLog log;
  final double hourlyRate;
  final double standardHours;
  final double actualHours;
  final double hoursDifference; // positive = overtime, negative = shortfall
  final double overtimeHours;
  final double shortfallHours;
  final double overtimePay;
  final double shortfallDeduction;
  final double basePay;
  final double adjustment;
  final double netPay;

  const DayCalculationResult({
    required this.log,
    required this.hourlyRate,
    required this.standardHours,
    required this.actualHours,
    required this.hoursDifference,
    required this.overtimeHours,
    required this.shortfallHours,
    required this.overtimePay,
    required this.shortfallDeduction,
    required this.basePay,
    required this.adjustment,
    required this.netPay,
  });

  bool get hasOvertime => overtimeHours > 0.01;
  bool get hasShortfall => shortfallHours > 0.01;
}

/// Aggregated monthly report summary
class MonthlyReportSummary {
  final int year;
  final int month;
  final int totalLoggedDays;
  final int workDaysCount;
  final int paidLeaveDaysCount;
  final int unpaidLeaveDaysCount;
  final int absentDaysCount;

  final double totalExpectedHours;
  final double totalActualHours;
  final double netHoursDifference; // positive = net extra, negative = net shortfall

  final double totalBaseWorkPay;
  final double totalOvertimePay;
  final double totalShortfallDeduction;
  final double totalPaidLeavePay;
  final double totalGrossHoursPay; // before adjustments

  final double totalAdjustment; // bonuses (+) and advances/deductions (-)
  final double netMonthlyEarnings; // final take-home

  final double averageDailyHours;
  final List<DayCalculationResult> dayResults;

  const MonthlyReportSummary({
    required this.year,
    required this.month,
    required this.totalLoggedDays,
    required this.workDaysCount,
    required this.paidLeaveDaysCount,
    required this.unpaidLeaveDaysCount,
    required this.absentDaysCount,
    required this.totalExpectedHours,
    required this.totalActualHours,
    required this.netHoursDifference,
    required this.totalBaseWorkPay,
    required this.totalOvertimePay,
    required this.totalShortfallDeduction,
    required this.totalPaidLeavePay,
    required this.totalGrossHoursPay,
    required this.totalAdjustment,
    required this.netMonthlyEarnings,
    required this.averageDailyHours,
    required this.dayResults,
  });
}

/// Calculation engine implementing business rules from build.md & design.md
class CalculationService {
  /// Calculates hourly rate from daily rate and standard hours
  static double computeHourlyRate(double dailyRate, double standardHours) {
    if (standardHours <= 0) return 0.0;
    return dailyRate / standardHours;
  }

  /// Calculates net duration between check-in and check-out with night shift support (24h rollover)
  static double computeDurationHours(TimeOfDay checkIn, TimeOfDay checkOut) {
    final startMins = checkIn.hour * 60 + checkIn.minute;
    var endMins = checkOut.hour * 60 + checkOut.minute;

    // Overnight shift: check-out is next morning or earlier in the day
    if (endMins <= startMins) {
      endMins += 24 * 60; // Add 1440 minutes
    }

    final diffMinutes = endMins - startMins;
    return diffMinutes / 60.0;
  }

  /// Computes pay and breakdown for a single day log
  static DayCalculationResult calculateDay(DailyLog log, AppSettings settings) {
    final standardHours = settings.standardHours > 0 ? settings.standardHours : 12.0;
    final hourlyRate = computeHourlyRate(log.dailyRate, standardHours);

    switch (log.status) {
      case DayStatus.paidLeave:
        final base = log.dailyRate;
        return DayCalculationResult(
          log: log,
          hourlyRate: hourlyRate,
          standardHours: standardHours,
          actualHours: 0.0,
          hoursDifference: 0.0,
          overtimeHours: 0.0,
          shortfallHours: 0.0,
          overtimePay: 0.0,
          shortfallDeduction: 0.0,
          basePay: base,
          adjustment: log.adjustment,
          netPay: base + log.adjustment,
        );

      case DayStatus.unpaidLeave:
      case DayStatus.absent:
        return DayCalculationResult(
          log: log,
          hourlyRate: hourlyRate,
          standardHours: standardHours,
          actualHours: 0.0,
          hoursDifference: 0.0,
          overtimeHours: 0.0,
          shortfallHours: 0.0,
          overtimePay: 0.0,
          shortfallDeduction: 0.0,
          basePay: 0.0,
          adjustment: log.adjustment,
          netPay: log.adjustment, // e.g. deductions or allowance
        );

      case DayStatus.work:
        final actualHours = log.actualHours;
        final diff = actualHours - standardHours;

        double overtimeHours = 0.0;
        double shortfallHours = 0.0;
        double overtimePay = 0.0;
        double shortfallDeduction = 0.0;
        double basePay = log.dailyRate;

        if (diff > 0.001) {
          overtimeHours = diff;
          overtimePay = overtimeHours * hourlyRate * settings.overtimeMultiplier;
          basePay = log.dailyRate + overtimePay;
        } else if (diff < -0.001) {
          shortfallHours = -diff;
          shortfallDeduction = shortfallHours * hourlyRate;
          basePay = math.max(0.0, log.dailyRate - shortfallDeduction);
        } else {
          basePay = log.dailyRate;
        }

        final netPay = basePay + log.adjustment;

        return DayCalculationResult(
          log: log,
          hourlyRate: hourlyRate,
          standardHours: standardHours,
          actualHours: actualHours,
          hoursDifference: diff,
          overtimeHours: overtimeHours,
          shortfallHours: shortfallHours,
          overtimePay: overtimePay,
          shortfallDeduction: shortfallDeduction,
          basePay: basePay,
          adjustment: log.adjustment,
          netPay: netPay,
        );
    }
  }

  /// Aggregates all logs for a specific month and year
  static MonthlyReportSummary calculateMonthlyReport({
    required int year,
    required int month,
    required List<DailyLog> logs,
    required AppSettings settings,
  }) {
    // Filter for target month
    final monthLogs = logs.where((l) => l.date.year == year && l.date.month == month).toList();

    // Sort chronologically
    monthLogs.sort((a, b) => a.date.compareTo(b.date));

    int workDays = 0;
    int paidLeaveDays = 0;
    int unpaidLeaveDays = 0;
    int absentDays = 0;

    double totalActualHours = 0.0;
    double totalOvertimePay = 0.0;
    double totalShortfallDeduction = 0.0;
    double totalBaseWorkPay = 0.0;
    double totalPaidLeavePay = 0.0;
    double totalGrossHoursPay = 0.0;
    double totalAdjustment = 0.0;

    final List<DayCalculationResult> dayResults = [];

    for (final log in monthLogs) {
      final res = calculateDay(log, settings);
      dayResults.add(res);

      totalAdjustment += res.adjustment;

      switch (log.status) {
        case DayStatus.work:
          workDays++;
          totalActualHours += res.actualHours;
          totalBaseWorkPay += log.dailyRate;
          totalOvertimePay += res.overtimePay;
          totalShortfallDeduction += res.shortfallDeduction;
          totalGrossHoursPay += res.basePay;
          break;
        case DayStatus.paidLeave:
          paidLeaveDays++;
          totalPaidLeavePay += res.basePay;
          totalGrossHoursPay += res.basePay;
          break;
        case DayStatus.unpaidLeave:
          unpaidLeaveDays++;
          break;
        case DayStatus.absent:
          absentDays++;
          break;
      }
    }

    final totalExpectedHours = workDays * (settings.standardHours > 0 ? settings.standardHours : 12.0);
    final netHoursDifference = totalActualHours - totalExpectedHours;
    final netMonthlyEarnings = totalGrossHoursPay + totalAdjustment;
    final averageDailyHours = workDays > 0 ? totalActualHours / workDays : 0.0;

    return MonthlyReportSummary(
      year: year,
      month: month,
      totalLoggedDays: monthLogs.length,
      workDaysCount: workDays,
      paidLeaveDaysCount: paidLeaveDays,
      unpaidLeaveDaysCount: unpaidLeaveDays,
      absentDaysCount: absentDays,
      totalExpectedHours: totalExpectedHours,
      totalActualHours: totalActualHours,
      netHoursDifference: netHoursDifference,
      totalBaseWorkPay: totalBaseWorkPay,
      totalOvertimePay: totalOvertimePay,
      totalShortfallDeduction: totalShortfallDeduction,
      totalPaidLeavePay: totalPaidLeavePay,
      totalGrossHoursPay: totalGrossHoursPay,
      totalAdjustment: totalAdjustment,
      netMonthlyEarnings: netMonthlyEarnings,
      averageDailyHours: averageDailyHours,
      dayResults: dayResults,
    );
  }
}
