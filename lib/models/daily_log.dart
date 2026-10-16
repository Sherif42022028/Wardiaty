import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Enum representing the 4 day statuses
enum DayStatus {
  work, // يوم عمل
  paidLeave, // إجازة مدفوعة الأجر
  unpaidLeave, // إجازة بدون أجر / راحة
  absent; // غياب

  String get arabicLabel {
    switch (this) {
      case DayStatus.work:
        return 'يوم عمل';
      case DayStatus.paidLeave:
        return 'إجازة مدفوعة';
      case DayStatus.unpaidLeave:
        return 'إجازة بدون أجر';
      case DayStatus.absent:
        return 'غياب';
    }
  }

  Color get color {
    switch (this) {
      case DayStatus.work:
        return AppColors.success;
      case DayStatus.paidLeave:
        return AppColors.paidLeave;
      case DayStatus.unpaidLeave:
        return AppColors.unpaidLeave;
      case DayStatus.absent:
        return AppColors.crimson;
    }
  }

  IconData get icon {
    switch (this) {
      case DayStatus.work:
        return Icons.work_rounded;
      case DayStatus.paidLeave:
        return Icons.beach_access_rounded;
      case DayStatus.unpaidLeave:
        return Icons.weekend_rounded;
      case DayStatus.absent:
        return Icons.person_off_rounded;
    }
  }
}

/// Model representing a daily attendance record and its pay calculation
class DailyLog {
  final DateTime date;
  final DayStatus status;
  final int? checkInHour;
  final int? checkInMinute;
  final int? checkOutHour;
  final int? checkOutMinute;
  final double actualHours;
  final double dailyRate;
  final double adjustment; // Bonus (+) or advance/deduction (-)
  final String notes;

  const DailyLog({
    required this.date,
    this.status = DayStatus.work,
    this.checkInHour,
    this.checkInMinute,
    this.checkOutHour,
    this.checkOutMinute,
    this.actualHours = 12.0,
    required this.dailyRate,
    this.adjustment = 0.0,
    this.notes = '',
  });

  /// Key in Hive: YYYY-MM-DD
  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  TimeOfDay? get checkInTime =>
      checkInHour != null && checkInMinute != null
          ? TimeOfDay(hour: checkInHour!, minute: checkInMinute!)
          : null;

  TimeOfDay? get checkOutTime =>
      checkOutHour != null && checkOutMinute != null
          ? TimeOfDay(hour: checkOutHour!, minute: checkOutMinute!)
          : null;

  DailyLog copyWith({
    DateTime? date,
    DayStatus? status,
    int? checkInHour,
    int? checkInMinute,
    int? checkOutHour,
    int? checkOutMinute,
    double? actualHours,
    double? dailyRate,
    double? adjustment,
    String? notes,
    bool clearCheckIn = false,
    bool clearCheckOut = false,
  }) {
    return DailyLog(
      date: date ?? this.date,
      status: status ?? this.status,
      checkInHour: clearCheckIn ? null : (checkInHour ?? this.checkInHour),
      checkInMinute: clearCheckIn ? null : (checkInMinute ?? this.checkInMinute),
      checkOutHour: clearCheckOut ? null : (checkOutHour ?? this.checkOutHour),
      checkOutMinute: clearCheckOut ? null : (checkOutMinute ?? this.checkOutMinute),
      actualHours: actualHours ?? this.actualHours,
      dailyRate: dailyRate ?? this.dailyRate,
      adjustment: adjustment ?? this.adjustment,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': dateKey,
      'status': status.name,
      'checkInHour': checkInHour,
      'checkInMinute': checkInMinute,
      'checkOutHour': checkOutHour,
      'checkOutMinute': checkOutMinute,
      'actualHours': actualHours,
      'dailyRate': dailyRate,
      'adjustment': adjustment,
      'notes': notes,
    };
  }

  factory DailyLog.fromJson(Map<dynamic, dynamic> json) {
    DateTime parsedDate;
    if (json['date'] != null) {
      final parts = json['date'].toString().split('-');
      if (parts.length == 3) {
        parsedDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } else {
        parsedDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    DayStatus parsedStatus = DayStatus.work;
    if (json['status'] != null) {
      parsedStatus = DayStatus.values.firstWhere(
        (e) => e.name == json['status'].toString(),
        orElse: () => DayStatus.work,
      );
    }

    return DailyLog(
      date: parsedDate,
      status: parsedStatus,
      checkInHour: json['checkInHour'] as int?,
      checkInMinute: json['checkInMinute'] as int?,
      checkOutHour: json['checkOutHour'] as int?,
      checkOutMinute: json['checkOutMinute'] as int?,
      actualHours: (json['actualHours'] as num?)?.toDouble() ?? 12.0,
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 300.0,
      adjustment: (json['adjustment'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString() ?? '',
    );
  }
}
