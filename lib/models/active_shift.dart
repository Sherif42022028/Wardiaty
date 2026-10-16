/// Model for an ongoing live shift
class ActiveShift {
  final int startTimestamp; // Milliseconds since epoch
  final String dateKey; // YYYY-MM-DD
  final int startHour;
  final int startMinute;

  const ActiveShift({
    required this.startTimestamp,
    required this.dateKey,
    required this.startHour,
    required this.startMinute,
  });

  DateTime get startTime => DateTime.fromMillisecondsSinceEpoch(startTimestamp);

  Duration get elapsed => DateTime.now().difference(startTime);

  double get elapsedHours {
    final diff = elapsed;
    if (diff.isNegative) return 0.0;
    return diff.inSeconds / 3600.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'startTimestamp': startTimestamp,
      'dateKey': dateKey,
      'startHour': startHour,
      'startMinute': startMinute,
    };
  }

  factory ActiveShift.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) {
      final now = DateTime.now();
      return ActiveShift(
        startTimestamp: now.millisecondsSinceEpoch,
        dateKey: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        startHour: now.hour,
        startMinute: now.minute,
      );
    }
    return ActiveShift(
      startTimestamp: json['startTimestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      dateKey: json['dateKey']?.toString() ?? '',
      startHour: json['startHour'] as int? ?? 8,
      startMinute: json['startMinute'] as int? ?? 0,
    );
  }
}
