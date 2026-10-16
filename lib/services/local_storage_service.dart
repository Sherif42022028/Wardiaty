import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/active_shift.dart';
import '../models/app_settings.dart';
import '../models/daily_log.dart';

class LocalStorageService {
  static const String settingsBoxName = 'wardiaty_settings_box';
  static const String dailyLogsBoxName = 'wardiaty_daily_logs_box';
  static const String activeShiftBoxName = 'wardiaty_active_shift_box';

  static const String settingsKey = 'app_settings';
  static const String activeShiftKey = 'active_shift';

  late Box _settingsBox;
  late Box _dailyLogsBox;
  late Box _activeShiftBox;

  bool _isInitialized = false;

  /// Initialize Hive and open all boxes
  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();

    _settingsBox = await Hive.openBox(settingsBoxName);
    _dailyLogsBox = await Hive.openBox(dailyLogsBoxName);
    _activeShiftBox = await Hive.openBox(activeShiftBoxName);

    _isInitialized = true;
  }

  // ==================== Settings ====================

  AppSettings getSettings() {
    try {
      final raw = _settingsBox.get(settingsKey);
      if (raw is Map) {
        return AppSettings.fromJson(raw);
      }
    } catch (e) {
      debugPrint('Error reading settings from Hive: $e');
    }
    return const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put(settingsKey, settings.toJson());
  }

  // ==================== Daily Logs ====================

  List<DailyLog> getAllDailyLogs() {
    final List<DailyLog> logs = [];
    try {
      for (final key in _dailyLogsBox.keys) {
        final raw = _dailyLogsBox.get(key);
        if (raw is Map) {
          logs.add(DailyLog.fromJson(raw));
        }
      }
    } catch (e) {
      debugPrint('Error reading daily logs from Hive: $e');
    }
    // Sort descending by date (newest first)
    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs;
  }

  DailyLog? getDailyLog(String dateKey) {
    try {
      final raw = _dailyLogsBox.get(dateKey);
      if (raw is Map) {
        return DailyLog.fromJson(raw);
      }
    } catch (e) {
      debugPrint('Error reading log for $dateKey: $e');
    }
    return null;
  }

  Future<void> saveDailyLog(DailyLog log) async {
    await _dailyLogsBox.put(log.dateKey, log.toJson());
  }

  Future<void> deleteDailyLog(String dateKey) async {
    await _dailyLogsBox.delete(dateKey);
  }

  // ==================== Active Shift ====================

  ActiveShift? getActiveShift() {
    try {
      final raw = _activeShiftBox.get(activeShiftKey);
      if (raw is Map) {
        return ActiveShift.fromJson(raw);
      }
    } catch (e) {
      debugPrint('Error reading active shift: $e');
    }
    return null;
  }

  Future<void> saveActiveShift(ActiveShift shift) async {
    await _activeShiftBox.put(activeShiftKey, shift.toJson());
  }

  Future<void> clearActiveShift() async {
    await _activeShiftBox.delete(activeShiftKey);
  }

  // ==================== Backup & Restore (JSON) ====================

  String exportBackupJson() {
    final settings = getSettings();
    final logs = getAllDailyLogs();
    final activeShift = getActiveShift();

    final Map<String, dynamic> data = {
      'app': 'Wardiaty',
      'version': '1.0.0',
      'exportTimestamp': DateTime.now().toIso8601String(),
      'settings': settings.toJson(),
      'logs': logs.map((l) => l.toJson()).toList(),
      'activeShift': activeShift?.toJson(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> importBackupJson(String jsonStr) async {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) return false;

      // Restore settings
      if (decoded['settings'] is Map) {
        final newSettings = AppSettings.fromJson(decoded['settings'] as Map);
        await saveSettings(newSettings);
      }

      // Restore logs
      if (decoded['logs'] is List) {
        await _dailyLogsBox.clear();
        for (final item in decoded['logs']) {
          if (item is Map) {
            final log = DailyLog.fromJson(item);
            await saveDailyLog(log);
          }
        }
      }

      // Restore active shift if present
      if (decoded['activeShift'] is Map) {
        final shift = ActiveShift.fromJson(decoded['activeShift'] as Map);
        await saveActiveShift(shift);
      } else {
        await clearActiveShift();
      }

      return true;
    } catch (e) {
      debugPrint('Error importing JSON backup: $e');
      return false;
    }
  }

  // ==================== Seed Demo Month Data ====================

  Future<void> loadDemoMonthData(AppSettings settings) async {
    final now = DateTime.now();
    final rate = settings.defaultDailyRate > 0 ? settings.defaultDailyRate : 300.0;

    final List<DailyLog> demoLogs = [
      // Day 1: Perfect 12-hour work day (8:00 to 20:00)
      DailyLog(
        date: DateTime(now.year, now.month, 1),
        status: DayStatus.work,
        checkInHour: 8,
        checkInMinute: 0,
        checkOutHour: 20,
        checkOutMinute: 0,
        actualHours: 12.0,
        dailyRate: rate,
        adjustment: 0.0,
        notes: 'وردية قياسية 12 ساعة كاملة بدون تأخير',
      ),
      // Day 2: Overtime (+2 hours, total 14 hours, bonus 50)
      DailyLog(
        date: DateTime(now.year, now.month, 2),
        status: DayStatus.work,
        checkInHour: 8,
        checkInMinute: 0,
        checkOutHour: 22,
        checkOutMinute: 0,
        actualHours: 14.0,
        dailyRate: rate,
        adjustment: 50.0,
        notes: 'ساعتان إضافي لتسليم شحنة عاجلة + مكافأة تميز',
      ),
      // Day 3: Paid Leave (إجازة مدفوعة)
      DailyLog(
        date: DateTime(now.year, now.month, 3),
        status: DayStatus.paidLeave,
        actualHours: 0.0,
        dailyRate: rate,
        adjustment: 0.0,
        notes: 'إجازة رسمية مدفوعة الأجر',
      ),
      // Day 4: Shortfall (-2 hours, total 10 hours)
      DailyLog(
        date: DateTime(now.year, now.month, 4),
        status: DayStatus.work,
        checkInHour: 9,
        checkInMinute: 0,
        checkOutHour: 19,
        checkOutMinute: 0,
        actualHours: 10.0,
        dailyRate: rate,
        adjustment: 0.0,
        notes: 'انصراف مبكر بسبب موعد طبي (نقص ساعتين)',
      ),
      // Day 5: Night Shift (20:00 to 08:00 next day = 12h)
      DailyLog(
        date: DateTime(now.year, now.month, 5),
        status: DayStatus.work,
        checkInHour: 20,
        checkInMinute: 0,
        checkOutHour: 8,
        checkOutMinute: 0,
        actualHours: 12.0,
        dailyRate: rate,
        adjustment: 0.0,
        notes: 'وردية ليلية عابرة لمنتصف الليل',
      ),
      // Day 6: Overtime (+1 hour = 13h) with deduction advance (-100)
      DailyLog(
        date: DateTime(now.year, now.month, 6),
        status: DayStatus.work,
        checkInHour: 7,
        checkInMinute: 0,
        checkOutHour: 20,
        checkOutMinute: 0,
        actualHours: 13.0,
        dailyRate: rate,
        adjustment: -100.0,
        notes: 'ساعة إضافي، وخصم سلفة نقدية 100 ج.م',
      ),
      // Day 7: Unpaid Leave (راحة أسبوعية)
      DailyLog(
        date: DateTime(now.year, now.month, 7),
        status: DayStatus.unpaidLeave,
        actualHours: 0.0,
        dailyRate: rate,
        adjustment: 0.0,
        notes: 'يوم راحة أسبوعية بدون أجر',
      ),
    ];

    for (final log in demoLogs) {
      await saveDailyLog(log);
    }
  }

  // ==================== Clear Data ====================

  Future<void> clearAllData() async {
    await _dailyLogsBox.clear();
    await _activeShiftBox.clear();
  }
}
