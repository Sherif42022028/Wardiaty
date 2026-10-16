import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/daily_log.dart';
import '../providers/attendance_provider.dart';
import '../services/calculation_service.dart';
import '../theme/app_theme.dart';
import 'animated_status_selector.dart';

class DayFormCard extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DailyLog>? onLogSaved;

  const DayFormCard({
    super.key,
    this.initialDate,
    this.onLogSaved,
  });

  @override
  State<DayFormCard> createState() => DayFormCardState();
}

class DayFormCardState extends State<DayFormCard> {
  late DateTime _selectedDate;
  DayStatus _status = DayStatus.work;
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;

  late TextEditingController _hoursController;
  late TextEditingController _rateController;
  late TextEditingController _adjustmentController;
  late TextEditingController _notesController;

  bool _isExistingLog = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _hoursController = TextEditingController(text: '12');
    _rateController = TextEditingController();
    _adjustmentController = TextEditingController(text: '0');
    _notesController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDateData(_selectedDate);
    });
  }

  @override
  void didUpdateWidget(covariant DayFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != null) {
      final cur = widget.initialDate!;
      // Only reload if the calendar day (year, month, day) is actually different from _selectedDate
      final isDifferentDay = _selectedDate.year != cur.year ||
          _selectedDate.month != cur.month ||
          _selectedDate.day != cur.day;
      if (isDifferentDay) {
        loadDate(cur);
      }
    }
  }


  @override
  void dispose() {
    _hoursController.dispose();
    _rateController.dispose();
    _adjustmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Public method so parent screen or recent logs list can populate this form
  void loadDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadDateData(date);
  }

  void _loadDateData(DateTime date) {
    final provider = context.read<AttendanceProvider>();
    final existingLog = provider.getLogForDate(date);

    if (existingLog != null) {
      setState(() {
        _isExistingLog = true;
        _status = existingLog.status;
        _checkInTime = existingLog.checkInTime;
        _checkOutTime = existingLog.checkOutTime;
        _hoursController.text = existingLog.actualHours.toStringAsFixed(
            existingLog.actualHours.truncateToDouble() == existingLog.actualHours ? 0 : 1);
        _rateController.text = existingLog.dailyRate.toStringAsFixed(0);
        _adjustmentController.text = existingLog.adjustment.toStringAsFixed(0);
        _notesController.text = existingLog.notes;
      });
    } else {
      setState(() {
        _isExistingLog = false;
        _status = DayStatus.work;
        _checkInTime = const TimeOfDay(hour: 8, minute: 0);
        _checkOutTime = const TimeOfDay(hour: 20, minute: 0);
        _hoursController.text = provider.settings.standardHours.toStringAsFixed(0);
        _rateController.text = provider.settings.defaultDailyRate.toStringAsFixed(0);
        _adjustmentController.text = '0';
        _notesController.text = '';
      });
    }
  }

  void _recalcHoursFromTimes() {
    if (_checkInTime != null && _checkOutTime != null) {
      final hours = CalculationService.computeDurationHours(_checkInTime!, _checkOutTime!);
      setState(() {
        _hoursController.text = hours.toStringAsFixed(
            hours.truncateToDouble() == hours ? 0 : 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final settings = provider.settings;

    final dateFormatted = DateFormat('EEEE، d MMMM yyyy', 'ar').format(_selectedDate);

    // Build temporary log for live preview
    final double actualHours = double.tryParse(_hoursController.text.trim()) ?? settings.standardHours;
    final double dailyRate = double.tryParse(_rateController.text.trim()) ?? settings.defaultDailyRate;
    final double adjustment = double.tryParse(_adjustmentController.text.trim()) ?? 0.0;

    final tempLog = DailyLog(
      date: _selectedDate,
      status: _status,
      checkInHour: _checkInTime?.hour,
      checkInMinute: _checkInTime?.minute,
      checkOutHour: _checkOutTime?.hour,
      checkOutMinute: _checkOutTime?.minute,
      actualHours: actualHours,
      dailyRate: dailyRate,
      adjustment: adjustment,
      notes: _notesController.text.trim(),
    );

    final previewResult = CalculationService.calculateDay(tempLog, settings);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Existing indicator
            Row(
              children: [
                Icon(
                  _isExistingLog ? Icons.edit_calendar_rounded : Icons.add_circle_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  _isExistingLog ? 'تعديل بيانات اليوم' : 'تسجيل يوم جديد',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const Spacer(),
                if (_isExistingLog)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'مسجل مسبقاً',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentDark,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Date Navigation Bar (Prev, Current Date, Next)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'اليوم السابق',
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      final prev = _selectedDate.subtract(const Duration(days: 1));
                      loadDate(prev);
                    },
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          locale: const Locale('ar', 'EG'),
                        );
                        if (picked != null) {
                          loadDate(picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Text(
                              dateFormatted,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                            const Text(
                              'اضغط لاختيار تاريخ من التقويم 📅',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'اليوم التالي',
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      final next = _selectedDate.add(const Duration(days: 1));
                      loadDate(next);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Status Selector
            const Text(
              'حالة اليوم',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedStatusSelector(
              selectedStatus: _status,
              onStatusChanged: (newStatus) {
                setState(() {
                  _status = newStatus;
                });
              },
            ),
            const SizedBox(height: 18),

            // Work Day Specific Inputs
            if (_status == DayStatus.work) ...[
              // Time pickers: Check In & Check Out
              Row(
                children: [
                  Expanded(
                    child: _buildTimePickerButton(
                      label: 'وقت الحضور',
                      time: _checkInTime,
                      icon: Icons.login_rounded,
                      color: AppColors.success,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _checkInTime ?? const TimeOfDay(hour: 8, minute: 0),
                        );
                        if (picked != null) {
                          setState(() {
                            _checkInTime = picked;
                          });
                          _recalcHoursFromTimes();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTimePickerButton(
                      label: 'وقت الانصراف',
                      time: _checkOutTime,
                      icon: Icons.logout_rounded,
                      color: AppColors.crimson,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _checkOutTime ?? const TimeOfDay(hour: 20, minute: 0),
                        );
                        if (picked != null) {
                          setState(() {
                            _checkOutTime = picked;
                          });
                          _recalcHoursFromTimes();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick Hour Presets Chips
              const Text(
                'ضبط سريع لساعات الوردية',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip('12س كامل', 12.0),
                    const SizedBox(width: 6),
                    _buildPresetChip('+13س إضافي', 13.0),
                    const SizedBox(width: 6),
                    _buildPresetChip('+14س إضافي', 14.0),
                    const SizedBox(width: 6),
                    _buildPresetChip('-10س ناقص', 10.0),
                    const SizedBox(width: 6),
                    _buildPresetChip('6س نصف يوم', 6.0),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Actual Hours Text Field
              TextFormField(
                controller: _hoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'إجمالي الساعات الفعلية',
                  suffixText: 'ساعة',
                  prefixIcon: Icon(Icons.schedule_rounded, color: AppColors.primary),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Daily Rate & Adjustment Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'يومية هذا اليوم',
                      suffixText: settings.currency,
                      prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.primary),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _adjustmentController,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'مكافأة (+) / سلفة (-)',
                      suffixText: settings.currency,
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.accentDark),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات اليوم (اختياري)',
                hintText: 'مثال: تسليم شحنة، استئذان مبكر، سلفة عاجلة...',
                prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            // Live Preview Box (معاينة حية قبل الحفظ)
            _buildLivePreviewBox(previewResult, settings),
            const SizedBox(height: 20),

            // Action Buttons: Save & Delete
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _saveDayLog(context, provider),
                    icon: const Icon(Icons.save_rounded),
                    label: Text(_isExistingLog ? 'تحديث السجل' : 'حفظ اليومية'),
                  ),
                ),
                if (_isExistingLog) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.crimson,
                        side: const BorderSide(color: AppColors.crimson),
                      ),
                      onPressed: () => _confirmDeleteLog(context, provider),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('حذف'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double hours) {
    final currentHours = double.tryParse(_hoursController.text.trim()) ?? 0.0;
    final isSelected = (currentHours - hours).abs() < 0.05;

    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? AppColors.primary : AppColors.background,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
        fontFamily: AppTheme.fontFamily,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
      onPressed: () {
        setState(() {
          _hoursController.text = hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1);
        });
      },
    );
  }

  Widget _buildTimePickerButton({
    required String label,
    required TimeOfDay? time,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final timeStr = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: AppTheme.fontFamily,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreviewBox(DayCalculationResult res, dynamic settings) {
    Color badgeColor = AppColors.textSecondary;
    String badgeText = '12 ساعة تماماً';

    if (res.log.status == DayStatus.work) {
      if (res.hasOvertime) {
        badgeColor = AppColors.success;
        badgeText = 'إضافي +${res.overtimeHours.toStringAsFixed(1)}س (+${res.overtimePay.toStringAsFixed(1)} ${settings.currency})';
      } else if (res.hasShortfall) {
        badgeColor = AppColors.crimson;
        badgeText = 'نقص -${res.shortfallHours.toStringAsFixed(1)}س (-${res.shortfallDeduction.toStringAsFixed(1)} ${settings.currency})';
      }
    } else {
      badgeColor = res.log.status.color;
      badgeText = res.log.status.arabicLabel;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المعاينة الفورية للحسبة:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سعر الساعة: ${res.hourlyRate.toStringAsFixed(1)} ${settings.currency}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontFamily: AppTheme.fontFamily,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'أجر الساعات: ${res.basePay.toStringAsFixed(1)} ${settings.currency}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontFamily: AppTheme.fontFamily,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (res.adjustment != 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  res.adjustment > 0 ? 'مكافأة مضافة (+)' : 'سلفة/خصم مستقطع (-)',
                  style: TextStyle(
                    fontSize: 12,
                    color: res.adjustment > 0 ? AppColors.success : AppColors.crimson,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                Text(
                  '${res.adjustment > 0 ? "+" : ""}${res.adjustment.toStringAsFixed(1)} ${settings.currency}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: res.adjustment > 0 ? AppColors.success : AppColors.crimson,
                    fontFamily: AppTheme.fontFamily,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'صافي مستحق اليوم:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              Text(
                '${res.netPay.toStringAsFixed(1)} ${settings.currency}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  fontFamily: AppTheme.fontFamily,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveDayLog(BuildContext context, AttendanceProvider provider) async {
    final double actualHours = double.tryParse(_hoursController.text.trim()) ?? provider.settings.standardHours;
    final double dailyRate = double.tryParse(_rateController.text.trim()) ?? provider.settings.defaultDailyRate;
    final double adjustment = double.tryParse(_adjustmentController.text.trim()) ?? 0.0;

    final log = DailyLog(
      date: _selectedDate,
      status: _status,
      checkInHour: _checkInTime?.hour,
      checkInMinute: _checkInTime?.minute,
      checkOutHour: _checkOutTime?.hour,
      checkOutMinute: _checkOutTime?.minute,
      actualHours: actualHours,
      dailyRate: dailyRate,
      adjustment: adjustment,
      notes: _notesController.text.trim(),
    );

    await provider.saveLog(log);
    setState(() {
      _isExistingLog = true;
    });

    widget.onLogSaved?.call(log);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تم حفظ بيانات يوم ${DateFormat('d MMMM', 'ar').format(_selectedDate)} بنجاح!',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
        ),
      );
    }
  }

  void _confirmDeleteLog(BuildContext context, AttendanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف سجل اليوم؟', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'هل أنت متأكد من حذف سجل يوم ${DateFormat('d MMMM yyyy', 'ar').format(_selectedDate)} نهائياً؟',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
            onPressed: () async {
              final key =
                  '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
              await provider.deleteLog(key);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadDateData(_selectedDate);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف سجل اليوم بنجاح'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
