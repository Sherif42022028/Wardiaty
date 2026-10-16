import 'dart:async';
import 'package:flutter/material.dart';
import '../models/active_shift.dart';
import '../models/app_settings.dart';
import '../models/daily_log.dart';
import '../services/calculation_service.dart';
import '../services/local_storage_service.dart';

enum DayFilter {
  all,
  workOnly,
  leavesOnly,
  overtimeOnly,
  shortfallOnly;

  String get arabicLabel {
    switch (this) {
      case DayFilter.all:
        return 'كل الأيام';
      case DayFilter.workOnly:
        return 'أيام العمل';
      case DayFilter.leavesOnly:
        return 'الإجازات والغياب';
      case DayFilter.overtimeOnly:
        return 'إضافي (+12س)';
      case DayFilter.shortfallOnly:
        return 'نقص (-12س)';
    }
  }
}

class AttendanceProvider extends ChangeNotifier {
  final LocalStorageService _storage;

  AppSettings _settings = const AppSettings();
  List<DailyLog> _dailyLogs = [];
  ActiveShift? _activeShift;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  DayFilter _currentFilter = DayFilter.all;

  DateTime _currentTime = DateTime.now();
  Timer? _tickerTimer;

  AttendanceProvider(this._storage);

  AppSettings get settings => _settings;
  List<DailyLog> get dailyLogs => List.unmodifiable(_dailyLogs);
  ActiveShift? get activeShift => _activeShift;
  bool get hasActiveShift => _activeShift != null;

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  DayFilter get currentFilter => _currentFilter;
  DateTime get currentTime => _currentTime;

  /// Initialize state from storage and start 1-second live clock ticker
  Future<void> init() async {
    await _storage.init();
    _settings = _storage.getSettings();
    _dailyLogs = _storage.getAllDailyLogs();
    _activeShift = _storage.getActiveShift();

    // Start 1-second timer for live clock & shift elapsed gauge
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTime = DateTime.now();
      notifyListeners();
    });

    notifyListeners();
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  // ==================== Settings Management ====================

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _storage.saveSettings(newSettings);
    notifyListeners();
  }

  // ==================== Daily Logs Operations ====================

  DailyLog? getLogForDate(DateTime date) {
    final key =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _storage.getDailyLog(key);
  }

  Future<void> saveLog(DailyLog log) async {
    await _storage.saveDailyLog(log);
    _dailyLogs = _storage.getAllDailyLogs();
    notifyListeners();
  }

  Future<void> deleteLog(String dateKey) async {
    await _storage.deleteDailyLog(dateKey);
    _dailyLogs = _storage.getAllDailyLogs();
    notifyListeners();
  }

  List<DailyLog> get recentLogs {
    final sorted = List<DailyLog>.from(_dailyLogs)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(7).toList();
  }

  // ==================== Live Punch Shift (تسجيل الحضور والانصراف الآن) ====================

  Future<void> startShiftNow({double? customDailyRate}) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final shift = ActiveShift(
      startTimestamp: now.millisecondsSinceEpoch,
      dateKey: dateKey,
      startHour: now.hour,
      startMinute: now.minute,
    );

    _activeShift = shift;
    await _storage.saveActiveShift(shift);
    notifyListeners();
  }

  Future<DailyLog> endShiftNow() async {
    if (_activeShift == null) {
      throw StateError('No active shift found');
    }

    final now = DateTime.now();
    final shift = _activeShift!;
    final startTime = shift.startTime;

    // Total actual hours worked
    final durationSeconds = now.difference(startTime).inSeconds;
    // Minimum 1 minute for sanity
    final actualHours = (durationSeconds / 3600.0).clamp(0.02, 24.0);

    final log = DailyLog(
      date: DateTime(startTime.year, startTime.month, startTime.day),
      status: DayStatus.work,
      checkInHour: shift.startHour,
      checkInMinute: shift.startMinute,
      checkOutHour: now.hour,
      checkOutMinute: now.minute,
      actualHours: double.parse(actualHours.toStringAsFixed(2)),
      dailyRate: _settings.defaultDailyRate,
      adjustment: 0.0,
      notes: 'تم التسجيل عبر البصمة الحية السريعة',
    );

    await saveLog(log);
    await _storage.clearActiveShift();
    _activeShift = null;
    notifyListeners();

    return log;
  }

  Future<void> cancelActiveShift() async {
    await _storage.clearActiveShift();
    _activeShift = null;
    notifyListeners();
  }

  /// Live accrued earnings up to this exact second
  double get liveAccruedEarnings {
    if (_activeShift == null) return 0.0;
    final hourlyRate = _settings.defaultHourlyRate;
    final hours = _activeShift!.elapsedHours;
    return hours * hourlyRate;
  }

  // ==================== Monthly Report & Filters ====================

  void setSelectedMonth(int year, int month) {
    _selectedYear = year;
    _selectedMonth = month;
    notifyListeners();
  }

  void previousMonth() {
    if (_selectedMonth == 1) {
      _selectedYear -= 1;
      _selectedMonth = 12;
    } else {
      _selectedMonth -= 1;
    }
    notifyListeners();
  }

  void nextMonth() {
    if (_selectedMonth == 12) {
      _selectedYear += 1;
      _selectedMonth = 1;
    } else {
      _selectedMonth += 1;
    }
    notifyListeners();
  }

  void setFilter(DayFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  MonthlyReportSummary get currentMonthSummary {
    return CalculationService.calculateMonthlyReport(
      year: _selectedYear,
      month: _selectedMonth,
      logs: _dailyLogs,
      settings: _settings,
    );
  }

  List<DayCalculationResult> get filteredDayResults {
    final allResults = currentMonthSummary.dayResults;
    switch (_currentFilter) {
      case DayFilter.all:
        return allResults;
      case DayFilter.workOnly:
        return allResults.where((r) => r.log.status == DayStatus.work).toList();
      case DayFilter.leavesOnly:
        return allResults.where((r) => r.log.status != DayStatus.work).toList();
      case DayFilter.overtimeOnly:
        return allResults.where((r) => r.hasOvertime).toList();
      case DayFilter.shortfallOnly:
        return allResults.where((r) => r.hasShortfall).toList();
    }
  }

  // ==================== Demo Data & Backup ====================

  Future<void> loadDemoData() async {
    await _storage.loadDemoMonthData(_settings);
    _dailyLogs = _storage.getAllDailyLogs();
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _storage.clearAllData();
    _dailyLogs = [];
    _activeShift = null;
    notifyListeners();
  }

  String exportBackupJson() {
    return _storage.exportBackupJson();
  }

  Future<bool> importBackupJson(String jsonStr) async {
    final success = await _storage.importBackupJson(jsonStr);
    if (success) {
      _settings = _storage.getSettings();
      _dailyLogs = _storage.getAllDailyLogs();
      _activeShift = _storage.getActiveShift();
      notifyListeners();
    }
    return success;
  }
}
