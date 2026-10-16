import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wardiaty/models/app_settings.dart';
import 'package:wardiaty/models/daily_log.dart';
import 'package:wardiaty/services/calculation_service.dart';
import 'package:wardiaty/services/export_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('ar', null);
  });

  group('CalculationService Unit Tests', () {
    const settings = AppSettings(
      userName: 'محمد',
      currency: 'ج.م',
      standardHours: 12.0,
      defaultDailyRate: 300.0,
      overtimeMultiplier: 1.5,
    );

    test('Computes hourly rate correctly (dailyRate / 12)', () {
      final rate = CalculationService.computeHourlyRate(300.0, 12.0);
      expect(rate, 25.0);
    });

    test('Computes normal shift duration correctly (08:00 to 20:00 = 12.0 hours)', () {
      const inTime = TimeOfDay(hour: 8, minute: 0);
      const outTime = TimeOfDay(hour: 20, minute: 0);
      final duration = CalculationService.computeDurationHours(inTime, outTime);
      expect(duration, 12.0);
    });

    test('Computes overnight night shift duration across midnight (20:00 to 08:00 = 12.0 hours)', () {
      const inTime = TimeOfDay(hour: 20, minute: 0);
      const outTime = TimeOfDay(hour: 8, minute: 0);
      final duration = CalculationService.computeDurationHours(inTime, outTime);
      expect(duration, 12.0);
    });

    test('Calculates standard 12-hour work day correctly', () {
      final log = DailyLog(
        date: DateTime(2026, 10, 1),
        status: DayStatus.work,
        actualHours: 12.0,
        dailyRate: 300.0,
      );
      final res = CalculationService.calculateDay(log, settings);

      expect(res.hourlyRate, 25.0);
      expect(res.actualHours, 12.0);
      expect(res.hoursDifference, 0.0);
      expect(res.overtimePay, 0.0);
      expect(res.shortfallDeduction, 0.0);
      expect(res.basePay, 300.0);
      expect(res.netPay, 300.0);
    });

    test('Calculates overtime (+2 hours @ 1.5x) correctly', () {
      // 14 hours = 12 standard + 2 extra
      // Hourly rate = 25.0
      // Overtime = 2 * 25.0 * 1.5 = 75.0
      // Base pay = 300 + 75 = 375.0
      final log = DailyLog(
        date: DateTime(2026, 10, 2),
        status: DayStatus.work,
        actualHours: 14.0,
        dailyRate: 300.0,
        adjustment: 25.0, // bonus
      );
      final res = CalculationService.calculateDay(log, settings);

      expect(res.overtimeHours, 2.0);
      expect(res.overtimePay, 75.0);
      expect(res.basePay, 375.0);
      expect(res.netPay, 400.0); // 375 + 25
    });

    test('Calculates shortfall (-2 hours) deduction correctly', () {
      // 10 hours = 2 hours missing
      // Hourly rate = 25.0
      // Shortfall deduction = 2 * 25.0 = 50.0
      // Base pay = 300 - 50 = 250.0
      final log = DailyLog(
        date: DateTime(2026, 10, 3),
        status: DayStatus.work,
        actualHours: 10.0,
        dailyRate: 300.0,
        adjustment: -50.0, // advance deduction
      );
      final res = CalculationService.calculateDay(log, settings);

      expect(res.shortfallHours, 2.0);
      expect(res.shortfallDeduction, 50.0);
      expect(res.basePay, 250.0);
      expect(res.netPay, 200.0); // 250 - 50
    });

    test('Calculates paid leave correctly', () {
      final log = DailyLog(
        date: DateTime(2026, 10, 4),
        status: DayStatus.paidLeave,
        actualHours: 0.0,
        dailyRate: 300.0,
      );
      final res = CalculationService.calculateDay(log, settings);

      expect(res.basePay, 300.0);
      expect(res.netPay, 300.0);
      expect(res.actualHours, 0.0);
    });

    test('Calculates unpaid leave and absence correctly', () {
      final unpaid = DailyLog(
        date: DateTime(2026, 10, 5),
        status: DayStatus.unpaidLeave,
        actualHours: 0.0,
        dailyRate: 300.0,
      );
      final absent = DailyLog(
        date: DateTime(2026, 10, 6),
        status: DayStatus.absent,
        actualHours: 0.0,
        dailyRate: 300.0,
      );

      final resUnpaid = CalculationService.calculateDay(unpaid, settings);
      final resAbsent = CalculationService.calculateDay(absent, settings);

      expect(resUnpaid.basePay, 0.0);
      expect(resUnpaid.netPay, 0.0);
      expect(resAbsent.basePay, 0.0);
      expect(resAbsent.netPay, 0.0);
    });

    test('Aggregates monthly report summary correctly', () {
      final logs = [
        DailyLog(date: DateTime(2026, 10, 1), status: DayStatus.work, actualHours: 12.0, dailyRate: 300.0),
        DailyLog(date: DateTime(2026, 10, 2), status: DayStatus.work, actualHours: 14.0, dailyRate: 300.0),
        DailyLog(date: DateTime(2026, 10, 3), status: DayStatus.paidLeave, actualHours: 0.0, dailyRate: 300.0),
        DailyLog(date: DateTime(2026, 10, 4), status: DayStatus.unpaidLeave, actualHours: 0.0, dailyRate: 300.0),
      ];

      final summary = CalculationService.calculateMonthlyReport(
        year: 2026,
        month: 10,
        logs: logs,
        settings: settings,
      );

      expect(summary.totalLoggedDays, 4);
      expect(summary.workDaysCount, 2);
      expect(summary.paidLeaveDaysCount, 1);
      expect(summary.unpaidLeaveDaysCount, 1);
      expect(summary.totalExpectedHours, 24.0); // 2 * 12
      expect(summary.totalActualHours, 26.0); // 12 + 14
      expect(summary.netHoursDifference, 2.0); // +2 hours extra
      expect(summary.totalOvertimePay, 75.0);
      expect(summary.totalPaidLeavePay, 300.0);
      // gross pay = 300 (day1) + 375 (day2) + 300 (paid leave) = 975.0
      expect(summary.totalGrossHoursPay, 975.0);
      expect(summary.netMonthlyEarnings, 975.0);
    });
  });

  group('ExportService Tests', () {
    const settings = AppSettings();
    final summary = CalculationService.calculateMonthlyReport(
      year: 2026,
      month: 10,
      logs: [
        DailyLog(date: DateTime(2026, 10, 1), status: DayStatus.work, actualHours: 12.0, dailyRate: 300.0),
      ],
      settings: settings,
    );

    test('Generates WhatsApp summary text containing key information', () {
      final text = ExportService.generateWhatsAppSummary(summary, settings);
      expect(text, contains('تقرير الحضور والمستحقات الشهرية'));
      expect(text, contains('ورديتي'));
      expect(text, contains(settings.userName));
    });

    test('Generates CSV starting with UTF-8 BOM (\\uFEFF)', () {
      final csv = ExportService.generateCsv(summary, settings);
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('التاريخ,اليوم,الحالة'));
    });
  });
}
