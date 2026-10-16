/// Settings model representing the user's shift & pay configuration
class AppSettings {
  final String userName;
  final String currency;
  final double standardHours;
  final double defaultDailyRate;
  final double overtimeMultiplier;

  const AppSettings({
    this.userName = 'محمد',
    this.currency = 'ج.م',
    this.standardHours = 12.0,
    this.defaultDailyRate = 300.0,
    this.overtimeMultiplier = 1.5,
  });

  /// Computed hourly rate from default daily rate
  double get defaultHourlyRate => standardHours > 0 ? (defaultDailyRate / standardHours) : 0.0;

  AppSettings copyWith({
    String? userName,
    String? currency,
    double? standardHours,
    double? defaultDailyRate,
    double? overtimeMultiplier,
  }) {
    return AppSettings(
      userName: userName ?? this.userName,
      currency: currency ?? this.currency,
      standardHours: standardHours ?? this.standardHours,
      defaultDailyRate: defaultDailyRate ?? this.defaultDailyRate,
      overtimeMultiplier: overtimeMultiplier ?? this.overtimeMultiplier,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'currency': currency,
      'standardHours': standardHours,
      'defaultDailyRate': defaultDailyRate,
      'overtimeMultiplier': overtimeMultiplier,
    };
  }

  factory AppSettings.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return const AppSettings();
    return AppSettings(
      userName: json['userName']?.toString() ?? 'محمد',
      currency: json['currency']?.toString() ?? 'ج.م',
      standardHours: (json['standardHours'] as num?)?.toDouble() ?? 12.0,
      defaultDailyRate: (json['defaultDailyRate'] as num?)?.toDouble() ?? 300.0,
      overtimeMultiplier: (json['overtimeMultiplier'] as num?)?.toDouble() ?? 1.5,
    );
  }
}
